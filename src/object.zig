const std = @import("std");
const rl = @import("raylib");
const main = @import("main.zig");
const dia = @import("dialog.zig");
const res = @import("resources.zig");

pub const ObjectType = enum {
    SOLID,
    HAZARD,
    ADVANCE_MAP,
    MILK,
    DIALOG,
    SHRINE
};

pub const Object = struct {
    rect: rl.Rectangle,
    obj_type: ObjectType,
    is_disabled: bool = false,
    dialog: ?dia.Dialog = null,
    shrine_has_stone: ?bool = null,
    
    pub fn updateDialog(self: *Object) void {
        if(self.obj_type == .DIALOG and self.dialog != null) self.dialog.?.update();
    }
    
    pub fn drawDialog(self: *Object) void {
        if(self.obj_type == .DIALOG and self.dialog != null) self.dialog.?.draw();
    }
    
    pub fn drawShrine(self: *Object) void {
        if(self.obj_type == .SHRINE and self.shrine_has_stone != null) {
            const src = rl.Rectangle{ .x = if(self.shrine_has_stone orelse unreachable) 0 else 128, .y = 0, .width = 128, .height = 128 };
            const dest = rl.Rectangle{ .x = self.rect.x, .y = self.rect.y - self.rect.height, .width = self.rect.width, .height = self.rect.height * 2 };
            rl.drawTexturePro(res.shrine, src, dest, .{ .x = 0, .y = 0 }, 0, .white);
        }
    }
    
    pub fn drawDebug(self: *Object) void {
        const color: rl.Color = switch (self.obj_type) {
            .SOLID => .orange,
            .HAZARD => .red,
            .ADVANCE_MAP => .green,
            .MILK => .blue,
            .DIALOG => .yellow,
            .SHRINE => .purple
        };
        
        if(!self.is_disabled) rl.drawRectangleLinesEx(self.rect, 3, color);
    }
};