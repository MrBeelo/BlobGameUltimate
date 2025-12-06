const std = @import("std");
const rl = @import("raylib");
const main = @import("main.zig");

const GameKey = enum {
    LEFT,
    RIGHT,
    UP,
    DOWN,
    JUMP,
    ATTACK,
    CONFIRM,
    F3,
    ESCAPE
};

const game_key_enum_length = @typeInfo(GameKey).@"enum".fields.len;
var holdKeys: [game_key_enum_length]bool = [_]bool{ false } ** game_key_enum_length;
var pressKeys: [game_key_enum_length]bool = [_]bool{ false } ** game_key_enum_length;

pub fn getHoldKey(key: GameKey) bool {
    return holdKeys[@intFromEnum(key)];
}

pub fn getPressKey(key: GameKey) bool {
    return pressKeys[@intFromEnum(key)];
}

fn handleHoldKey(key: rl.KeyboardKey, game_key: GameKey) void {
    if(rl.isKeyDown(key)) holdKeys[@intFromEnum(game_key)] = true;
}

fn handlePressKey(key: rl.KeyboardKey, game_key: GameKey) void {
    if(rl.isKeyPressed(key)) pressKeys[@intFromEnum(game_key)] = true;
}

fn handleBothKeys(key: rl.KeyboardKey, game_key: GameKey) void {
    handleHoldKey(key, game_key);
    handlePressKey(key, game_key);
}

pub fn updateInputManager() void {
    holdKeys = [_]bool{ false } ** game_key_enum_length;
    pressKeys = [_]bool{ false } ** game_key_enum_length;
    
    handleBothKeys(if(main.settings.arrow_keys) .left else .a, .LEFT);
    handleBothKeys(if(main.settings.arrow_keys) .right else .d, .RIGHT);
    handleBothKeys(if(main.settings.arrow_keys) .up else .w, .UP);
    handleBothKeys(if(main.settings.arrow_keys) .down else .s, .DOWN);
    handlePressKey(if(main.settings.x_jump_key) .x else .space, .JUMP);
    handlePressKey(if(main.settings.z_attack_key) .z else .k, .ATTACK);
    handlePressKey(.enter, .CONFIRM);
    handlePressKey(.f3, .F3);
    handlePressKey(.escape, .ESCAPE);
}