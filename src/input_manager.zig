const std = @import("std");
const rl = @import("raylib");

const GameKey = enum {
    LEFT,
    RIGHT,
    UP,
    DOWN,
    JUMP,
    CONFIRM,
    F3
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
    
    handleBothKeys(.a, .LEFT);
    handleBothKeys(.d, .RIGHT);
    handleBothKeys(.w, .UP);
    handleBothKeys(.s, .DOWN);
    handlePressKey(.space, .JUMP);
    handlePressKey(.enter, .CONFIRM);
    handlePressKey(.f3, .F3);
}