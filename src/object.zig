const std = @import("std");
const rl = @import("raylib");
const main = @import("main.zig");
const dia = @import("dialog.zig");

pub const ObjectType = enum {
    SOLID,
    HAZARD,
    ADVANCE_MAP,
    MILK,
    DIALOG
};

pub const Object = struct {
    rect: rl.Rectangle,
    obj_type: ObjectType,
    is_disabled: bool = false,
    dialog: ?dia.Dialog = null,
    
    pub fn updateDialog(self: *Object) void {
        if(self.obj_type == .DIALOG and self.dialog != null) self.dialog.?.update();
    }
    
    pub fn drawDialog(self: *Object) void {
        if(self.obj_type == .DIALOG and self.dialog != null) self.dialog.?.draw();
    }
    
    pub fn drawDebug(self: *Object) void {
        const color: rl.Color = switch (self.obj_type) {
            .SOLID => .orange,
            .HAZARD => .red,
            .ADVANCE_MAP => .green,
            .MILK => .blue,
            .DIALOG => .yellow
        };
        
        if(!self.is_disabled) rl.drawRectangleLinesEx(self.rect, 3, color);
    }
};