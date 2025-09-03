const std = @import("std");
const rl = @import("raylib");
const main = @import("main.zig");
const ch = @import("crash_handler.zig");
const im = @import("input_manager.zig");
const mm = @import("map_manager.zig");

var player_atlas: rl.Texture2D = undefined;
const def_player_size = rl.Vector2{ .x = 40, .y = 60 };

pub const Player = struct {
    pos: rl.Vector2,
    vel: rl.Vector2,
    anim_state: PlayerAnimState,
    
    pub fn update(self: *Player) void {
        if(im.getHoldKey(.LEFT)) {
            self.vel.x = -3;
        } else if(im.getHoldKey(.RIGHT)) {
            self.vel.x = 3;
        } else {
            self.vel.x = 0;
        }
        
        if(im.getHoldKey(.UP)) {
            self.vel.y = -3;
        } else if(im.getHoldKey(.DOWN)) {
            self.vel.y = 3;
        } else {
            self.vel.y = 0;
        }
        
        self.pos.x += self.vel.x * main.dt;
        self.pos.y += self.vel.y * main.dt;
    }
    
    pub fn draw(self: *Player) void {
        rl.drawTexturePro(player_atlas, .{ .x = 20 * @as(f32, @floatFromInt(@intFromEnum(self.anim_state))), .y = 0, .width = 20, .height = 30 }, 
            .{ .x = self.pos.x, .y = self.pos.y, .width = def_player_size.x, .height = def_player_size.y }, 
            .zero(), 0, .white);
        if(main.f3) rl.drawRectangleLinesEx(.{ .x = self.pos.x, .y = self.pos.y, .width = def_player_size.x, .height = def_player_size.y }, 3, .orange);
    }
};

pub fn loadPlayer() void {
    player_atlas = rl.loadTexture("res/player_atlas.png") catch ch.crash(.RAYLIB_ERROR);
}

pub fn unloadPlayer() void {
    defer rl.unloadTexture(player_atlas);
}

pub fn newPlayer() Player {
    return Player{ .pos = .{ .x = 10, .y = 10 }, .vel = .zero(), .anim_state = .IDLE2 };
}

pub fn resetPlayer(player: *Player) void {
    _ = player;
}

const PlayerAnimState = enum {
    IDLE1,
    IDLE2,
    WALK1,
    WALK2,
    JUMP1,
    JUMP2
};

