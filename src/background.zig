const std = @import("std");
const rl = @import("raylib");
const main = @import("main.zig");
const scr = @import("screen.zig");
const ti = @import("timer.zig");
const sta = @import("stars.zig");
const crsh = @import("crash.zig");
const txt = @import("text.zig");
const res = @import("resources.zig");

pub const BackgroundType = enum {
    MM,
    BB1,
    BB2,
    BBU1,
    BBU2,
    BBU3,
    BBUF
};


var mm_blob_strip_timer: ti.Timer = .{ .auto_start = true, .duration = 1, .repeat = true };

const MMBlobStrip = struct {
    index: usize = 0,
    y_offset: f32 = 0,
    
    pub fn update(self: *MMBlobStrip) void {
        const timer_state = (@as(f32, @floatCast(rl.getTime())) - mm_blob_strip_timer.start_time) / mm_blob_strip_timer.duration;
        const offsetted_timer_state = timer_state + @as(f32, @floatFromInt(self.index)) / 10;
        self.y_offset = @sin(offsetted_timer_state * std.math.pi);
    }
    
    pub fn draw(self: *MMBlobStrip) void {
        rl.drawTexturePro(res.mm_blob_strip, .{ .x = 0, .y = 0, .width = 64, .height = 1024 }, .{ .x = 128 * @as(f32, @floatFromInt(self.index)), .y = -self.y_offset * 32 - 64, .width = 128, .height = 2048 }, .{ .x = 0, .y = 0 }, 0, .{ .r = 50, .g = 50, .b = 50, .a = 255 });
    }
};

pub fn newStripArray(len: usize) [len]MMBlobStrip {
    const def_strip = MMBlobStrip{};
    var strip_array: [len]MMBlobStrip = [_]MMBlobStrip{def_strip} ** len;
    for(0..(len-1)) |index| strip_array[index].index = index;
    return strip_array;
}

pub var splash_text_index: i32 = 0;

pub const MMParams = struct {
    strips: [16]MMBlobStrip = newStripArray(16),
    pub fn update(self: *MMParams) void {
        for(&self.strips) |*strip| strip.update();
    }
    
    pub fn draw(self: *MMParams) void {
        for(&self.strips) |*strip| strip.draw();
        if(main.game_state == .MAIN) {
            rl.drawTexture(res.raylib_logo, @intFromFloat(scr.sim_size.x - @as(f32, @floatFromInt(res.raylib_logo.width)) - scr.ui_buffer), @intFromFloat(scr.sim_size.y - @as(f32, @floatFromInt(res.raylib_logo.height)) - scr.ui_buffer), .white);
            rl.drawTexture(res.zig_logo, @intFromFloat(scr.sim_size.x - @as(f32, @floatFromInt(res.raylib_logo.width)) - @as(f32, @floatFromInt(res.zig_logo.width)) - scr.ui_buffer * 2 ), @intFromFloat(scr.sim_size.y - @as(f32, @floatFromInt(res.raylib_logo.height)) - scr.ui_buffer), .white);
            
            const text = switch (splash_text_index) {
                0 => "Made with Hate by MrBeelo",
                1 => "Nick is too childish by MrBeelo",
                2 => "What even is JavaScript? (By MrBeelo)",
                3 => "I hate my life by MrBeelo",
                4 => "AAAAAAAAAAAAAAAAAAAAAAAAAAAA (By MrBeelo)",
                5 => "Sporg Gkek Fungoon Haha Funny by MrBeelo",
                6 => "WHERE'S MY MONDAY JOKE?!? (By MrBeelo)",
                7 => "<insert meme here> by MrBeelo",
                8 => "public static void main(string[] args) by MrBeelo",
                9 => "Did you know that Blob Game 1 sucks? (By MrBeelo)",
                10 => "DEN SOU KANO TON AGIO, AAAAAAAAA (By MrBeelo)",
                11 => "borb (By MrBeelo)",
                12 => "Hey Google! Good Afternoon! (By MrBeelo)",
                13 => "10/10 peak gameplay by MrBeelo",
                14 => "DM me \"blob game ultimate is the best game :)\" for a free iPhone by MrBeelo",
                15 => "I can't think of more jokes for here (By MrBeelo)",
                16 => "It doesn't look THAT bad... (By MrBeelo)",
                17 => "la vasta la vida loca loca loca loca by MrBeelo",
                18 => "      by MrBeelo",
                19 => "Did you know that Blob Game 2 ALSO sucks but less than BB1? (By MrBeelo)",
                else => "ERROR ERROR ERROR (By MrBeelo)"
            };
            txt.drawCustomText(text, .ELEVATIA, .ITALIC, 32, .{ .x = scr.ui_buffer, .y = scr.sim_size.y - scr.ui_buffer - 32 }, .white);
        }
    }
};

const sun_duration: f32 = 100;
const moon_duration: f32 = 15;

