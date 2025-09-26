const std = @import("std");
const rl = @import("raylib");
const main = @import("main.zig");
const scr = @import("screen.zig");

pub var camera: rl.Camera2D = undefined;

pub fn initCamera() void {
    camera = .{ .offset = .{ .x = scr.sim_size.x / 2, .y = scr.sim_size.y / 2 }, .rotation = 0, .target = main.player.data.pos, .zoom = 1 };
}

pub fn updateCamera() void {
    camera.target = main.player.data.pos;
    
    const clampx = std.math.clamp(camera.target.x, scr.sim_size.x / 2, main.test_map.map_size.x * main.test_map.tile_size - scr.sim_size.x / 2);
    const clampy = std.math.clamp(camera.target.y, scr.sim_size.y / 2, main.test_map.map_size.x * main.test_map.tile_size - scr.sim_size.y / 2);
    camera.target = .{ .x = clampx, .y = clampy };
}