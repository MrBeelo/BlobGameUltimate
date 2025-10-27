const std = @import("std");
const rl = @import("raylib");
const crsh = @import("crash.zig");
const main = @import("main.zig");

pub var mm_blob_strip: rl.Texture2D = undefined;
pub var zig_logo: rl.Texture2D = undefined;
pub var raylib_logo: rl.Texture2D = undefined;

pub var circle_atlas: rl.Texture2D = undefined;
pub var triangle_atlas: rl.Texture2D = undefined;

pub var cutscene_image_1: rl.Texture2D = undefined;
pub var cutscene_image_2: rl.Texture2D = undefined;
pub var cutscene_image_3: rl.Texture2D = undefined;

pub var blob_logo: rl.Texture2D = undefined;

pub var player_atlas: rl.Texture2D = undefined;
pub var tinted_player_atlas: rl.Texture2D = undefined;

pub var blur_shader: rl.Shader = undefined;

pub var sword_texture: rl.Texture2D = undefined;

pub var elevatia: rl.Font = undefined;
pub var elevatia_italic: rl.Font = undefined;
pub var dancing_script: rl.Font = undefined;

pub var tile_atlas_texture: rl.Texture2D = undefined;

fn crash() noreturn {
    crash();
}

pub fn loadResources() void {
    mm_blob_strip = rl.loadTexture("res/sprite/menu/blob_strip.png") catch crash();
    zig_logo = rl.loadTexture("res/sprite/menu/zig_logo.png") catch crash();
    raylib_logo = rl.loadTexture("res/sprite/menu/raylib_logo.png") catch crash();
    
    circle_atlas = rl.loadTexture("res/sprite/entity/circle_atlas.png") catch crash();
    triangle_atlas = rl.loadTexture("res/sprite/entity/triangle_atlas.png") catch crash();
    
    cutscene_image_1 = rl.loadTexture("res/sprite/cutscene/blob_cutscene_1.png") catch crash();
    cutscene_image_2 = rl.loadTexture("res/sprite/cutscene/blob_cutscene_2.png") catch crash();
    cutscene_image_3 = rl.loadTexture("res/sprite/cutscene/blob_cutscene_3.png") catch crash();
    
    blob_logo = rl.loadTexture("res/sprite/menu/blob_logo.png") catch crash();
    
    player_atlas = rl.loadTexture("res/sprite/entity/player_atlas.png") catch crash();
    tinted_player_atlas = main.fullyTintTexture(player_atlas, .white);
    
    blur_shader = rl.loadShader(null, "res/shader/blur.fs") catch crash();
    
    sword_texture = rl.loadTexture("res/sprite/entity/sword.png") catch crash();
    
    elevatia = rl.loadFontEx("res/font/elevatia.ttf", 100, null) catch crash();
    elevatia_italic = rl.loadFontEx("res/font/elevatia_italic.ttf", 100, null) catch crash();
    dancing_script = rl.loadFontEx("res/font/dancing_script.ttf", 200, null) catch crash();
    
    tile_atlas_texture = rl.loadTexture("res/sprite/tileset.png") catch crash();
}

pub fn unloadResources() void {
    rl.unloadTexture(mm_blob_strip);
    rl.unloadTexture(zig_logo);
    rl.unloadTexture(raylib_logo);
    
    rl.unloadTexture(circle_atlas);
    rl.unloadTexture(triangle_atlas);
    
    rl.unloadTexture(cutscene_image_1);
    rl.unloadTexture(cutscene_image_2);
    rl.unloadTexture(cutscene_image_3);
    
    rl.unloadTexture(blob_logo);
    
    rl.unloadTexture(player_atlas);
    
    rl.unloadShader(blur_shader);
    
    rl.unloadTexture(sword_texture);
    
    rl.unloadFont(elevatia);
    rl.unloadFont(elevatia_italic);
    rl.unloadFont(dancing_script);
    
    rl.unloadTexture(tile_atlas_texture);
}