pub const BBU1Params = struct {
    top_color: rl.Color = .sky_blue,
    bottom_color: rl.Color = .blue,
    day_phase: usize = 1,
    sun_moon_timer: ti.Timer = .{ .auto_start = true, .duration = sun_duration, .repeat = true },
    sun_moon_radius: f32 = 60,
    
    pub fn timerState(self: *BBU1Params) f32 {
        return (@as(f32, @floatCast(rl.getTime())) - self.sun_moon_timer.start_time) / self.sun_moon_timer.duration;
    }
    
    pub fn globalState(self: *BBU1Params) f32 {
        const global_state: f32 = switch (self.day_phase) {
            0,2 => self.timerState() / 2,
            1,3 => self.timerState() / 2 + 0.5,
            else => 0
        };
        return global_state;
    }
    
    pub fn calculateBackgroundColorFactor(self: *BBU1Params) f32 {
        const factor: f32 = switch (self.day_phase) {
            1 => self.timerState(),
            2 => 1.0,
            3 => 1 - self.timerState(),
            else => 0.0
        };
        return factor;
    }
    
    pub fn calculateSunMoonPos(self: *BBU1Params) rl.Vector2 {
        const x_pos = self.globalState() * (scr.sim_size.x + self.sun_moon_radius * 2) - self.sun_moon_radius;
        const y_pos = if(self.globalState() < 0.5) 200 - self.globalState() * 100 else 100 + self.globalState() * 100;
        return rl.Vector2{ .x = x_pos, .y = y_pos };
    }
    
    pub fn update(self: *BBU1Params) void {
        self.sun_moon_timer.update();
        if(self.sun_moon_timer.called and self.day_phase >= 3) {
            self.day_phase = 0; 
            self.sun_moon_timer.duration = sun_duration;
        } else if(self.sun_moon_timer.called) {
            self.sun_moon_timer.duration = if(self.day_phase + 1 == 2 or self.day_phase + 1 == 3) moon_duration else sun_duration;
            self.day_phase += 1;
        }
        
        const day_top_color: rl.Color = .{ .r = 102, .g = 191, .b = 255, .a = 255 };
        const night_top_color: rl.Color = .{ .r = 0, .g = 42, .b = 135, .a = 255 };
        const day_bottom_color: rl.Color = .{ .r = 0, .g = 59, .b = 189, .a = 255 };
        const night_bottom_color: rl.Color = .{ .r = 0, .g = 29, .b = 94, .a = 255 };
        
        self.top_color = rl.colorLerp(day_top_color, night_top_color, self.calculateBackgroundColorFactor());
        self.bottom_color = rl.colorLerp(day_bottom_color, night_bottom_color, self.calculateBackgroundColorFactor());
    }
    
    pub fn draw(self: *BBU1Params) void {
        self.drawSky();
        if(self.isDay() and (self.globalState() < 0.2 or self.globalState() > 0.8)) self.drawExtraSunLight();
        if(!self.isDay()) self.drawStars();
        self.drawSunMoon();
    }
    
    pub fn drawSky(self: *BBU1Params) void {
        rl.drawRectangleGradientV(0, 0, scr.sim_size.x, scr.sim_size.y, self.top_color, self.bottom_color);
    }
    
    pub fn shouldDrawStar(self: *BBU1Params, star: *sta.Star) bool {
        return (self.globalState() < 0.5 and self.globalState() >= star.delay_factor / 2) or (self.globalState() > 0.5 and self.globalState() <= 1 - star.delay_factor / 2);
    }
    
    pub fn drawStars(self: *BBU1Params) void {
        for(&sta.stars) |*star| {
            if(!self.isDay() and self.shouldDrawStar(star)) rl.drawRectanglePro(.{ .x = star.pos.x, .y = star.pos.y, .width = 5, .height = 5 }, .{ .x = 0, .y = 0 }, star.rot, .white);
        }
    }
    
    pub fn drawSunMoon(self: *BBU1Params) void {
        const sun_inner_color: rl.Color = .{ .r = 255, .g = 190, .b = 0, .a = 255 };
        const sun_outer_color: rl.Color = .yellow;
        const moon_inner_color: rl.Color = .white;
        const moon_outer_color: rl.Color = .light_gray;
        rl.drawCircleGradient(self.calculateSunMoonPos(), self.sun_moon_radius, if(self.isDay()) sun_inner_color else moon_inner_color, if(self.isDay()) sun_outer_color else moon_outer_color);
    }
    
    pub fn drawExtraSunLight(self: *BBU1Params) void {
        const inner_color = if(self.globalState() < 0.5) rl.colorLerp(.blank, .orange, self.sunriseFactor()) else rl.colorLerp(.blank, .orange, self.sunsetFactor());
        rl.drawCircleGradient(self.calculateSunMoonPos(), self.sun_moon_radius * 3, inner_color, .blank);
    }
    
    pub fn isDay(self: *BBU1Params) bool {
        return (self.day_phase != 2 and self.day_phase != 3);
    }
    
    pub fn sunriseFactor(self: *BBU1Params) f32 {
        return if(self.isDay() and self.globalState() < 0.2) return 1 - self.globalState() * 5 else 0;
    }
    
    pub fn sunsetFactor(self: *BBU1Params) f32 {
        return if(self.isDay() and self.globalState() > 0.8) return 1 - (1 - self.globalState()) * 5 else 0;
    }
};

var mm = MMParams{};
pub var bbu1 = BBU1Params{};

pub fn updateBackground(bg_type: BackgroundType) void {
    switch (bg_type) {
        .MM => mm.update(),
        .BBU1 => bbu1.update(),
        else => {}
    }
}

pub fn drawBackground(bg_type: BackgroundType) void {
    switch (bg_type) {
        .MM => mm.draw(),
        .BBU1 => bbu1.draw(),
        else => {}
    }
}

pub fn getBackgroundType() BackgroundType {
    if(main.game_state != .PLAYING and main.game_state != .MAP_TRANSITION and main.game_state != .PAUSED) {
        return .MM;
    } else switch (main.savefile.current_map) {
        0...10 => return .BBU1,
        11...20 => return .BBU2,
        21...30 => return .BBU3,
        31,32,35,36,39,40 => return .BB1,
        33,34,37,38 => return .BB2,
        41...50 => return .BBUF,
        else => return .MM
    }
}

pub fn initBackgrounds() void {
    splash_text_index = rl.getRandomValue(0, 19);
    bbu1.sun_moon_timer.init();
}