const std = @import("std");
const rl = @import("raylib");
const main = @import("main.zig");
const bg = @import("background.zig");
const scr = @import("screen.zig");
const map = @import("map.zig");

pub fn handleGlobalLights() void {
    var dimmed_color: rl.Color = .blank;
    const night_color = rl.colorAlpha(.black, 0.3);
    if(!bg.bbu1.isDay()) {
        dimmed_color = night_color;
    } else if (bg.bbu1.isDay()) {
        if(bg.bbu1.globalState() < 0.2) dimmed_color = rl.colorLerp(.blank, night_color, bg.bbu1.sunriseFactor());
        if(bg.bbu1.globalState() > 0.8) dimmed_color = rl.colorLerp(.blank, night_color, bg.bbu1.sunsetFactor());
    }
    rl.drawRectangle(0, 0, scr.sim_size.x, scr.sim_size.y, dimmed_color);
    rl.beginBlendMode(.additive);
    rl.drawCircleGradient(bg.bbu1.calculateSunMoonPos(), 700, if(bg.bbu1.isDay()) .white else rl.colorAlpha(.white, 0.4), .blank);
    rl.endBlendMode();
}

pub fn handleRelativeLights() void {
    rl.beginBlendMode(.additive);
    for(map.maps[main.savefile.current_map].lights) |*light| light.draw();
    rl.endBlendMode();
}

pub const Light = struct {
    pos: rl.Vector2,
    intensity: f32,
    radius: f32,
    color: rl.Color,
    
    pub fn draw(self: *Light) void {
        rl.drawCircleGradient(self.pos, self.radius, rl.colorAlpha(self.color, self.intensity), .blank);
    }
};