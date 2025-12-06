const std = @import("std");
const rl = @import("raylib");
const main = @import("main.zig");
const ti = @import("timer.zig");
const scr = @import("screen.zig");
const txt = @import("text.zig");
const crsh = @import("crash.zig");
const res = @import("resources.zig");

const DialogPart = struct {
    line1: []const u8 = "PLACEHOLDER",
    line2: ?[]const u8 = null,
    combined: ?[]const u8 = null,
    time: f32,
    line1_active: bool = true
};

pub const DialogType = enum {
    BLANK,
    SIGN1
};

pub const Dialog = struct {
    part: DialogPart,
    timer: ti.Timer,
    dialog_type: DialogType = .BLANK,
    current_drawn_characters: usize = 0,
    
    pub fn update(self: *Dialog) void {
        const lines: []const u8 = if(self.part.line1_active) self.part.line1 else if(self.part.line2 != null) (self.part.combined orelse unreachable) else "";
        
        if(!self.timer.active) {
            self.timer.init();
            self.current_drawn_characters = 0;
        }
        
        self.timer.update();
        if(self.timer.called) {
            if(self.current_drawn_characters < lines.len) {
                self.current_drawn_characters += 1;
            } else if(self.part.line1_active and self.part.line2 != null) {
                self.part.line1_active = false;
            }
        }
    }
    
    pub fn draw(self: *Dialog) void {
        const part: DialogPart = self.part;
        const rect = rl.Rectangle{ .x = scr.sim_size.x / 4, .y = 100, .width = scr.sim_size.x / 2, .height = 300 };
        
        switch (self.dialog_type) {
            .BLANK => {
                rl.drawRectangleRec(rect, .white);
                rl.drawRectangleLinesEx(rect, 5, .black);
            },
            .SIGN1 => {
                rl.drawTexture(res.sign1, @intFromFloat(scr.sim_size.x / 4), 100, .white);
            }
        }
        
        const big_font_size: f32 = 48;
        const small_font_size: f32 = 36;
        const character_threshold: usize = 25;
        
        if(part.line1_active) {
            const line: []const u8 = part.line1;
            const sliced_line: []const u8 = if(self.current_drawn_characters <= line.len) line[0..self.current_drawn_characters] else "ERROR LINE 1";
            const line_xpos: f32 = getTextMiddleXPos(sliced_line, if(line.len < character_threshold) big_font_size else small_font_size);
            const line_ypos: f32 = 170;
            
            txt.drawCustomText(sliced_line, .ELEVATIA, .NORMAL, if(line.len < character_threshold) big_font_size else small_font_size, .{ .x = line_xpos, .y = line_ypos }, .black);
        } else if(part.line2 != null) {
            const line1: []const u8 = part.line1;
            const line2: []const u8 = part.line2 orelse unreachable;
            const line2_drawn_characters: usize = self.current_drawn_characters - line1.len;
            const sliced_line2: []const u8 = if(line2_drawn_characters <= line2.len) line2[0..line2_drawn_characters] else "ERROR LINE 2";
            const line1_xpos: f32 = getTextMiddleXPos(line1, if(line1.len < character_threshold) big_font_size else small_font_size);
            const line1_ypos: f32 = 170;
            const line2_xpos: f32 = getTextMiddleXPos(sliced_line2, if(line2.len < character_threshold) big_font_size else small_font_size);
            const line2_ypos: f32 = 260;
            
            txt.drawCustomText(line1, .ELEVATIA, .NORMAL, if(line1.len < character_threshold) big_font_size else small_font_size, .{ .x = line1_xpos, .y = line1_ypos }, .black);
            txt.drawCustomText(sliced_line2, .ELEVATIA, .NORMAL, if(line2.len < character_threshold) big_font_size else small_font_size, .{ .x = line2_xpos, .y = line2_ypos }, .black);
        }
    }
};

fn getPartTextLength(line1: []const u8, line2: ?[]const u8, combined: ?[]const u8) i32 {
    if(line2 == null) {
        return @intCast(line1.len);
    } else {
        const lines = combined orelse unreachable;
        return @intCast(lines.len);
    }
}

fn getTextMiddleXPos(line: []const u8, font_size: f32) f32 {
    return scr.sim_size.x / 2 - txt.measureCustomText(line, .ELEVATIA, .NORMAL, font_size).x / 2;
}

fn calculateTimerDuration(text_length: i32) f32 {
    const length: f32 = @floatFromInt(text_length);
    return 1 / (length / 1.7);
}

pub fn singleLineDialog(line: []const u8, dialog_type: DialogType) Dialog {
    const part = DialogPart{ .line1 = line, .time = calculateTimerDuration(getPartTextLength(line, null, null)) };
    return Dialog{ .part = part, .timer = .{ .duration = part.time, .auto_start = true, .repeat = true }, .dialog_type = dialog_type };
}

pub fn doubleLineDialog(line1: []const u8, line2: []const u8, dialog_type: DialogType) Dialog {
    const combined: []const u8 = std.mem.concat(main.allocator, u8, &[_][]const u8{
        line1,
        line2,
    }) catch crsh.crash(.OUT_OF_MEMORY);
    defer main.allocator.free(combined);
    const part = DialogPart{ .line1 = line1, .line2 = line2, .combined = combined, .time = calculateTimerDuration(getPartTextLength(line1, line2, combined)) };
    return Dialog{ .part = part, .timer = .{ .duration = part.time, .auto_start = true, .repeat = true }, .dialog_type = dialog_type };
}