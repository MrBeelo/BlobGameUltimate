const std = @import("std");
const rl = @import("raylib");
const main = @import("main.zig");
const ch = @import("crash_handler.zig");
const im = @import("input_manager.zig");
const mm = @import("map_manager.zig");
const ti = @import("timer.zig");
const ent = @import("entity.zig");
const pl = @import("player.zig");

var circle_atlas: rl.Texture2D = undefined;
var triangle_atlas: rl.Texture2D = undefined;
pub var enemies: std.array_list.Managed(Enemy) = undefined;

const EnemyType = enum {
    CIRCLE,
    TRIANGLE,
    TRIANGLE_BOSS
};

pub const Enemy = struct {
    data: ent.EntityData,
    type: EnemyType = .CIRCLE,
    texture: rl.Texture2D,
    detection_radius: f32,
    animation_timer: ti.Timer = .{ .auto_start = true, .duration = 0.3, .repeat = true },
    direction_timer: ti.Timer = .{ .auto_start = true, .duration = 2, .repeat = true },
    idle_direction_right: bool = true,
    damage_dealt: f32 = 10,
    
    pub fn update(self: *Enemy) void {  
        self.runAI();
        self.data.update();
        self.data.updateAnimations(&self.animation_timer);
        if(self.data.getRect().checkCollision(main.player.data.getRect()) and !main.player.immunity_timer.active) {
            main.player.data.health -= self.damage_dealt;
            main.player.immunity_timer.activate();
        }
    }
    
    pub fn draw(self: *Enemy) void {
        const flip: f32 = if(self.data.last_direction_right) 1 else -1;
        rl.drawTexturePro(self.texture, .{ .x = 20 * @as(f32, @floatFromInt(@intFromEnum(self.data.anim_state))), .y = 0, .width = 20 * flip, .height = 30 }, 
            self.data.getRect(), .zero(), 0, .white);
        if (main.f3) rl.drawRectangleLinesEx(self.data.getRect(), 3, .red);
    }
    
    pub fn playerClose(self: *Enemy) bool {
        const player = main.player.data;
        if(player.pos.x - self.data.pos.x >= -self.detection_radius and player.pos.x - self.data.pos.x < self.detection_radius and player.pos.y - self.data.pos.y >= -self.detection_radius and player.pos.y - self.data.pos.y < self.detection_radius) return true;
        return false;
    }
    
    // beelo partially approves, though i want to improve it more :)
    pub fn runAI(self: *Enemy) void {
        const player = main.player.data;
        self.direction_timer.update();
        if(self.direction_timer.called) self.idle_direction_right = !self.idle_direction_right;
        
        if(self.data.collisionsX[@intFromEnum(ent.CollisionDirectionX.LEFT)] or self.data.collisionsX[@intFromEnum(ent.CollisionDirectionX.RIGHT)]) {
            const rand = rl.getRandomValue(0, 2);
            if(rand != 0) self.idle_direction_right = !self.idle_direction_right else self.data.jump();
            self.direction_timer.start_time = @floatCast(rl.getTime());
        }
        
        if(self.playerClose()) {
            if(self.data.pos.x >= player.pos.x) self.data.moveLeft() else self.data.moveRight();
        } else {
            if(self.idle_direction_right) self.data.moveRight() else self.data.moveLeft();
        }
    }
};

pub fn loadEnemies() void {
    enemies = std.array_list.Managed(Enemy).init(main.allocator);
    circle_atlas = rl.loadTexture("res/sprite/circle_atlas.png") catch ch.crash(.RAYLIB_ERROR);
    triangle_atlas = rl.loadTexture("res/sprite/triangle_atlas.png") catch ch.crash(.RAYLIB_ERROR);
}

pub fn unloadEnemies() void {
    enemies.deinit();
    rl.unloadTexture(circle_atlas);
    rl.unloadTexture(triangle_atlas);
}

pub fn newEnemy(ent_type: EnemyType, pos: rl.Vector2) Enemy {
    const size: rl.Vector2 = switch (ent_type) {
        .CIRCLE => .{ .x = 40, .y = 60 },
        .TRIANGLE => .{ .x = 40, .y = 60 },
        .TRIANGLE_BOSS => .{ .x = 40, .y = 60 }
    };
    
    const speed: f32 = switch (ent_type) {
        .CIRCLE => 1.2,
        .TRIANGLE => 2,
        .TRIANGLE_BOSS => 2.4
    };
    
    const health: f32 = switch (ent_type) {
        .CIRCLE => 30,
        .TRIANGLE => 20,
        .TRIANGLE_BOSS => 1000
    };
    
    const texture: rl.Texture2D = switch (ent_type) {
        .CIRCLE => circle_atlas,
        .TRIANGLE => triangle_atlas,
        .TRIANGLE_BOSS => triangle_atlas
    };
    
    const detection_radius: f32 = switch (ent_type) {
        .CIRCLE => 200,
        .TRIANGLE => 350,
        .TRIANGLE_BOSS => 400
    };
    
    const damage_dealt: f32 = switch (ent_type) {
        .CIRCLE => 10,
        .TRIANGLE => 20,
        .TRIANGLE_BOSS => 30
    };
    
    var enemy = Enemy{ .data = .{ .pos = pos, .size = size, .speed = speed, .health = health }, .texture = texture, .detection_radius = detection_radius, .damage_dealt = damage_dealt };   
    
    enemy.animation_timer.init();
    enemy.direction_timer.init();
    
    return enemy;
}

pub fn summonEnemy(ent_type: EnemyType, pos: rl.Vector2) void {
    enemies.append(newEnemy(ent_type, pos)) catch ch.crash(.OUT_OF_MEMORY);
}