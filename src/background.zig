const std = @import("std");
const rl = @import("raylib");
const main = @import("main.zig");
const scr = @import("screen.zig");
const ti = @import("timer.zig");
const sta = @import("stars.zig");

pub const BackgroundType = enum {
    BB1,
    BB2,
    BBU
};

pub const BB1Params = struct {
    top_color: rl.Color = .sky_blue,
    bottom_color: rl.Color = .blue,
    day_phase: usize = 0,
    sun_moon_timer: ti.Timer = .{ .auto_start = true, .duration = 100, .repeat = true },
    sun_moon_radius: f32 = 60,
    
    pub fn timerState(self: *BB1Params) f32 {
        return (@as(f32, @floatCast(rl.getTime())) - self.sun_moon_timer.start_time) / self.sun_moon_timer.duration;
    }
    
    pub fn globalState(self: *BB1Params) f32 {
        const global_state: f32 = switch (self.day_phase) {
            0,2 => self.timerState() / 2,
            1,3 => self.timerState() / 2 + 0.5,
            else => 0
        };
        return global_state;
    }
    
    pub fn calculateBackgroundColorFactor(self: *BB1Params) f32 {
        const factor: f32 = switch (self.day_phase) {
            1 => self.timerState(),
            2 => 1.0,
            3 => 1 - self.timerState(),
            else => 0.0
        };
        return factor;
    }
    
    pub fn calculateSunMoonPos(self: *BB1Params) rl.Vector2 {
        const x_pos = self.globalState() * (scr.sim_size.x + self.sun_moon_radius * 2) - self.sun_moon_radius;
        const y_pos = if(self.globalState() < 0.5) 200 - self.globalState() * 100 else 100 + self.globalState() * 100;
        return rl.Vector2{ .x = x_pos, .y = y_pos };
    }
    
    pub fn update(self: *BB1Params) void {
        self.sun_moon_timer.update();
        if(self.sun_moon_timer.called and self.day_phase >= 3) self.day_phase = 0 else if(self.sun_moon_timer.called) self.day_phase += 1;
        
        const day_top_color: rl.Color = .{ .r = 102, .g = 191, .b = 255, .a = 255 };
        const night_top_color: rl.Color = .{ .r = 0, .g = 42, .b = 135, .a = 255 };
        const day_bottom_color: rl.Color = .{ .r = 0, .g = 59, .b = 189, .a = 255 };
        const night_bottom_color: rl.Color = .{ .r = 0, .g = 29, .b = 94, .a = 255 };
        
        self.top_color = rl.colorLerp(day_top_color, night_top_color, self.calculateBackgroundColorFactor());
        self.bottom_color = rl.colorLerp(day_bottom_color, night_bottom_color, self.calculateBackgroundColorFactor());
    }
    
    pub fn draw(self: *BB1Params) void {
        self.drawSky();
        if(self.isDay() and (self.globalState() < 0.2 or self.globalState() > 0.8)) self.drawExtraSunLight();
        if(!self.isDay()) self.drawStars();
        self.drawSunMoon();
    }
    
    pub fn drawSky(self: *BB1Params) void {
        rl.drawRectangleGradientV(0, 0, scr.sim_size.x, scr.sim_size.y, self.top_color, self.bottom_color);
    }
    
    pub fn shouldDrawStar(self: *BB1Params, star: *sta.Star) bool {
        return (self.globalState() < 0.5 and self.globalState() >= star.delay_factor / 2) or (self.globalState() > 0.5 and self.globalState() <= 1 - star.delay_factor / 2);
    }
    
    pub fn drawStars(self: *BB1Params) void {
        for(&sta.stars) |*star| {
            if(!self.isDay() and self.shouldDrawStar(star)) rl.drawRectanglePro(.{ .x = star.pos.x, .y = star.pos.y, .width = 5, .height = 5 }, .{ .x = 0, .y = 0 }, star.rot, .white);
        }
    }
    
    pub fn drawSunMoon(self: *BB1Params) void {
        const sun_inner_color: rl.Color = .orange;
        const sun_outer_color: rl.Color = .yellow;
        const moon_inner_color: rl.Color = .white;
        const moon_outer_color: rl.Color = .light_gray;
        rl.drawCircleGradient(@intFromFloat(self.calculateSunMoonPos().x), @intFromFloat(self.calculateSunMoonPos().y), self.sun_moon_radius, if(self.isDay()) sun_inner_color else moon_inner_color, if(self.isDay()) sun_outer_color else moon_outer_color);
    }
    
    pub fn drawExtraSunLight(self: *BB1Params) void {
        const inner_color = if(self.globalState() < 0.5) rl.colorLerp(.blank, .orange, self.sunriseFactor()) else rl.colorLerp(.blank, .orange, self.sunsetFactor());
        rl.drawCircleGradient(@intFromFloat(self.calculateSunMoonPos().x), @intFromFloat(self.calculateSunMoonPos().y), self.sun_moon_radius * 3, inner_color, .blank);
    }
    
    pub fn isDay(self: *BB1Params) bool {
        return (self.day_phase != 2 and self.day_phase != 3);
    }
    
    pub fn sunriseFactor(self: *BB1Params) f32 {
        return if(self.isDay() and self.globalState() < 0.2) return 1 - self.globalState() * 5 else 0;
    }
    
    pub fn sunsetFactor(self: *BB1Params) f32 {
        return if(self.isDay() and self.globalState() > 0.8) return 1 - (1 - self.globalState()) * 5 else 0;
    }
};

var bb1 = BB1Params{};

pub fn updateBackground(bg_type: BackgroundType) void {
    switch (bg_type) {
        .BB1 => bb1.update(),
        else => {}
    }
}

pub fn drawBackground(bg_type: BackgroundType) void {
    switch (bg_type) {
        .BB1 => bb1.draw(),
        else => {}
    }
}

pub fn loadBackgrounds() void {
    bb1.sun_moon_timer.init();
}

pub fn unloadBackgrounds() void {
    
}