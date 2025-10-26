const std = @import("std");
const rl = @import("raylib");
const crsh = @import("crash.zig");

pub var blur: rl.Shader = undefined;

pub fn loadShaders() void {
    blur = rl.loadShader(null, "res/shader/blur.fs") catch crsh.crash(.RAYLIB_ERROR);
}

pub fn unloadShaders() void {
    rl.unloadShader(blur);
}