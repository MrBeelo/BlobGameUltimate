const std = @import("std");
const rl = @import("raylib");
const main = @import("main.zig");
const crsh = @import("crash.zig");
const cam = @import("camera.zig");
const scr = @import("screen.zig");
const ene = @import("enemy.zig");
const obj = @import("object.zig");
const men = @import("menu.zig");
const pl = @import("player.zig");
const sav = @import("savefile.zig");
const lit = @import("light.zig");
const res = @import("resources.zig");

pub const TileAtlas = struct {
    texture: rl.Texture2D,
    atlas_tile_size: f32,
    atlas_width: i32
};

pub const Tile = struct {
    src_rect: rl.Rectangle,
    dest_rect: rl.Rectangle,
    texture_number: i32,
    should_draw: bool = true,
    y_offset: f32 = 0,
    id: usize,
    
    pub fn getSimDestRect(self: *Tile) rl.Rectangle {
        return .{ .x = self.dest_rect.x, .y = self.dest_rect.y + self.y_offset, .width = self.dest_rect.width, .height = self.dest_rect.height };
    }
};

pub const EnemySpawnPos = struct {
    enemy_type: ene.EnemyType,
    spawn_pos: rl.Vector2
};

pub const Map = struct {
    map_size: rl.Vector2,
    tile_size: f32,
    id: usize,
    data: []Tile,
    player_spawn_pos: rl.Vector2 = .{ .x = 10, .y = 10 },
    enemy_spawn_poses: []EnemySpawnPos = &[_]EnemySpawnPos{},
    objects: []obj.Object = &[_]obj.Object{},
    milk_poses: []usize = &[_]usize{},
    lights: []lit.Light = &[_]lit.Light{},
    
    pub fn reset(self: *Map) void {
        main.player.reset();
        ene.enemies.clearRetainingCapacity();
        for (self.enemy_spawn_poses) |*enemy_spawn_pos| ene.summonEnemy(enemy_spawn_pos.enemy_type, enemy_spawn_pos.spawn_pos);
    }
    
    pub fn update(self: *Map) void {
        for(self.milk_poses) |milk_pos_index| {
            const time_diff = @as(f32, @floatCast(rl.getTime() - @floor(rl.getTime())));
            self.data[milk_pos_index - 1].y_offset = @sin(time_diff * 2 * std.math.pi) * 5;
        }
    }
    
    pub fn draw(self: *Map) void {
        for(self.data) |*tile| {
            if(rl.checkCollisionRecs(tile.dest_rect, .{ .x = cam.camera.target.x - cam.camera.offset.x, .y = cam.camera.target.y - cam.camera.offset.y, .width = scr.sim_size.x, .height = scr.sim_size.y })) {
                if(tile.should_draw) rl.drawTexturePro(tile_atlas.texture, tile.src_rect, tile.getSimDestRect(), .zero(), 0, .white);
            }
        }
        
        if(main.f3) for(self.objects) |*object| object.drawDebug();
    }
};

pub var maps: []Map = undefined;
var tile_atlas: TileAtlas = undefined;

