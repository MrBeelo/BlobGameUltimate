const std = @import("std");
const rl = @import("raylib");
const main = @import("main.zig");

pub const ObjectType = enum {
    SOLID,
    HAZARD,
    ADVANCE_MAP,
    MILK
};

pub const Object = struct {
    rect: rl.Rectangle,
    obj_type: ObjectType,
    is_disabled: bool = false,
    
    pub fn drawDebug(self: *Object) void {
        const color: rl.Color = switch (self.obj_type) {
            .SOLID => .orange,
            .HAZARD => .red,
            .ADVANCE_MAP => .green,
            .MILK => .blue
        };
        
        if(!self.is_disabled) rl.drawRectangleLinesEx(self.rect, 5, color);
    }
};