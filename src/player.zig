const std = @import("std");
const rl = @import("raylib");
const main = @import("main.zig");
const crsh = @import("crash.zig");
const inp = @import("input.zig");
const ti = @import("timer.zig");
const ent = @import("entity.zig");
const scr = @import("screen.zig");
const men = @import("menu.zig");
const map = @import("map.zig");
const txt = @import("text.zig");
const sw = @import("sword.zig");

var player_atlas: rl.Texture2D = undefined;
var tinted_player_atlas: rl.Texture2D = undefined;
pub const def_player_size = rl.Vector2{ .x = 40, .y = 60 };
pub const base_player_health: f32 = 100;

pub const Player = struct {
    data: ent.EntityData = .{ .size = def_player_size, .is_player = true },
    animation_timer: ti.Timer = ti.Timer{ .auto_start = true, .duration = 0.3, .repeat = true },
    sword: sw.Sword = .{},
    
    pub fn update(self: *Player) void {
        if(inp.getHoldKey(.LEFT)) self.data.moveLeft() else if(inp.getHoldKey(.RIGHT)) self.data.moveRight() else if(!self.data.is_being_knocked) self.data.vel.x = 0;
        if(inp.getPressKey(.ATTACK)) self.sword.use();
        if(inp.getPressKey(.JUMP)) self.data.jump();
        if(inp.getPressKey(.JUMP) and self.data.can_walljump) {
            self.data.jumpMidAir(7);
            if(self.data.last_direction_right) self.data.knockBack(false, 3) else self.data.knockBack(true, 3);
        }
        
        self.data.update();
        self.data.updateAnimations(&self.animation_timer);
        
        if(self.data.health <= 0) men.changeGameState(.DIED);
        
        self.sword.update();
    }
    
    pub fn draw(self: *Player) void {
        const texture = if(self.data.hit_timer.active) tinted_player_atlas else player_atlas;
        const flip: f32 = if(self.data.last_direction_right) 1 else -1;
        rl.drawTexturePro(texture, .{ .x = 20 * @as(f32, @floatFromInt(@intFromEnum(self.data.anim_state))), .y = 0, .width = 20 * flip, .height = 30 }, 
            self.data.getRect(), .zero(), 0, self.data.color);
        self.sword.draw();
        if (main.f3) rl.drawRectangleLinesEx(self.data.getRect(), 3, .orange);
        if (main.f3) rl.drawRectangleLinesEx(self.data.getWallJumpHitBox(), 3, .sky_blue);
    }
    
    pub fn drawHealthBar(self: *Player) void {
        rl.drawRectangleRounded(.{ .x = scr.ui_buffer, .y = scr.ui_buffer, .width = 4 * self.data.health, .height = 40 }, 0.7, 100, .red);
        rl.drawRectangleRoundedLinesEx(.{ .x = scr.ui_buffer, .y = scr.ui_buffer, .width = 4 * base_player_health, .height = 40 }, 0.7, 100, 5, .black);
        txt.drawCustomText(std.fmt.allocPrintSentinel(main.allocator, "{d:.0}/{d:.0}", .{self.data.health, base_player_health}, 0) catch crsh.crash(.OUT_OF_MEMORY), .ELEVATIA, .ITALIC, 24, .{ .x = scr.ui_buffer * 2, .y = scr.ui_buffer * 2 }, .black);
    }
    
    pub fn reset(self: *Player) void {
        self.data.pos = map.maps[main.savefile.current_map].player_spawn_pos;
        self.data.vel = .zero();
        self.data.immunity_timer.activate();
        self.data.health = base_player_health;
        self.data.is_player = true;
    }
};

pub fn loadPlayer() void {
    player_atlas = rl.loadTexture("res/sprite/player_atlas.png") catch crsh.crash(.RAYLIB_ERROR);
    tinted_player_atlas = main.fullyTintTexture(player_atlas, .white);
}

pub fn unloadPlayer() void {
    defer rl.unloadTexture(player_atlas);
}

pub fn newPlayer() Player {
    var player = Player{ .data = .{ .pos = .{ .x = 10, .y = 10 }, .size = def_player_size, .speed = 3.5, .health = base_player_health } }; //THIS SUCKS! MAKE CUSTOM SPAWN POINTSD
    player.animation_timer.init();
    player.data.immunity_timer.init();
    return player;
}