pub fn loadMap(path: []const u8, id: usize) !Map {
    var file = try std.fs.cwd().openFile(path, .{});
    defer file.close();
    
    const file_size = try file.getEndPos();
    const buffer = try main.allocator.alloc(u8, file_size);
    defer main.allocator.free(buffer);
    
    _ = try file.readAll(buffer);
    
    var parsed: std.json.Parsed(std.json.Value) = try std.json.parseFromSlice(std.json.Value, main.allocator, buffer, .{});
    defer parsed.deinit();
    
    const layers = parsed.value.object.get("layers").?.array.items;
    var map_width: i64 = undefined;
    var map_height: i64 = undefined;
    var data_array: std.array_list.Managed(std.json.Value) = undefined;
    var player_spawn_pos = rl.Vector2{ .x = 0, .y = 0 };
    var enemy_spawn_poses = std.array_list.Managed(EnemySpawnPos).init(main.allocator);
    var objects = std.array_list.Managed(obj.Object).init(main.allocator);
    var lights = std.array_list.Managed(lit.Light).init(main.allocator);
    
    for (layers) |layer| {
        const eql = std.mem.eql;
        const layer_object = layer.object;
        const layer_name = layer_object.get("name").?.string;
        
        if(eql(u8, layer_name, "tiles")) {
            map_width = layer_object.get("width").?.integer;
            map_height = layer_object.get("height").?.integer;
            data_array = layer_object.get("data").?.array;
        } else if(eql(u8, layer_name, "objects")) {
            const tiled_objects = layer_object.get("objects").?.array.items;
            for(tiled_objects) |object| {
                const tiled_object_object = object.object; // I know this is confusing bare with me...
                const tiled_object_name = tiled_object_object.get("name").?.string;
                
                const x: f32 = @floatFromInt(tiled_object_object.get("x").?.integer);
                const y: f32 = @floatFromInt(tiled_object_object.get("y").?.integer);
                const width: f32 = @floatFromInt(tiled_object_object.get("width").?.integer);
                const height: f32 = @floatFromInt(tiled_object_object.get("height").?.integer);
                
                if(eql(u8, tiled_object_name, "") or eql(u8, tiled_object_name, "solid")) objects.append(.{ .obj_type = .SOLID, .rect = .{ .x = x, .y = y, .width = width, .height = height } }) catch crsh.crash(.OUT_OF_MEMORY);
                if(eql(u8, tiled_object_name, "hazard")) objects.append(.{ .obj_type = .HAZARD, .rect = .{ .x = x, .y = y, .width = width, .height = height } }) catch crsh.crash(.OUT_OF_MEMORY);
                if(eql(u8, tiled_object_name, "player")) player_spawn_pos = .{ .x = x, .y = y };
                if(eql(u8, tiled_object_name, "circle")) enemy_spawn_poses.append(.{ .enemy_type = .CIRCLE, .spawn_pos = .{ .x = x, .y = y } }) catch crsh.crash(.OUT_OF_MEMORY);
                if(eql(u8, tiled_object_name, "triangle")) enemy_spawn_poses.append(.{ .enemy_type = .TRIANGLE, .spawn_pos = .{ .x = x, .y = y } }) catch crsh.crash(.OUT_OF_MEMORY);
                if(eql(u8, tiled_object_name, "light")) {
                    const properties = tiled_object_object.get("properties").?.array.items;
                    const pos = rl.Vector2{ .x = x, .y = y };
                    var radius: f32 = 50;
                    var intensity: f32 = 1;
                    var color_string: []const u8 = "white";
                    
                    for(properties) |property| {
                        const property_object = property.object;
                        const property_name = property_object.get("name").?.string;
                        const property_value = property_object.get("value").?;
                        
                        if(eql(u8, property_name, "radius")) radius = @floatFromInt(property_value.integer);
                        if(eql(u8, property_name, "intensity")) intensity = @floatCast(property_value.float);
                        if(eql(u8, property_name, "color")) color_string = property_value.string;
                    }  
                    
                    var color: rl.Color = undefined;
                    if(eql(u8, color_string, "white")) color = .white;
                    if(eql(u8, color_string, "red")) color = .red;
                    if(eql(u8, color_string, "orange")) color = .orange;
                    if(eql(u8, color_string, "yellow")) color = .yellow;
                    if(eql(u8, color_string, "green")) color = .green;
                    if(eql(u8, color_string, "blue")) color = .blue;
                    
                    lights.append(.{ .pos = pos, .radius = radius, .intensity = intensity, .color = color }) catch crsh.crash(.OUT_OF_MEMORY);
                }
            }
        }
    }
    
    const map_size = rl.Vector2{ .x = @floatFromInt(map_width), .y = @floatFromInt(map_height) };
    const tile_size: f32 = 32;
    
    var shifted_data_array = std.array_list.Managed(i32).init(main.allocator);
    for(data_array.items) |d_array| {
        const texture_number = @as(i32, @intCast(d_array.integer));
        shifted_data_array.append(texture_number - 1) catch crsh.crash(.OUT_OF_MEMORY);
    }
    
    var air_tiles: usize = 0;
    for(shifted_data_array.items) |tile| { if(tile == -1) air_tiles += 1; }
    var data = try main.allocator.alloc(Tile, shifted_data_array.items.len - air_tiles);
    
    var milk_poses = std.array_list.Managed(usize).init(main.allocator);
    
    objects.append(.{ .obj_type = .ADVANCE_MAP, .rect = .{ .x = map_size.x * tile_size + pl.def_player_size.x / 2, .y = 0, .width = 10, .height = map_size.y * tile_size }}) catch crsh.crash(.OUT_OF_MEMORY);
    
    var variable_index: usize = 0;
    for(shifted_data_array.items, 0..) |texture_number, index| {
        const tile_pos: rl.Vector2 = .{ .x = @mod(@as(f32, @floatFromInt(index)), map_size.x) * tile_size, .y = @floor(@as(f32, @floatFromInt(index)) / map_size.x) * tile_size };
        
        if(texture_number != -1) {
            data[variable_index] = Tile{
                .src_rect = .{ .x = @as(f32, @floatFromInt(@mod(texture_number, tile_atlas.atlas_width))) * tile_atlas.atlas_tile_size, .y = @as(f32, @floatFromInt(@divFloor(texture_number, tile_atlas.atlas_width))) * tile_atlas.atlas_tile_size, .width = tile_atlas.atlas_tile_size, .height = tile_atlas.atlas_tile_size },
                .dest_rect = .{ .x = tile_pos.x, .y = tile_pos.y, .width = tile_size, .height = tile_size },
                .texture_number = texture_number,
                .id = variable_index
            };
            variable_index += 1;
        }
        
        const special_tile_row = 5;
        const horiz_spike_buffer: f32 = 10;
        const vert_spike_buffer: f32 = 15;
                
        switch (texture_number) {
            special_tile_row * 8 => objects.append(.{ .obj_type = .HAZARD, .rect = .{ .x = tile_pos.x + horiz_spike_buffer, .y = tile_pos.y + vert_spike_buffer, .width = tile_size - horiz_spike_buffer * 2, .height = tile_size - vert_spike_buffer }}) catch crsh.crash(.OUT_OF_MEMORY),
            special_tile_row * 8 + 1 => { 
                objects.append(.{ .obj_type = .MILK, .rect = .{ .x = tile_pos.x, .y = tile_pos.y, .width = tile_size, .height = tile_size } }) catch crsh.crash(.OUT_OF_MEMORY); 
                milk_poses.append(variable_index) catch crsh.crash(.OUT_OF_MEMORY);
                lights.append(.{ .pos = .{ .x = tile_pos.x + tile_size / 2, .y = tile_pos.y + tile_size / 2 }, .radius = 50, .intensity = 0.5, .color = .blue }) catch crsh.crash(.OUT_OF_MEMORY);
            },
            else => {}
        }
    }
            
    data_array.deinit();
    shifted_data_array.deinit();
    
    return Map{ .map_size = map_size, .tile_size = tile_size, .id = id, .data = data, .player_spawn_pos = player_spawn_pos, .enemy_spawn_poses = enemy_spawn_poses.items, .objects = objects.items, .milk_poses = milk_poses.items, .lights = lights.items };
}

