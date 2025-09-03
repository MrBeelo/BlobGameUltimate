const std = @import("std");
const rl = @import("raylib");
const ch = @import("crash_handler.zig");
const pl = @import("player.zig");
const im = @import("input_manager.zig");
const mm = @import("map_manager.zig");
const cm = @import("camera_manager.zig");

pub const allocator = std.heap.page_allocator;
pub const sim_size: rl.Vector2 = .{ .x = 800, .y = 450 };
pub var sim_fps: f32 = 60;
pub var dt: f32 = 0;
pub var f3 = false;
pub var test_map: mm.Map = undefined;
pub var player: pl.Player = undefined;
pub var camera: rl.Camera2D = undefined;

pub fn main() anyerror!void {
    rl.initWindow(sim_size.x, sim_size.y, "Blob Game: Ultimate");
    defer rl.closeWindow();
    
    pl.loadPlayer();
    defer pl.unloadPlayer();
    player = pl.newPlayer();
    
    mm.loadTileAtlas();
    defer mm.unloadTileAtlas();
    test_map = mm.loadMap("res/data/test-map.json") catch ch.crash(.MAP_ERROR);
    
    camera = .{ .offset = .{ .x = sim_size.x / 2, .y = sim_size.y / 2 }, .rotation = 0, .target = player.pos, .zoom = 1 };
    
    while (!rl.windowShouldClose()) {
        dt = rl.getFrameTime() * sim_fps;
        player.update();
        im.updateInputManager();
        if(im.getPressKey(.F3)) f3 = !f3;
        cm.updateCamera();
        
        rl.beginDrawing();
        rl.beginMode2D(camera);
        defer rl.endDrawing();
        rl.clearBackground(.white);
        
        mm.drawMap(test_map);
        player.draw();
        rl.endMode2D();
        if(f3) rl.drawText(std.fmt.allocPrintSentinel(allocator, "FPS: {d:.1}", .{rl.getFPS()}, 0) catch ch.crash(.OUT_OF_MEMORY), 10, 10, 32, .black);
    }
}
