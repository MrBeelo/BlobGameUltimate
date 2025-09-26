const std = @import("std");
const rl = @import("raylib");
const crsh = @import("crash.zig");
const pl = @import("player.zig");
const inp = @import("input.zig");
const map = @import("map.zig");
const cam = @import("camera.zig");
const scr = @import("screen.zig");
const ene = @import("enemy.zig");
const men = @import("menu.zig");
const txt = @import("text.zig");

pub const allocator = std.heap.page_allocator;
pub var sim_fps: f32 = 60;
pub var dt: f32 = 0;
pub var f3 = false;
pub var test_map: map.Map = undefined;
pub var player: pl.Player = undefined;
pub var game_state: men.GameState = .MAIN;
pub var should_exit: bool = false;

pub fn main() void {
    rl.setConfigFlags(.{ .window_resizable = true });
    
    rl.initWindow(@intFromFloat(scr.window_size.x), @intFromFloat(scr.window_size.y), "Blob Game: Ultimate");
    defer rl.closeWindow();
    
    rl.setExitKey(.null);
    
    txt.loadFonts();
    defer txt.unloadFonts();
    
    pl.loadPlayer();
    defer pl.unloadPlayer();
    player = pl.newPlayer();
    
    ene.loadEnemies();
    defer ene.unloadEnemies();
    ene.summonEnemy(.CIRCLE, .{ .x = 590, .y = 10 });
    ene.summonEnemy(.TRIANGLE, .{ .x = 890, .y = 10 });
    
    map.loadTileAtlas();
    defer map.unloadTileAtlas();
    test_map = map.loadMap("res/data/test-map.json") catch crsh.crash(.MAP_ERROR);
    
    cam.initCamera();
    scr.initTarget();
    
    men.initMenus();
    
    while (!rl.windowShouldClose() and !should_exit) {
        dt = rl.getFrameTime() * sim_fps;
        inp.updateInputManager();
        if(inp.getPressKey(.F3)) f3 = !f3;
        scr.updateTargetScale();
        
        if(game_state == .PLAYING) {
            for(ene.enemies.items) |*enemy| enemy.update();
            player.update();
            cam.updateCamera();
            if(inp.getPressKey(.ESCAPE)) game_state = .PAUSED;
        } else {
            men.updateMenus();
        }
        
        if(scr.target.texture.id != 0) rl.beginTextureMode(scr.target);
        rl.clearBackground(.white);
        
        if(game_state == .PLAYING) {
            rl.beginMode2D(cam.camera);
            map.drawMap(test_map);
            for(ene.enemies.items) |*enemy| enemy.draw();
            player.draw();
            rl.endMode2D();
        
            player.drawHealthBar();
        } else {
            men.drawMenus();
        }
        
        if(f3) rl.drawText(std.fmt.allocPrintSentinel(allocator, "FPS: {d:.1}", .{rl.getFPS()}, 0) catch crsh.crash(.OUT_OF_MEMORY), 10, 10, 32, .black);
        
        rl.endTextureMode();
        
        rl.beginDrawing();
        defer rl.endDrawing();
        rl.clearBackground(.black);
        scr.drawTarget();
    }
}