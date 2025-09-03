const std = @import("std");
const rl = @import("raylib");
const ch = @import("crash_handler.zig");
const pl = @import("player.zig");
const im = @import("input_manager.zig");
const mm = @import("map_manager.zig");

pub const allocator = std.heap.page_allocator;
pub const sim_size: rl.Vector2 = .{ .x = 800, .y = 450 };
pub var sim_fps: f32 = 60;
pub var dt: f32 = 0;
pub var f3 = false;
pub var test_map: mm.Map = undefined;

pub fn main() anyerror!void {
    rl.initWindow(sim_size.x, sim_size.y, "Blob Game: Ultimate");
    defer rl.closeWindow();
    
    pl.loadPlayer();
    defer pl.unloadPlayer();
    var player = pl.newPlayer();
    
    mm.loadTileAtlas();
    defer mm.unloadTileAtlas();
    test_map = mm.loadMap("res/data/test-map.json") catch ch.crash(.MAP_ERROR);

    while (!rl.windowShouldClose()) {
        dt = rl.getFrameTime() * sim_fps;
        player.update();
        im.updateInputManager();
        if(im.getPressKey(.F3)) f3 = !f3;
        
        rl.beginDrawing();
        defer rl.endDrawing();
        rl.clearBackground(.white);
        
        mm.drawMap(test_map);
        player.draw();
    }
}
