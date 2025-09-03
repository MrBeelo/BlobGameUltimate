const std = @import("std");
const rl = @import("raylib");
const main = @import("main.zig");

pub fn updateCamera() void {
    main.camera.target = main.player.pos;
    
    const clampx = std.math.clamp(main.camera.target.x, main.sim_size.x / 2, main.test_map.map_size.x * main.test_map.tile_size - main.sim_size.x / 2);
    const clampy = std.math.clamp(main.camera.target.y, main.sim_size.y / 2, main.test_map.map_size.x * main.test_map.tile_size - main.sim_size.y / 2);
    main.camera.target = .{ .x = clampx, .y = clampy };
}