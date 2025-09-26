const std = @import("std");
const rl = @import("raylib");
const main = @import("main.zig");
const crsh = @import("crash.zig");

var elevatia: rl.Font = undefined;
var elevatia_italic: rl.Font = undefined;

pub const FontName = enum {
    ELEVATIA
};

pub const FontType = enum {
    NORMAL,
    ITALIC
};

fn getFont(font_name: FontName, font_type: FontType) rl.Font {
    return switch (font_name) {
        .ELEVATIA => switch (font_type) {
            .NORMAL => elevatia,
            .ITALIC => elevatia_italic
        }
    };
}

pub fn loadFonts() void {
    elevatia = rl.loadFontEx("res/font/elevatia.ttf", 100, null) catch crsh.crash(.RAYLIB_ERROR);
    elevatia_italic = rl.loadFontEx("res/font/elevatia_italic.ttf", 100, null) catch crsh.crash(.RAYLIB_ERROR);
}

pub fn unloadFonts() void {
    rl.unloadFont(elevatia);
    rl.unloadFont(elevatia_italic);
}

pub fn drawCustomText(text: [:0]const u8, font_name: FontName, font_type: FontType, font_size: f32, pos: rl.Vector2, color: rl.Color) void {
    const font = getFont(font_name, font_type);
    rl.drawTextEx(font, text, pos, font_size, 0, color);
}

pub fn measureCustomText(text: [:0]const u8, font_name: FontName, font_type: FontType, font_size: f32) rl.Vector2 {
    const font = getFont(font_name, font_type);
    return rl.measureTextEx(font, text, font_size, 0);
}