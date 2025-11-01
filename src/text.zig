const std = @import("std");
const rl = @import("raylib");
const main = @import("main.zig");
const crsh = @import("crash.zig");
const res = @import("resources.zig");

pub const FontName = enum {
    ELEVATIA,
    DANCING_SCRIPT
};

pub const FontType = enum {
    NORMAL,
    ITALIC
};

fn getFont(font_name: FontName, font_type: FontType) rl.Font {
    return switch (font_name) {
        .ELEVATIA => switch (font_type) {
            .NORMAL => res.elevatia,
            .ITALIC => res.elevatia_italic
        },
        .DANCING_SCRIPT => res.dancing_script
    };
}

fn getFontSpacing(font_name: FontName) f32 {
    return switch (font_name) {
        .ELEVATIA => 2,
        .DANCING_SCRIPT => 3
    };
}

fn nullTerminate(text: []const u8) [:0]const u8 {
    const text_z = main.allocator.dupeZ(u8, text) catch crsh.crash(.OUT_OF_MEMORY);
    return text_z;
}

pub fn drawCustomText(text: []const u8, font_name: FontName, font_type: FontType, font_size: f32, pos: rl.Vector2, color: rl.Color) void {
    const font = getFont(font_name, font_type);
    rl.drawTextEx(font, nullTerminate(text), pos, font_size, getFontSpacing(font_name), color);
}

pub fn measureCustomText(text: []const u8, font_name: FontName, font_type: FontType, font_size: f32) rl.Vector2 {
    const font = getFont(font_name, font_type);
    return rl.measureTextEx(font, nullTerminate(text), font_size, getFontSpacing(font_name));
}