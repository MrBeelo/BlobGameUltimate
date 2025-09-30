const std = @import("std");
const rl = @import("raylib");
const main = @import("main.zig");
const crsh = @import("crash.zig");
const pl = @import("player.zig");
const ti = @import("timer.zig");

var sword_texture: rl.Texture2D = undefined;
const def_sword_size = rl.Vector2{ .x = 30, .y = 80 };
const relative_pivot_pos = rl.Vector2{ .x = def_sword_size.x / 2, .y = def_sword_size.y * 5 / 8 };

pub const Sword = struct {
    sword_active_timer: ti.Timer = .{ .duration = 0.2 },
    pivot: rl.Vector2 = .{ .x = 0, .y = 0 },
    rot: f32 = 0,
    flip: f32 = 1,
    
    pub fn getTip(self: *Sword) rl.Vector2 {
        return rl.Vector2{
            .x = self.pivot.x - relative_pivot_pos.x * self.flip * -@sin(self.rot * std.math.pi / 180) * std.math.pi,
            .y = self.pivot.y - relative_pivot_pos.y * @cos(self.rot * std.math.pi / 180)
        };
    }
    
    pub fn checkSwordCollision(self: *Sword, rec: rl.Rectangle) bool {
        const pivot = self.pivot;
        const tip = self.getTip();
        const middle_steps: f32 = 5;
        
        for(0..middle_steps) |index| {
            const pos_on_line = @as(f32, @floatFromInt(index)) / middle_steps;
            const point = rl.Vector2{ 
                .x = pivot.x + (tip.x - pivot.x) * pos_on_line,
                .y = pivot.y + (tip.y - pivot.y) * pos_on_line
            };
            if(self.sword_active_timer.active and rl.checkCollisionPointRec(point, rec)) return true;
        }
        
        return false;
    }
    
    pub fn use(self: *Sword) void {
        if(!self.sword_active_timer.active) {
            self.rot = 15;
            self.sword_active_timer.activate();
        }
    }
    
    pub fn update(self: *Sword) void {
        self.sword_active_timer.update();
        
        const dir_modifier: f32 = if(self.flip == 1) pl.def_player_size.x else 0;
        self.pivot.x = main.player.data.pos.x + dir_modifier + (relative_pivot_pos.x - 10) * self.flip;
        self.pivot.y = main.player.data.pos.y + relative_pivot_pos.y - 5;

        if(self.sword_active_timer.active) self.rot += main.dt * 10;
        if(!self.sword_active_timer.active) self.flip = if(main.player.data.last_direction_right) 1 else -1;
    }
    
    pub fn draw(self: *Sword) void {
        if(self.sword_active_timer.active) rl.drawTexturePro(sword_texture, rl.Rectangle{ .x = 0, .y = 0, .width = 15, .height = 40 }, .{ .x = self.pivot.x, .y = self.pivot.y, .width = def_sword_size.x, .height = def_sword_size.y }, relative_pivot_pos, self.rot * self.flip, .white);
        if(main.f3) rl.drawCircleV(self.pivot, 5, .sky_blue);
        if(main.f3) rl.drawCircleV(self.getTip(), 5, .red);
    }
};

pub fn loadSword() void {
    sword_texture = rl.loadTexture("res/sprite/sword.png") catch crsh.crash(.RAYLIB_ERROR);
}

pub fn unloadSword() void {
    rl.unloadTexture(sword_texture);
}