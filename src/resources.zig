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

pub var sign1: rl.Texture2D = undefined;

pub var sword_item: rl.Texture2D = undefined;

pub var shrine: rl.Texture2D = undefined;

fn loadT(file_path: [:0]const u8) rl.Texture {
    return rl.loadTexture(file_path) catch crsh.crash(.RAYLIB_ERROR);
}

fn loadS(file_path: [:0]const u8) rl.Shader {
    return rl.loadShader(null, file_path) catch crsh.crash(.RAYLIB_ERROR);
}

fn loadF(file_path: [:0]const u8) rl.Font {
    return rl.loadFontEx(file_path, 200, null) catch crsh.crash(.RAYLIB_ERROR);
}

pub fn loadResources() void {
    mm_blob_strip = loadT("res/sprite/menu/blob_strip.png");
    zig_logo = loadT("res/sprite/menu/zig_logo.png");
    raylib_logo = loadT("res/sprite/menu/raylib_logo.png");
    
    circle_atlas = loadT("res/sprite/entity/circle_atlas.png");
    triangle_atlas = loadT("res/sprite/entity/triangle_atlas.png");
    
    cutscene_image_1 = loadT("res/sprite/cutscene/blob_cutscene_1.png");
    cutscene_image_2 = loadT("res/sprite/cutscene/blob_cutscene_2.png");
    cutscene_image_3 = loadT("res/sprite/cutscene/blob_cutscene_3.png");
    
    blob_logo = loadT("res/sprite/menu/blob_logo.png");
    
    player_atlas = loadT("res/sprite/entity/player_atlas.png");
    tinted_player_atlas = main.fullyTintTexture(player_atlas, .white);
    
    blur_shader = loadS("res/shader/blur.fs");
    
    sword_texture = loadT("res/sprite/entity/sword.png");
    
    elevatia = loadF("res/font/elevatia.ttf");
    elevatia_italic = loadF("res/font/elevatia_italic.ttf");
    dancing_script = loadF("res/font/dancing_script.ttf");
    
    tile_atlas_texture = loadT("res/sprite/tileset.png");
    
    sign1 = loadT("res/sprite/ui/sign1.png");
    
    sword_item = loadT("res/sprite/ui/sword_item.png");
    
    shrine = loadT("res/sprite/sword_shrine.png");
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
    
    rl.unloadTexture(sign1);
    
    rl.unloadTexture(sword_item);
    
    rl.unloadTexture(shrine);
}