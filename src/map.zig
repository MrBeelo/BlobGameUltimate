const std = @import("std");
const rl = @import("raylib");
const main = @import("main.zig");
const crsh = @import("crash.zig");
const cam = @import("camera.zig");
const scr = @import("screen.zig");
const ene = @import("enemy.zig");
const obj = @import("object.zig");
const men = @import("menu.zig");

pub const TileAtlas = struct {
    texture: rl.Texture2D,
    atlas_tile_size: f32,
    atlas_width: i32
};

pub const TileType = enum {
    AIR,
    SOLID
};

pub const Tile = struct {
    src_rect: rl.Rectangle,
    dest_rect: rl.Rectangle,
    type: TileType,
    texture_number: i32
};

pub const EnemySpawnPos = struct {
    enemy_type: ene.EnemyType,
    spawn_pos: rl.Vector2
};

pub const Map = struct {
    map_size: rl.Vector2,
    tile_size: f32,
    data: []Tile,
    player_spawn_pos: rl.Vector2 = .{ .x = 10, .y = 10 },
    enemy_spawn_poses: []EnemySpawnPos = &[_]EnemySpawnPos{},
    objects: []obj.Object = &[_]obj.Object{},
    
    pub fn reset(self: *Map) void {
        main.player.reset();
        ene.enemies.clearRetainingCapacity();
        for (self.enemy_spawn_poses) |*enemy_spawn_pos| ene.summonEnemy(enemy_spawn_pos.enemy_type, enemy_spawn_pos.spawn_pos);
    }
    
    pub fn draw(self: *Map) void {
        for(self.data) |tile| {
            if(rl.checkCollisionRecs(tile.dest_rect, .{ .x = cam.camera.target.x - cam.camera.offset.x, .y = cam.camera.target.y - cam.camera.offset.y, .width = scr.sim_size.x, .height = scr.sim_size.y })) {
                rl.drawTexturePro(test_tile_atlas.texture, tile.src_rect, tile.dest_rect, .zero(), 0, .white);
                if(main.f3) for(self.objects) |*object| object.drawDebug();
            }
        }
    }
};

pub var maps: []Map = undefined;
var test_tile_atlas: TileAtlas = undefined;

pub fn loadMap(path: []const u8) !Map {
    var file = try std.fs.cwd().openFile(path, .{});
    defer file.close();
    
    const file_size = try file.getEndPos();
    const buffer = try main.allocator.alloc(u8, file_size);
    defer main.allocator.free(buffer);
    
    _ = try file.readAll(buffer);
    
    var parsed: std.json.Parsed(std.json.Value) = try std.json.parseFromSlice(std.json.Value, main.allocator, buffer, .{});
    defer parsed.deinit();
    
    const parsed_map = parsed.value.object;
    const layers_val = parsed_map.get("layers").?.array.getLast().object;
    
    const width = layers_val.get("width").?.integer;
    const height = layers_val.get("height").?.integer;
    const map_size = rl.Vector2{ .x = @floatFromInt(width), .y = @floatFromInt(height) };
    
    const tile_size = @as(f32, @floatFromInt(parsed_map.get("tilewidth").?.integer));
    
    const data_array = layers_val.get("data").?.array;
    
    var air_tiles: usize = 0;
    for(data_array.items) |tile| { if(tile.integer == -1) air_tiles += 1; }
    var data = try main.allocator.alloc(Tile, data_array.items.len - air_tiles);
    
    var variable_index: usize = 0;
    for(data_array.items, 0..) |d_array, index| {
        const texture_number = @as(i32, @intCast(d_array.integer));
        const tile_type: TileType = switch(texture_number) {
            0,1 => .SOLID,
            else => .AIR
        };
        
        if(tile_type != .AIR) {
            data[variable_index] = Tile{
                .src_rect = .{ .x = @as(f32, @floatFromInt(@mod(texture_number, test_tile_atlas.atlas_width))) * test_tile_atlas.atlas_tile_size, .y = @as(f32, @floatFromInt(@divFloor(texture_number, test_tile_atlas.atlas_width))) * test_tile_atlas.atlas_tile_size, .width = test_tile_atlas.atlas_tile_size, .height = test_tile_atlas.atlas_tile_size },
                .dest_rect = .{ .x = @mod(@as(f32, @floatFromInt(index)), map_size.x) * tile_size, .y = @floor(@as(f32, @floatFromInt(index)) / map_size.x) * tile_size, .width = tile_size, .height = tile_size },
                .type = tile_type,
                .texture_number = texture_number
            };
            variable_index += 1;
        }
    }
    
    return Map{ .map_size = map_size, .tile_size = tile_size, .data = data };
}

pub fn loadMapEx(path: []const u8, player_spawn_pos: rl.Vector2, enemy_spawn_poses: []EnemySpawnPos, objects: []obj.Object) !Map {
    var map = try loadMap(path);
    map.player_spawn_pos = player_spawn_pos;
    map.enemy_spawn_poses = enemy_spawn_poses;
    map.objects = objects;
    return map;
}

pub fn loadTileAtlas() void {
    test_tile_atlas = TileAtlas{
        .texture = rl.loadTexture("res/sprite/map_atlas.png") catch crsh.crash(.RAYLIB_ERROR),
        .atlas_tile_size = 32,
        .atlas_width = 8
    };
}

pub fn unloadTileAtlas() void {
    rl.unloadTexture(test_tile_atlas.texture);
}

pub fn initMaps() void {
    //TEMPORARY, MAKE A BETTER SYSTEM SO THAT YOU MINIMIZE DUPED CODE
    maps = main.mutateSlice(Map, &[_]Map{
        loadMapEx("res/data/test-map.json", .{ .x = 200, .y = 10 }, 
            main.mutateSlice(EnemySpawnPos, &[_]EnemySpawnPos{ EnemySpawnPos{ .enemy_type = .CIRCLE, .spawn_pos = .{ .x = 590, .y = 10 } } }),
            main.mutateSlice(obj.Object, &[_]obj.Object{ obj.Object{ .rect = .init(1000, 250, 100, 100), .obj_type = .ADVANCE_MAP } })
        ) catch crsh.crash(.MAP_ERROR),
        
        loadMapEx("res/data/test-map.json", .{ .x = 400, .y = 10 }, 
            main.mutateSlice(EnemySpawnPos, &[_]EnemySpawnPos{ EnemySpawnPos{ .enemy_type = .TRIANGLE, .spawn_pos = .{ .x = 590, .y = 10 } } }),
            main.mutateSlice(obj.Object, &[_]obj.Object{ obj.Object{ .rect = .init(1000, 200, 100, 100), .obj_type = .SOLID } })
        ) catch crsh.crash(.MAP_ERROR),
    });
}

pub fn moveToMap(map_number: usize) void {
    if(map_number < maps.len) {
        main.current_map = map_number;
        maps[main.current_map].reset();
    }
}

pub fn advanceMap() void {
    if(main.current_map + 1 < maps.len) {
        men.changeGameState(.MAP_TRANSITION);
        men.map_transition_timer.activate();
        men.map_transition_map_changed = false;
    }
}