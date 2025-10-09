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
const sw = @import("sword.zig");
const sav = @import("savefile.zig");
const bg = @import("background.zig");

pub const allocator = std.heap.page_allocator;
pub var sim_fps: f32 = 60;
pub var dt: f32 = 0;
pub var f3 = false;
pub var player: pl.Player = undefined;
pub var game_state: men.GameState = .MAIN;
pub var should_exit: bool = false;
pub var savefile: sav.SaveFile = undefined;

pub fn mutateSlice(comptime T: type, slice: []const T) []T {
    const mut_slice = allocator.alloc(T, slice.len) catch crsh.crash(.OUT_OF_MEMORY);
    std.mem.copyForwards(T, mut_slice, slice);
    return mut_slice;
}

pub fn fullyTintTexture(texture: rl.Texture2D, color: rl.Color) rl.Texture2D {
    var image = rl.loadImageFromTexture(texture) catch crsh.crash(.RAYLIB_ERROR);
    for(0..(@intCast(texture.width * texture.height))) |index| {
        const parsed_color = rl.getImageColor(image, @mod(@as(i32, @intCast(index)), texture.width), @divFloor(@as(i32, @intCast(index)), texture.width));
        if((parsed_color.r != color.r or parsed_color.g != color.g or parsed_color.b != color.b) and parsed_color.a != 0) rl.imageColorReplace(&image, parsed_color, color);
    }
    const new_texture = rl.loadTextureFromImage(image) catch crsh.crash(.RAYLIB_ERROR);
    rl.unloadImage(image);
    return new_texture;
}

pub fn updateGame() void {
    bg.updateBackground(.BB1);
    map.maps[savefile.current_map].update();
    for(ene.enemies.items) |*enemy| enemy.update();
    player.update();
    cam.updateCamera();
    if(inp.getPressKey(.ESCAPE)) men.changeGameState(.PAUSED);
}

pub fn drawGame() void {
    bg.drawBackground(.BB1);
    rl.beginMode2D(cam.camera);
    map.maps[savefile.current_map].draw();
    for(ene.enemies.items) |*enemy| enemy.draw();
    player.draw();
    rl.endMode2D();
    player.drawHealthBar();
}

pub fn main() void {
    rl.setConfigFlags(.{ .window_resizable = true, .vsync_hint = true });
    
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
    
    map.loadTileAtlas();
    defer map.unloadTileAtlas();
    
    cam.initCamera();
    scr.initTarget();
    
    men.initMenus();
    map.initMaps();
    
    sw.loadSword();
    defer sw.unloadSword();
    
    bg.loadBackgrounds();
    defer bg.unloadBackgrounds();
    
    sav.loadSaveFile(&savefile) catch crsh.crash(.SAVE_ERROR);
    
    while (!rl.windowShouldClose() and !should_exit) {
        dt = rl.getFrameTime() * sim_fps;
        inp.updateInputManager();
        if(inp.getPressKey(.F3)) f3 = !f3;
        scr.updateTargetScale();
        
        if(game_state == .PLAYING) updateGame() else men.updateMenus();
        
        if(scr.target.texture.id != 0) rl.beginTextureMode(scr.target);
        rl.clearBackground(.white);
        
        if(game_state == .PLAYING or game_state == .MAP_TRANSITION) {
            drawGame();
        } else if(game_state == .PAUSED) {
            drawGame();
            men.drawMenus();
        } else {
            men.drawMenus();
        }
        
        if(f3) txt.drawCustomText(std.fmt.allocPrintSentinel(allocator, "FPS: {d:.1}", .{rl.getFPS()}, 0) catch crsh.crash(.OUT_OF_MEMORY), .ELEVATIA, .NORMAL, 32, .{ .x = 10, .y = 80 }, .black);
        if(f3) txt.drawCustomText(std.fmt.allocPrintSentinel(allocator, "Current Map: {d}", .{savefile.current_map}, 0) catch crsh.crash(.OUT_OF_MEMORY), .ELEVATIA, .NORMAL, 32, .{ .x = 10, .y = 120 }, .black);
        if(f3) txt.drawCustomText(std.fmt.allocPrintSentinel(allocator, "Milk: {d}", .{savefile.milk}, 0) catch crsh.crash(.OUT_OF_MEMORY), .ELEVATIA, .NORMAL, 32, .{ .x = 10, .y = 160 }, .black);
        if(f3) txt.drawCustomText(std.fmt.allocPrintSentinel(allocator, "Position: [{d:.1}, {d:.1}]", .{player.data.pos.x, player.data.pos.y}, 0) catch crsh.crash(.OUT_OF_MEMORY), .ELEVATIA, .NORMAL, 32, .{ .x = 10, .y = 200 }, .black);
        
        rl.endTextureMode();
        
        rl.beginDrawing();
        defer rl.endDrawing();
        rl.clearBackground(.black);
        scr.drawTarget();
    }
}