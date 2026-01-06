const std = @import("std");
const rl = @import("raylib");
const main = @import("main.zig");
const scr = @import("screen.zig");
const res = @import("resources.zig");
const txt = @import("text.zig");

const coin_size = rl.Vector2{ .x = 64, .y = 64 };

pub fn drawCoins() void {
    const src_rect = rl.Rectangle{ .x = 0, .y = 0, .width = 32, .height = 32 };
    const dest_rect = rl.Rectangle{.x = scr.sim_size.x - scr.ui_buffer - coin_size.x, .y = scr.ui_buffer * 4 + 96, .width = coin_size.x, .height = coin_size.y };
    rl.drawTexturePro(res.coin, src_rect, dest_rect, .{ .x = 0, .y = 0 }, 0, .white);
    
    const text: []const u8 = main.formatString("{d:.0}", .{main.savefile.coins});
    txt.drawCustomText(text, .ELEVATIA, .NORMAL, 64, .{ .x = scr.sim_size.x - scr.ui_buffer * 2 - coin_size.x - txt.measureCustomText(text, .ELEVATIA, .NORMAL, 64).x, .y = scr.ui_buffer * 4 + 96 }, .black);
}