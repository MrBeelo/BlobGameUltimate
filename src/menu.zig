const std = @import("std");
const rl = @import("raylib");
const crsh = @import("crash.zig");
const inp = @import("input.zig");
const scr = @import("screen.zig");
const main = @import("main.zig");
const txt = @import("text.zig");
const map = @import("map.zig");
const ti = @import("timer.zig");

pub const GameState = enum {
    PLAYING,
    MAP_TRANSITION,
    MAIN,
    PAUSED,
    EXIT
};

pub var map_transition_timer = ti.Timer{ .duration = 1 };
pub var map_transition_map_changed = false;
pub var map_transition_color: rl.Color = .white;

pub const ButtonType = union(enum) {
    change_game_state: GameState,
    exit: bool,
    reset_player: bool,
};

pub fn changeGameState(game_state: GameState) void {
    main.game_state = game_state;
    menus[@intFromEnum(game_state)].selected_button_index = 0;
}

pub const Button = struct {
    index: usize,
    font_size: f32 = 32,
    button_type: ButtonType = .{ .exit = true },
    text: [:0]const u8 = "BUTTON NAME PLACEHOLDER",
    selected: bool = false,
    color: rl.Color = .black,
    
    pub fn click(self: *Button) void {
        switch (self.button_type) {
            .change_game_state => |game_state| changeGameState(game_state),
            .exit => main.should_exit = true,
            .reset_player => {
                map.maps[main.savefile.current_map].reset();
                changeGameState(.PLAYING);
            }
        }
    }
    
    pub fn getRect(self: *Button) rl.Rectangle {
        const y_pos: f32 = 400 + @as(f32, @floatFromInt(self.index)) * 110;
        const width: f32 = scr.sim_size.x / 3;
        const height: f32 = 80;
        return rl.Rectangle{ .x = 0, .y = y_pos, .width = width, .height = height };
    }
    
    pub fn update(self: *Button) void {
        self.color = if(self.selected) .gold else .white;
    }
    
    pub fn draw(self: *Button) void {
        const up_left_point: rl.Vector2 = .{ .x = self.getRect().x, .y = self.getRect().y };
        const up_right_point: rl.Vector2 = .{ .x = self.getRect().x + self.getRect().width, .y = self.getRect().y };
        const bottom_left_point: rl.Vector2 = .{ .x = self.getRect().x, .y = self.getRect().y + self.getRect().height };
        const bottom_right_point: rl.Vector2 = .{ .x = self.getRect().x + self.getRect().width * 15 / 16, .y = self.getRect().y + self.getRect().height };
        const thickness: f32 = 5;
        
        rl.drawLineEx(up_left_point, up_right_point, thickness, self.color);
        rl.drawLineEx(bottom_left_point, bottom_right_point, thickness, self.color);
        //rl.drawLineEx(up_left_point, bottom_left_point, thickness, self.color);
        rl.drawLineEx(up_right_point, bottom_right_point, thickness, self.color);
            
        const measured_text = txt.measureCustomText(self.text, .ELEVATIA, .NORMAL, self.font_size);
        txt.drawCustomText(self.text, .ELEVATIA, .NORMAL, self.font_size, .{ .x = self.getRect().x + self.getRect().width - measured_text.x - self.getRect().width / 16, .y = self.getRect().y + scr.ui_buffer }, self.color);
    }
};

