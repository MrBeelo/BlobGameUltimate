const std = @import("std");
const rl = @import("raylib");
const main = @import("main.zig");
const ch = @import("crash_handler.zig");
const im = @import("input_manager.zig");
const mm = @import("map_manager.zig");
const ti = @import("timer.zig");
const ent = @import("entity.zig");

var circle_atlas: rl.Texture2D = undefined;
pub const def_circle_size = rl.Vector2{ .x = 40, .y = 60 };

const EnemyType = enum {
    CIRCLE,
    TRIANGLE,
    TRIANGLE_BOSS
};

pub const Enemy = struct {
    data: ent.EntityData = .{ .size = def_circle_size }, //CHANGE CHNAGE
    type: EnemyType = .CIRCLE,
    detection_radius: f32 = 350,
    animation_timer: ti.Timer = .{ .auto_start = true, .duration = 0.3, .repeat = true },
    direction_timer: ti.Timer = .{ .auto_start = true, .duration = 2, .repeat = true },
    idle_direction_right: bool = true,
    
    pub fn update(self: *Enemy) void {
        if(!self.animation_timer.active) self.animation_timer.init(); // would like to do another way but whatever
        if(!self.direction_timer.active) self.direction_timer.init();
        
        self.runAI();
        
        self.data.update();
        
        self.animation_timer.update();
        if(self.animation_timer.called) self.data.handleBaseAnims();
        self.data.handleAnimEdgeCases();
    }
    
    pub fn draw(self: *Enemy) void {
        const flip: f32 = if(self.data.last_direction_right) 1 else -1;
        //change circle_atlas to atlas based on type
        rl.drawTexturePro(circle_atlas, .{ .x = 20 * @as(f32, @floatFromInt(@intFromEnum(self.data.anim_state))), .y = 0, .width = 20 * flip, .height = 30 }, 
            self.data.getRect(), .zero(), 0, .white);
        if (main.f3) rl.drawRectangleLinesEx(self.data.getRect(), 3, .orange);
    }
    
    fn playerClose(self: *Enemy) bool {
        const player = main.player.data;
        if(player.pos.x - self.data.pos.x >= -self.detection_radius and self.data.pos.x - player.pos.x <= self.detection_radius and player.pos.y - self.data.pos.y >= -self.detection_radius and self.data.pos.y - player.pos.y <= self.detection_radius) return true;
        return false;
    }
    
    // beelo partially approves, though i want to improve it more :)
    pub fn runAI(self: *Enemy) void {
        const player = main.player.data;
        self.direction_timer.update();
        if(self.direction_timer.called) self.idle_direction_right = !self.idle_direction_right;
        
        if(self.data.collisionsX[0] or self.data.collisionsX[1]) {
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
    circle_atlas = rl.loadTexture("res/sprite/circle_atlas.png") catch ch.crash(.RAYLIB_ERROR);
}

pub fn unloadEnemies() void {
    rl.unloadTexture(circle_atlas);
}

pub fn newEnemy() Enemy {
    return Enemy{ .data = .{ .pos = .{ .x = 590, .y = 10 }, .size = def_circle_size, .speed = 2 } }; //NO!!!!!!!!!!
}