const std = @import("std");
const rl = @import("raylib");
const main = @import("main.zig");
const ch = @import("crash_handler.zig");
const im = @import("input_manager.zig");
const mm = @import("map_manager.zig");
const ti = @import("timer.zig");
const ent = @import("entity.zig");

var player_atlas: rl.Texture2D = undefined;
pub const def_player_size = rl.Vector2{ .x = 40, .y = 60 };
var animation_timer: ti.Timer = ti.Timer{ .auto_start = true, .duration = 0.3, .repeat = true };
pub const base_health: f32 = 100;

pub const Player = struct {
    data: ent.EntityData = .{ .size = def_player_size },
    
    pub fn update(self: *Player) void {
        if(im.getHoldKey(.LEFT)) self.data.moveLeft() else if(im.getHoldKey(.RIGHT)) self.data.moveRight() else self.data.vel.x = 0;
        if(im.getPressKey(.JUMP)) self.data.jump();
        
        self.data.update();
        self.data.updateAnimations(&animation_timer);
    }
    
    pub fn draw(self: *Player) void {
        const flip: f32 = if(self.data.last_direction_right) 1 else -1;
        rl.drawTexturePro(player_atlas, .{ .x = 20 * @as(f32, @floatFromInt(@intFromEnum(self.data.anim_state))), .y = 0, .width = 20 * flip, .height = 30 }, 
            self.data.getRect(), .zero(), 0, .white);
        if (main.f3) rl.drawRectangleLinesEx(self.data.getRect(), 3, .orange);
    }
};

pub fn loadPlayer() void {
    player_atlas = rl.loadTexture("res/sprite/player_atlas.png") catch ch.crash(.RAYLIB_ERROR);
    animation_timer.init();
}

pub fn unloadPlayer() void {
    defer rl.unloadTexture(player_atlas);
}

pub fn newPlayer() Player {
    return Player{ .data = .{ .pos = .{ .x = 10, .y = 10 }, .size = def_player_size, .speed = 3.5, .health = base_health } }; //THIS SUCKS! MAKE CUSTOM SPAWN POINTSD
}

