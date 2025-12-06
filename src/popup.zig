const std = @import("std");
const rl = @import("raylib");
const scr = @import("screen.zig");
const txt = @import("text.zig");
const main = @import("main.zig");
const crsh = @import("crash.zig");
const ti = @import("timer.zig");

pub var milk_popup_timer = ti.Timer{ .duration = 2 };
var placement_modifier: f32 = 0;
const max_milk_popup_modifier: f32 = 310;

pub fn triggerMilkPopup() void {
    placement_modifier = 0;
    milk_popup_timer.activate();
}

pub fn updateMilkPopup() void {
    milk_popup_timer.update();
    const timer_state: f32 = if(milk_popup_timer.active) (@as(f32, @floatCast(rl.getTime())) - milk_popup_timer.start_time) / milk_popup_timer.duration else 0;
    placement_modifier = @sin(timer_state * std.math.pi) * max_milk_popup_modifier;
}

pub fn drawMilkPopup() void {
    const modifier = placement_modifier - max_milk_popup_modifier;
    
    const up_left_point: rl.Vector2 = .{ .x = 0 + modifier, .y = scr.ui_buffer + 100 };
    const up_right_point: rl.Vector2 = .{ .x = 300 + modifier, .y = scr.ui_buffer + 100 };
    const bottom_left_point: rl.Vector2 = .{ .x = 0 + modifier, .y = scr.ui_buffer + 100 + 75 };
    const bottom_right_point: rl.Vector2 = .{ .x = 300 * 15 / 16 + modifier, .y = scr.ui_buffer + 100 + 75 };
    const thickness: f32 = 8;
    
    rl.drawTriangle(up_left_point, bottom_left_point, up_right_point, .sky_blue);
    rl.drawTriangle(bottom_left_point, bottom_right_point, up_right_point, .sky_blue);
    
    rl.drawLineEx(up_left_point, .{ .x = up_right_point.x + 3, .y = up_right_point.y }, thickness, .black);
    rl.drawLineEx(bottom_left_point, .{ .x = bottom_right_point.x + 3, .y = bottom_right_point.y }, thickness, .black);
    rl.drawLineEx(up_right_point, bottom_right_point, thickness, .black);
    
    txt.drawCustomText(main.formatString("{d:.0}", .{main.savefile.milk}), .ELEVATIA, .ITALIC, 60, .{ .x = scr.ui_buffer * 2 + 200 + modifier, .y = scr.ui_buffer * 2 + 100 }, .black);
}