pub fn loadMapEx(path: []const u8, player_spawn_pos: rl.Vector2, enemy_spawn_poses: []EnemySpawnPos, objects: []obj.Object) !Map {
    var map = try loadMap(path);
    map.player_spawn_pos = player_spawn_pos;
    map.enemy_spawn_poses = enemy_spawn_poses;
    map.objects = objects;
    return map;
}

pub fn initTileAtlas() void {
    tile_atlas = TileAtlas{
        .texture = res.tile_atlas_texture,
        .atlas_tile_size = 32,
        .atlas_width = 8
    };
}

pub fn initMaps() void {
    const map_amount = 4;
    var map_list = std.array_list.Managed(Map).init(main.allocator);
    for(0..map_amount) |index| map_list.append(loadMap(std.fmt.allocPrintSentinel(main.allocator, "res/map/{d}.json", .{index + 1}, 0) catch crsh.crash(.OUT_OF_MEMORY), index) catch crsh.crash(.MAP_ERROR )) catch crsh.crash(.OUT_OF_MEMORY);
    maps = map_list.toOwnedSlice() catch crsh.crash(.OUT_OF_MEMORY);
}

pub fn moveToMap(map_number: usize) void {
    if(map_number < maps.len) main.savefile.current_map = map_number;
    maps[main.savefile.current_map].reset();
    sav.saveSaveFile(&main.savefile) catch crsh.crash(.SAVE_ERROR);
}

pub fn resetAndStayAtMap() void {
    men.changeGameState(.MAP_TRANSITION);
    men.map_transition_timer.activate();
    men.map_transition_map_changed = false;
}

pub fn advanceMap() void {
    if(main.savefile.current_map + 1 < maps.len) {
        men.changeGameState(.MAP_TRANSITION);
        men.map_transition_timer.activate();
        men.map_transition_map_changed = false;
    }
}