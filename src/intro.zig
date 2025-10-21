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

pub fn drawIntro() void {
    const timer_state = (@as(f32, @floatCast(rl.getTime())) - cutscene_timer.start_time) / cutscene_timer.duration;
    const text_color_alpha: u8 = switch (@as(i32, @intFromFloat(timer_state * 100))) {
        0...9 => @intFromFloat((timer_state - 0) * 10 * 255),
        40...49 => @intFromFloat(255 - (timer_state - 0.4) * 10 * 255),
        50...59 => @intFromFloat((timer_state - 0.5) * 10 * 255),
        90...99 => @intFromFloat(255 - (timer_state - 0.9) * 10 * 255),
        else => 255
    };
    const text_color = rl.Color{ .r = 0, .g = 0, .b = 0, .a = text_color_alpha};
    const image_color_rgb: u8 = switch (@as(i32, @intFromFloat(timer_state * 100))) {
        0...9 => @intFromFloat((timer_state - 0) * 10 * 255),
        90...99 => @intFromFloat(255 - (timer_state - 0.9) * 10 * 255),
        else => 255
    };
    const image_color = rl.Color{ .r = image_color_rgb, .g = image_color_rgb, .b = image_color_rgb, .a = 255};
    switch (current_phase) {
        1 => {
            rl.drawTexture(cutscene_image_1, 0, 0, image_color);
            if(timer_state <= 0.5) {
                txt.drawCustomText("We find ourselves in a place", .DANCING_SCRIPT, .ITALIC, 70, .{ .x = 200 + timer_state * 30, .y = 400 }, text_color);
            } else {
                txt.drawCustomText("where the world is governed by shapes", .DANCING_SCRIPT, .ITALIC, 70, .{ .x = 500 + timer_state * 30, .y = 700 }, text_color);
            }
        },
        2 => {
            rl.drawTexture(cutscene_image_2, 0, 0, image_color);
            if(timer_state <= 0.5) {
                txt.drawCustomText("but a little cube with legs stands out...", .DANCING_SCRIPT, .ITALIC, 70, .{ .x = 800 - timer_state * 30, .y = 400 }, text_color);
            } else {
                txt.drawCustomText("For it is to seek the legendary sword of death...", .DANCING_SCRIPT, .ITALIC, 70, .{ .x = 500 - timer_state * 30, .y = 700 }, text_color);
            }
        },
        3 => {
            rl.drawTexture(cutscene_image_3, 0, 0, image_color);
            if(timer_state <= 0.5) {
                txt.drawCustomText("And destroy every living thing there is...", .DANCING_SCRIPT, .ITALIC, 70, .{ .x = 400 + timer_state * 30, .y = 400 }, text_color);
            } else {
                txt.drawCustomText("And so, the blob goes forth", .DANCING_SCRIPT, .ITALIC, 120, .{ .x = 400, .y = 450 }, text_color);
            }
        },
        else => {}
    }
}