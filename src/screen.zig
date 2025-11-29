const std = @import("std");
const rl = @import("raylib");
const main = @import("main.zig");
const crsh = @import("crash.zig");
const men = @import("menu.zig");
const sha = @import("shake.zig");
const res = @import("resources.zig");

pub const sim_size: rl.Vector2 = .{ .x = 1920, .y = 1080 };
pub var window_size: rl.Vector2 = .{ .x = 1920, .y = 1080 };
pub var game_target: rl.RenderTexture2D = undefined;
pub var menu_target: rl.RenderTexture2D = undefined;
var target_scale: f32 = undefined;
pub const ui_buffer: f32 = 10;

pub fn initTarget() void {
    game_target = rl.loadRenderTexture(sim_size.x, sim_size.y) catch crsh.crash(.RAYLIB_ERROR);
    rl.setTextureFilter(game_target.texture, .bilinear);
    
    menu_target = rl.loadRenderTexture(sim_size.x, sim_size.y) catch crsh.crash(.RAYLIB_ERROR);
    rl.setTextureFilter(menu_target.texture, .bilinear);
}

pub fn updateTargetScale() void {
    window_size = .{ .x = @floatFromInt(rl.getScreenWidth()), .y = @floatFromInt(rl.getScreenHeight()) };
    target_scale = @min(window_size.x / sim_size.x, window_size.y / sim_size.y);
}

pub fn drawTarget() void {
    const game_target_src = rl.Rectangle{ .x = 0, .y = 0, .width = @floatFromInt(game_target.texture.width), .height = @floatFromInt(-game_target.texture.height) };
    const menu_target_src = rl.Rectangle{ .x = 0, .y = 0, .width = @floatFromInt(menu_target.texture.width), .height = @floatFromInt(-menu_target.texture.height) };
    const target_dest = rl.Rectangle{ .x = (window_size.x - sim_size.x * target_scale) * 0.5 + sha.screenShakeModifier().x, .y = (window_size.y - sim_size.y * target_scale) * 0.5 + sha.screenShakeModifier().y, .width = sim_size.x * target_scale, .height = sim_size.y * target_scale };
    const color = if(main.game_state == .MAP_TRANSITION) men.map_transition_color else rl.Color.white;
    
    if(main.game_state == .PAUSED) rl.beginShaderMode(res.blur_shader);
    rl.drawTexturePro(game_target.texture, game_target_src, target_dest, .zero(), 0, color);
    if(main.game_state == .PAUSED) rl.endShaderMode();
    rl.drawTexturePro(menu_target.texture, menu_target_src, target_dest, .zero(), 0, color);
}