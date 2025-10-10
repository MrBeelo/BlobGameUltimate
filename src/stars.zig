const std = @import("std");
const rl = @import("raylib");
const scr = @import("screen.zig");

pub const Star = struct {
    pos: rl.Vector2 = .{ .x = 0, .y = 0 },
    rot: f32 = 0,
    delay_factor: f32 = 0
};

const default_star = Star{};
pub var stars: [100]Star = [_]Star{default_star} ** 100;

pub fn initStars() void {
    for(&stars, 0..) |*star, index| {
        star.pos = rl.Vector2{ .x = @floatFromInt(rl.getRandomValue(0, @intFromFloat(scr.sim_size.x))), .y = @floatFromInt(rl.getRandomValue(0, @intFromFloat(scr.sim_size.y))) };
        star.rot = @floatFromInt(rl.getRandomValue(0, 360));
        star.delay_factor = @as(f32, @floatFromInt(index)) / stars.len;
    }
}