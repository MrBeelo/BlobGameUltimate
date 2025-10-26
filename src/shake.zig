const std = @import("std");
const rl = @import("raylib");
const ti = @import("timer.zig");

var screen_shake_timer = ti.Timer{ .duration = 1 };
var screen_shake_intensity: f32 = 1;

pub fn screenShakeModifier() rl.Vector2 {
    if(screen_shake_timer.active) {
        const intensity = @as(i32, @intFromFloat(screen_shake_intensity));
        return .{ .x = @floatFromInt(rl.getRandomValue(-intensity * 2, intensity * 2)), .y = @floatFromInt(rl.getRandomValue(-intensity, intensity)) };
    } else {
        return .{ .x = 0, .y = 0 };
    }
}

pub fn updateScreenShakeTimer() void {
    screen_shake_timer.update();
}

pub fn shakeScreen(duration: f32, intensity: f32) void {
    screen_shake_timer.duration = duration;
    screen_shake_intensity = intensity;
    screen_shake_timer.activate();
}