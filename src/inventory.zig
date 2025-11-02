const std = @import("std");
const rl = @import("raylib");
const main = @import("main.zig");
const scr = @import("screen.zig");
const res = @import("resources.zig");

pub fn drawInventory() void {
    const slot_amount: usize = 2;
    const slot_size: f32 = 96;
    const slot_gap: f32 = scr.ui_buffer;
    
    const bg_pos: rl.Vector2 = .{ .x = scr.sim_size.x - slot_size * @as(f32, @floatFromInt(slot_amount)) - slot_gap * (@as(f32, @floatFromInt(slot_amount)) + 1), .y = 0 };
    const bg_rect: rl.Rectangle = .{ .x = bg_pos.x, .y = bg_pos.y, .width = scr.sim_size.x - bg_pos.x, .height = slot_size + slot_gap * 2 };
    rl.drawRectangleRec(bg_rect, .green);
    
    const border_buffer: f32 = 3;
    rl.drawLineEx(.{ .x = bg_rect.x - border_buffer, .y = bg_rect.y }, .{ .x = bg_rect.x - border_buffer, .y = bg_rect.y + bg_rect.height + border_buffer + 4 }, 7, .black);
    rl.drawLineEx(.{ .x = bg_rect.x - border_buffer, .y = bg_rect.y + bg_rect.height + border_buffer }, .{ .x = scr.sim_size.x, .y = bg_rect.y + bg_rect.height + border_buffer }, 7, .black);
    
    for(0..(slot_amount + 1)) |i| {
        const index: f32 = @floatFromInt(i);
        const slot_pos: rl.Vector2 = .{ .x = scr.sim_size.x - slot_size * index - slot_gap * index, .y = slot_gap };
        const slot_rect: rl.Rectangle = .{ .x = slot_pos.x, .y = slot_pos.y, .width = slot_size, .height = slot_size };
        rl.drawRectangleRec(slot_rect, .white);
        rl.drawRectangleLinesEx(slot_rect, 5, .black);
        
        if(i == 2 and main.savefile.has_sword) rl.drawTexturePro(res.sword_item, .{ .x = 0, .y = 0, .width = slot_size, .height = slot_size }, slot_rect, .{ .x = 0, .y = 0 }, 0, .white);
    }
}