pub const Menu = struct {
    buttons: []Button,
    is_gameplay_menu: bool = false,
    is_map_transition_menu: bool = false,
    selected_button_index: i32 = 0,
    top_text: [:0]const u8 = "TOP TEXT PLACEHOLDER",
    top_text_font_size: f32 = 64,
    top_text_color: rl.Color = .white,
    
    pub fn update(self: *Menu) void {
        if(!self.is_gameplay_menu and !self.is_map_transition_menu) {
            if(inp.getPressKey(.UP)) self.selected_button_index -= 1;
            if(inp.getPressKey(.DOWN)) self.selected_button_index += 1;
            
            if(self.selected_button_index < 0) self.selected_button_index = @as(i32, @intCast(self.buttons.len)) - 1;
            if(self.selected_button_index > @as(i32, @intCast(self.buttons.len)) - 1) self.selected_button_index = 0;
            
            for(self.buttons, 0..) |*button, index| {
                button.selected = if(index == self.selected_button_index) true else false;
                button.update();
            }
            
            if(inp.getPressKey(.CONFIRM)) {
                for(self.buttons, 0..) |*button, index| {
                    if(index == self.selected_button_index) {
                        button.click(); 
                        break;
                    }
                }
            }
        } else if(self.is_map_transition_menu) {
            map_transition_timer.update();
            if(map_transition_timer.called) changeGameState(.PLAYING);
            if(@as(f32, @floatCast(rl.getTime())) - map_transition_timer.start_time >= map_transition_timer.duration / 2) {
                map_transition_color = rl.colorLerp(.black, .white, (@as(f32, @floatCast(rl.getTime())) - map_transition_timer.start_time - map_transition_timer.duration / 2) * 2 / map_transition_timer.duration);
                
                if(!map_transition_map_changed) {
                    map_transition_map_changed = true;
                    map.moveToMap(if(main.player.data.health <= 0) main.savefile.current_map else main.savefile.current_map + 1);
                    main.player.data.anim_state = .IDLE1;
                }
            } else {
                map_transition_color = rl.colorLerp(.white, .black, (@as(f32, @floatCast(rl.getTime())) - map_transition_timer.start_time) * 2 / map_transition_timer.duration);
            }
        }
    }
    
    pub fn draw(self: *Menu) void {
        for(self.buttons) |*button| button.draw();
        //maybe make a custom logo for main menu?
        txt.drawCustomText(self.top_text, .ELEVATIA, .NORMAL, self.top_text_font_size, .{ .x = scr.sim_size.x / 2 - txt.measureCustomText(self.top_text, .ELEVATIA, .NORMAL, self.top_text_font_size).x / 2, .y = 50 }, self.top_text_color);
    }
};

var menus: [@typeInfo(GameState).@"enum".fields.len]Menu = undefined;

fn createButton(text: [:0]const u8, button_type: ButtonType, index: usize) Button {
    return Button{ .button_type = button_type, .text = text, .font_size = 64, .index = index };
}

pub fn initMenus() void {
    menus = [_]Menu{
        // PLAYING
        Menu{ .buttons = main.mutateSlice(Button, &[_]Button{}), .is_gameplay_menu = true },
        
        // MAP TRANSITION
        Menu{ .buttons = main.mutateSlice(Button, &[_]Button{}), .is_map_transition_menu = true },
        
        // MAIN
        Menu{ 
            .buttons = main.mutateSlice(Button, &[_]Button{
                createButton("PLAY", .{ .reset_player = true }, 0),
                createButton("EXIT", .{ .change_game_state = .EXIT }, 1)
            }), 
            .top_text = "BLOB GAME: ULTIMATE"
        },
        
        // PAUSED
        Menu{ 
            .buttons = main.mutateSlice(Button, &[_]Button{
                createButton("CONTINUE", .{ .change_game_state = .PLAYING }, 0),
                createButton("BACK TO MAIN MENU", .{ .change_game_state = .MAIN }, 1)
            }), 
            .top_text = "PAUSED"
        },
        
        // EXIT
        Menu{ 
            .buttons = main.mutateSlice(Button, &[_]Button{
                createButton("YES :)", .{ .exit = true }, 0),
                createButton("NO :(", .{ .change_game_state = .MAIN }, 1)
            }), 
            .top_text = "EXIT THE GAME?"
        }
    };
}

pub fn updateMenus() void {
    menus[@intFromEnum(main.game_state)].update();
}

pub fn drawMenus() void {
    menus[@intFromEnum(main.game_state)].draw();
}