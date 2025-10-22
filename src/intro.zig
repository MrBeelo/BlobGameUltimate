const std = @import("std");
const rl = @import("raylib");
const main = @import("main.zig");
const txt = @import("text.zig");
const crsh = @import("crash.zig");
const ti = @import("timer.zig");
const men = @import("menu.zig");
const sav = @import("savefile.zig");

var cutscene_timer: ti.Timer = ti.Timer{ .duration = 5 };
var current_phase: i32 = 0;
var cutscene_image_1: rl.Texture2D = undefined;
var cutscene_image_2: rl.Texture2D = undefined;
var cutscene_image_3: rl.Texture2D = undefined;


pub fn playIntro() void {
    current_phase = 1;
    cutscene_timer.activate();
}

pub fn loadIntro() void {
    cutscene_image_1 = rl.loadTexture("res/sprite/cutscene/blob_cutscene_1.png") catch crsh.crash(.RAYLIB_ERROR);
    cutscene_image_2 = rl.loadTexture("res/sprite/cutscene/blob_cutscene_2.png") catch crsh.crash(.RAYLIB_ERROR);
    cutscene_image_3 = rl.loadTexture("res/sprite/cutscene/blob_cutscene_3.png") catch crsh.crash(.RAYLIB_ERROR);
}

pub fn unloadIntro() void {
    rl.unloadTexture(cutscene_image_1);
    rl.unloadTexture(cutscene_image_2);
    rl.unloadTexture(cutscene_image_3);
}

pub fn updateIntro() void {
    cutscene_timer.update();
    if(cutscene_timer.called) {
        if(current_phase == 3) {
            main.savefile.played_intro = true;
            sav.saveSaveFile(&main.savefile) catch crsh.crash(.SAVE_ERROR);
            men.changeGameState(.PLAYING);
        } else {
            current_phase += 1;
            cutscene_timer.activate();
        }
    }
}

pub fn drawIntroImage(timer_state: f32, texture: rl.Texture2D, pos: rl.Vector2, scale: f32) void {
    drawIntroImageRec(timer_state, texture, .{ .x = pos.x, .y = pos.y, .width = 1920 * scale, .height = 1080 * scale });
}

pub fn drawIntroImageRec(timer_state: f32, texture: rl.Texture2D, rect: rl.Rectangle) void {
    const image_color_rgb: u8 = switch (@as(i32, @intFromFloat(timer_state * 100))) {
        0...9 => @intFromFloat((timer_state - 0) * 10 * 255),
        90...99 => @intFromFloat(255 - (timer_state - 0.9) * 10 * 255),
        else => 255
    };
    const image_color = rl.Color{ .r = image_color_rgb, .g = image_color_rgb, .b = image_color_rgb, .a = 255};
    rl.drawTexturePro(texture, .{ .x = 0, .y = 0, .width = 1920, .height = 1080 }, rect, .{ .x = 0, .y = 0 }, 0, image_color);
}

pub fn drawIntroText(timer_state: f32, text1: [:0]const u8, pos1: rl.Vector2, text2: [:0]const u8, pos2: rl.Vector2) void {
    const def_font_size: f32 = 70;
    drawIntroTextWithFontSize(timer_state, text1, pos1, def_font_size, text2, pos2, def_font_size);
}

pub fn drawIntroTextWithFontSize(timer_state: f32, text1: [:0]const u8, pos1: rl.Vector2, fs1: f32, text2: [:0]const u8, pos2: rl.Vector2, fs2: f32) void {
    const text_color_alpha: u8 = switch (@as(i32, @intFromFloat(timer_state * 100))) {
        0...9 => @intFromFloat((timer_state - 0) * 10 * 255),
        40...49 => @intFromFloat(255 - (timer_state - 0.4) * 10 * 255),
        50...59 => @intFromFloat((timer_state - 0.5) * 10 * 255),
        90...99 => @intFromFloat(255 - (timer_state - 0.9) * 10 * 255),
        else => 255
    };
    const text_color = rl.Color{ .r = 0, .g = 0, .b = 0, .a = text_color_alpha};
    
    if(timer_state <= 0.5) {
        txt.drawCustomText(text1, .DANCING_SCRIPT, .ITALIC, fs1, pos1, text_color);
    } else {
        txt.drawCustomText(text2, .DANCING_SCRIPT, .ITALIC, fs2, pos2, text_color);
    }
}

pub fn drawIntro() void {
    const timer_state = (@as(f32, @floatCast(rl.getTime())) - cutscene_timer.start_time) / cutscene_timer.duration;
    switch (current_phase) {
        1 => {
            drawIntroImage(timer_state, cutscene_image_1, .{ .x = 0 - timer_state * 100, .y = 0 }, 1.3);
            drawIntroText(timer_state, "We find ourselves in a place", .{ .x = 200 + timer_state * 30, .y = 400 }, "where the world is governed by shapes", .{ .x = 500 + timer_state * 30, .y = 700 });
        },
        2 => {
            drawIntroImage(timer_state, cutscene_image_2, .{ .x = -100 + timer_state * 100, .y = 0 }, 1.3);
            drawIntroText(timer_state, "but a little cube with legs stands out...", .{ .x = 800 - timer_state * 30, .y = 400 }, "For it is to seek the legendary sword of death...", .{ .x = 500 - timer_state * 30, .y = 700 });
        },
        3 => {
            const diff: f32 = timer_state * 100;
            drawIntroImageRec(timer_state, cutscene_image_3, .{ .x = 0 - diff, .y = 0 - diff, .width = 1920 + diff * 2, .height = 1080 + diff * 2 });
            drawIntroTextWithFontSize(timer_state, "And destroy every living thing there is...", .{ .x = 400 + timer_state * 30, .y = 400 }, 70, "And so, the blob goes forth", .{ .x = 400, .y = 450 }, 120);
        },
        else => {}
    }
}