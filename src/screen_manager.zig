const std = @import("std");
const rl = @import("raylib");
const main = @import("main.zig");
const ch = @import("crash_handler.zig");

pub const sim_size: rl.Vector2 = .{ .x = 1920, .y = 1080 };
pub var window_size: rl.Vector2 = .{ .x = 1920, .y = 1080 };
pub var target: rl.RenderTexture2D = undefined;
var target_scale: f32 = undefined;

pub fn initTarget() void {
    target = rl.loadRenderTexture(sim_size.x, sim_size.y) catch ch.crash(.RAYLIB_ERROR);
    rl.setTextureFilter(target.texture, .bilinear);
}

pub fn updateTargetScale() void {
    window_size = .{ .x = @floatFromInt(rl.getScreenWidth()), .y = @floatFromInt(rl.getScreenHeight()) };
    target_scale = @min(window_size.x / sim_size.x, window_size.y / sim_size.y);
}

pub fn drawTarget() void {
    const target_src = rl.Rectangle{ .x = 0, .y = 0, .width = @floatFromInt(target.texture.width), .height = @floatFromInt(-target.texture.height) };
    const target_dest = rl.Rectangle{ .x = (window_size.x - sim_size.x * target_scale) * 0.5, .y = (window_size.y - sim_size.y * target_scale) * 0.5, .width = sim_size.x * target_scale, .height = sim_size.y * target_scale };
    rl.drawTexturePro(target.texture, target_src, target_dest, .zero(), 0, .white);
}