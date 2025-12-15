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
const sta = @import("stars.zig");
const int = @import("intro.zig");
const sha = @import("shake.zig");
const pop = @import("popup.zig");
const lit = @import("light.zig");
const res = @import("resources.zig");
const inv = @import("inventory.zig");
const set = @import("settings.zig");

pub const allocator = std.heap.page_allocator;
pub var sim_fps: f32 = 60;
pub var dt: f32 = 0;
pub var f3 = false;
pub var player: pl.Player = undefined;
pub var game_state: men.GameState = .MAIN;
pub var should_exit: bool = false;
pub var savefile: sav.SaveFile = undefined;
pub var settings: set.Settings = undefined;

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

pub fn formatString(comptime fmt: []const u8, args: anytype) []const u8 {
    return std.fmt.allocPrintSentinel(allocator, fmt, args, 0) catch crsh.crash(.OUT_OF_MEMORY);
}

pub fn nullTerStr(str: []const u8) [:0]const u8 {
    return allocator.dupeZ(u8, str) catch crsh.crash(.OUT_OF_MEMORY);
}

pub fn updateGame() void {
    map.maps[savefile.current_map].update();
    for(ene.enemies.items) |*enemy| if(enemy.getData().health > 0) enemy.update();
    player.update();
    cam.updateCamera();
    if(inp.getPressKey(.ESCAPE)) men.changeGameState(.PAUSED);
    sha.updateScreenShakeTimer();
    pop.updateMilkPopup();
}

pub fn drawGame() void {
    rl.beginMode2D(cam.camera);
    
    rl.beginShaderMode(res.tint_shader);
    map.maps[savefile.current_map].draw();
    rl.endShaderMode();
    
    for(ene.enemies.items) |*enemy| if(enemy.getData().health > 0) enemy.draw();
    player.draw();
    
    rl.endMode2D();
    
    lit.handleGlobalLights();
    
    rl.beginMode2D(cam.camera);
    lit.handleRelativeLights();
    rl.endMode2D();
    
    player.drawHealthBar();
    if(pop.milk_popup_timer.active) pop.drawMilkPopup();
    player.data.drawDialog();
    inv.drawInventory();
}

pub fn main() void {
    rl.setConfigFlags(.{ .window_resizable = true, .vsync_hint = true });
    
    rl.initWindow(@intFromFloat(scr.window_size.x), @intFromFloat(scr.window_size.y), "Blob Game: Ultimate");
    defer rl.closeWindow();
    
    rl.setExitKey(.null);
    
    res.loadResources();
    defer res.unloadResources();
    
    player = pl.newPlayer();
    
    ene.initEnemies();
    defer ene.deinitEnemies();
    
    sav.loadSaveFile(&savefile) catch crsh.crash(.SAVE_ERROR);
    set.loadSettings(&settings) catch crsh.crash(.SAVE_ERROR);
    
    map.initTileAtlas();
    cam.initCamera();
    scr.initTarget();
    men.initMenus();
    map.initMaps();
    bg.initBackgrounds();
    sta.initStars();
        
    while (!rl.windowShouldClose() and !should_exit) {
        dt = rl.getFrameTime() * sim_fps;
        inp.updateInputManager();
        if(inp.getPressKey(.F3)) f3 = !f3;
        scr.updateTargetScale();
        
        bg.updateBackground(bg.getBackgroundType());
        if(game_state == .PLAYING) updateGame() else men.updateMenus();
        
        if(scr.game_target.texture.id != 0) rl.beginTextureMode(scr.game_target);
        rl.clearBackground(.white);
        
        bg.drawBackground(bg.getBackgroundType());
        if(game_state == .PLAYING or game_state == .MAP_TRANSITION or game_state == .PAUSED) drawGame();
        
        rl.endTextureMode();
        
        if(scr.menu_target.texture.id != 0) rl.beginTextureMode(scr.menu_target);
        rl.clearBackground(.blank);
        
        if(game_state != .PLAYING and game_state != .MAP_TRANSITION) men.drawMenus();
        
        if(f3) {
            txt.drawCustomText(formatString("FPS: {d:.1}", .{rl.getFPS()}), .ELEVATIA, .NORMAL, 32, .{ .x = 10, .y = 80 }, .black);
            txt.drawCustomText(formatString("Current Map: {d}", .{savefile.current_map}), .ELEVATIA, .NORMAL, 32, .{ .x = 10, .y = 120 }, .black);
            txt.drawCustomText(formatString("Milk: {d}", .{savefile.milk}), .ELEVATIA, .NORMAL, 32, .{ .x = 10, .y = 160 }, .black);
            txt.drawCustomText(formatString("Position: [{d:.1}, {d:.1}]", .{player.data.pos.x, player.data.pos.y}), .ELEVATIA, .NORMAL, 32, .{ .x = 10, .y = 200 }, .black);
            txt.drawCustomText(formatString("Game State: {}", .{game_state}), .ELEVATIA, .NORMAL, 32, .{ .x = 10, .y = 240 }, .black);
        }
        
        rl.endTextureMode();
        
        rl.beginDrawing();
        defer rl.endDrawing();
        rl.clearBackground(.black);
        scr.drawTarget();
    }
}