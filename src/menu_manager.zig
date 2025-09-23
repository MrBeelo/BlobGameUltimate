const std = @import("std");
const rl = @import("raylib");
const ch = @import("crash_handler.zig");
const pl = @import("player.zig");
const im = @import("input_manager.zig");
const mm = @import("map_manager.zig");
const cm = @import("camera_manager.zig");
const sm = @import("screen_manager.zig");
const ene = @import("enemy.zig");
const main = @import("main.zig");

pub const GameState = enum {
    PLAYING,
    MAIN
};

pub const ButtonType = union(enum) {
    change_game_state: GameState,
    exit: bool,
    reset_player: bool,
};

pub const Button = struct {
    pos: rl.Vector2,
    font_size: f32 = 32,
    button_type: ButtonType = .{ .exit = true },
    text: [:0]const u8 = "BUTTON NAME PLACEHOLDER",
    selected: bool = false,
    color: rl.Color = .black,
    
    pub fn click(self: *Button) void {
        switch (self.button_type) {
            .change_game_state => |game_state| main.game_state = game_state,
            .exit => main.should_exit = true,
            .reset_player => main.player.reset()
        }
    }
    
    pub fn getSize(self: *Button) rl.Vector2 {
        const button_width = @as(f32, @floatFromInt(rl.measureText(self.text, @intFromFloat(self.font_size)))) + sm.ui_buffer * 2; //change when you add custom fonts
        const button_height = self.font_size + sm.ui_buffer * 2;
        return rl.Vector2{ .x = button_width, .y = button_height };
    }
    
    pub fn getRect(self: *Button) rl.Rectangle {
        return rl.Rectangle{ .x = self.pos.x, .y = self.pos.y, .width = self.getSize().x, .height = self.getSize().y };
    }
    
    pub fn update(self: *Button) void {
        self.color = if(self.selected) .gold else .black;
    }
    
    pub fn draw(self: *Button) void {
        rl.drawRectangleLinesEx(self.getRect(), 3, self.color);
        rl.drawText(self.text, @intFromFloat(self.getRect().x + sm.ui_buffer), @intFromFloat(self.getRect().y + sm.ui_buffer), @intFromFloat(self.font_size), self.color);
    }
};

pub fn newCenteredButton(font_size: f32, button_type: ButtonType, text: [:0]const u8, y_pos: f32) Button {
    var button: Button = .{ .font_size = font_size, .text = text, .button_type = button_type };
    button.pos = .{ .x = sm.sim_size.x / 2 - button.getSize().x / 2, .y = y_pos };
    return button;
}

pub const Menu = struct {
    buttons: []Button,
    is_gameplay_menu: bool = false,
    selected_button_index: i32 = 0,
    top_text: [:0]const u8 = "TOP TEXT PLACEHOLDER",
    top_text_font_size: i32 = 64,
    top_text_color: rl.Color = .black,
    
    pub fn update(self: *Menu) void {
        if(!self.is_gameplay_menu) {
            if(im.getPressKey(.UP)) self.selected_button_index -= 1;
            if(im.getPressKey(.DOWN)) self.selected_button_index += 1;
            
            if(self.selected_button_index < 0) self.selected_button_index = @as(i32, @intCast(self.buttons.len)) - 1;
            if(self.selected_button_index > @as(i32, @intCast(self.buttons.len)) - 1) self.selected_button_index = 0;
            
            for(self.buttons, 0..) |*button, index| {
                button.selected = if(index == self.selected_button_index) true else false;
                button.update();
            }
            
            if(im.getPressKey(.CONFIRM)) {
                for(self.buttons, 0..) |*button, index| {
                    if(index == self.selected_button_index) {
                        button.click(); 
                        break;
                    }
                }
            }
        }
    }
    
    pub fn draw(self: *Menu) void {
        for(self.buttons) |*button| button.draw();
        //obviously replace when you add fonts
        rl.drawText(self.top_text, @as(i32, @intFromFloat(sm.sim_size.x / 2)) - rl.measureText(self.top_text, self.top_text_font_size), 50, self.top_text_font_size, self.top_text_color);
    }
};

var button_array = [_]Button{
    Button{ .button_type = .{ .change_game_state = .PLAYING }, .pos = .{ .x = sm.sim_size.x / 2, .y = 100 }, .text = "PLAY" },
    Button{ .button_type = .{ .exit = true}, .pos = .{ .x = sm.sim_size.x / 2, .y = 180 }, .text = "EXIT" },
};

var menus: [2]Menu = [_]Menu{
    // PLAYING
    Menu{ .buttons = &[_]Button{}, .is_gameplay_menu = true },
    
    // MAIN
    Menu{ 
        .buttons = button_array[0..], 
        .top_text = "MAIN MENU"
    }
};

pub fn updateMenus() void {
    menus[@intFromEnum(main.game_state)].update();
}

pub fn drawMenus() void {
    menus[@intFromEnum(main.game_state)].draw();
}