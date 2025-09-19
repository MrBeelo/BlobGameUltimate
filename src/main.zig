const std = @import("std");
const rl = @import("raylib");
const ch = @import("crash_handler.zig");
const pl = @import("player.zig");
const im = @import("input_manager.zig");
const mm = @import("map_manager.zig");
const cm = @import("camera_manager.zig");
const sm = @import("screen_manager.zig");
const ene = @import("enemy.zig");

pub const allocator = std.heap.page_allocator;
pub var sim_fps: f32 = 60;
pub var dt: f32 = 0;
pub var f3 = false;
pub var test_map: mm.Map = undefined;
pub var player: pl.Player = undefined;
pub var circle: ene.Enemy = undefined; //THIS IS SHHHHIIIIIIIIIIIIIIIIIIIIIITTTTTT!!!!

pub fn main() void {
    rl.setConfigFlags(.{ .window_resizable = true });
    rl.initWindow(@intFromFloat(sm.window_size.x), @intFromFloat(sm.window_size.y), "Blob Game: Ultimate");
    defer rl.closeWindow();
    
    pl.loadPlayer();
    defer pl.unloadPlayer();
    player = pl.newPlayer();
    
    ene.loadEnemies();
    defer ene.unloadEnemies();
    circle = ene.newEnemy();
    
    mm.loadTileAtlas();
    defer mm.unloadTileAtlas();
    test_map = mm.loadMap("res/data/test-map.json") catch ch.crash(.MAP_ERROR);
    
    cm.initCamera();
    sm.initTarget();
    
    while (!rl.windowShouldClose()) {
        dt = rl.getFrameTime() * sim_fps;
        circle.update();
        player.update();
        
        im.updateInputManager();
        if(im.getPressKey(.F3)) f3 = !f3;
        
        cm.updateCamera();
        sm.updateTargetScale();
        
        if(sm.target.texture.id != 0) rl.beginTextureMode(sm.target);
        rl.clearBackground(.white);
        
        rl.beginMode2D(cm.camera);
        mm.drawMap(test_map);
        circle.draw();
        player.draw();
        rl.endMode2D();
        
        if(f3) rl.drawText(std.fmt.allocPrintSentinel(allocator, "FPS: {d:.1}", .{rl.getFPS()}, 0) catch ch.crash(.OUT_OF_MEMORY), 10, 10, 32, .black);
        rl.endTextureMode();
        
        rl.beginDrawing();
        defer rl.endDrawing();
        rl.clearBackground(.black);
        sm.drawTarget();
    }
}
