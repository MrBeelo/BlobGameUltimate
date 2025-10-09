const std = @import("std");
const rl = @import("raylib");
const main = @import("main.zig");
const scr = @import("screen.zig");
const ti = @import("timer.zig");

pub const BackgroundType = enum {
    BB1,
    BB2,
    BBU
};

var bb1_top_color: rl.Color = .sky_blue;
var bb1_bottom_color: rl.Color = .blue;
var bb1_day_phase: usize = 0;
var bb1_sun_moon_timer: ti.Timer = .{ .auto_start = true, .duration = 30, .repeat = true };
const day_top_color = rl.Color{ .r = 102, .g = 191, .b = 255, .a = 255 };
const night_top_color = rl.Color{ .r = 0, .g = 42, .b = 135, .a = 255 };
const day_bottom_color = rl.Color{ .r = 0, .g = 59, .b = 189, .a = 255 };
const night_bottom_color = rl.Color{ .r = 0, .g = 29, .b = 94, .a = 255 };


pub fn updateBackground(bg_type: BackgroundType) void {
    switch (bg_type) {
        .BB1 => {
            bb1_sun_moon_timer.update();
            if(bb1_sun_moon_timer.called and bb1_day_phase >= 3) bb1_day_phase = 0 else if(bb1_sun_moon_timer.called) bb1_day_phase += 1;
            
            bb1_top_color = rl.colorLerp(day_top_color, night_top_color, calculateBB1BackgroundColorFactor());
            bb1_bottom_color = rl.colorLerp(day_bottom_color, night_bottom_color, calculateBB1BackgroundColorFactor());
        },
        else => {}
    }
}

pub fn drawBackground(bg_type: BackgroundType) void {
    switch (bg_type) {
        .BB1 => {
            rl.drawRectangleGradientV(0, 0, scr.sim_size.x, scr.sim_size.y, bb1_top_color, bb1_bottom_color);
        },
        else => {}
    }
}

pub fn loadBackgrounds() void {
    bb1_sun_moon_timer.init();
}

pub fn unloadBackgrounds() void {
    
}

pub fn calculateBB1BackgroundColorFactor() f32 {
    const timer_state: f32 = (@as(f32, @floatCast(rl.getTime())) - bb1_sun_moon_timer.start_time) / bb1_sun_moon_timer.duration;
    const factor: f32 = switch (bb1_day_phase) {
        1 => timer_state,
        2 => 1.0,
        3 => 1 - timer_state,
        else => 0.0
    };
    return factor;
}