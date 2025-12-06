const std = @import("std");
const rl = @import("raylib");
const main = @import("main.zig");
const crsh = @import("crash.zig");

const settings_path = "res/data/settings.json";

pub const Settings = struct {
    volume: i32
};

pub fn loadSettings(settings: *Settings) !void {
    var file = std.fs.cwd().openFile(settings_path, .{ .mode = .read_only }) catch |err| switch (err) {
        error.FileNotFound => try std.fs.cwd().createFile(settings_path, .{}),
        else => return err
    };
    defer file.close();
    
    const file_size = try file.getEndPos();
    const buffer = try main.allocator.alloc(u8, file_size);
    defer main.allocator.free(buffer);
    
    _ = try file.readAll(buffer);
    
    var parsed_value: std.json.Parsed(std.json.Value) = std.json.parseFromSlice(std.json.Value, main.allocator, buffer, .{}) catch |err| switch (err) {
        error.UnexpectedEndOfInput => {
            var new_settings = newSettings();
            try saveSettings(&new_settings);
            settings.* = new_settings;
            return;
        },
        else => return err
    };
    defer parsed_value.deinit();
    
    const parsed_settings = parsed_value.value.object;
    settings.volume = @intCast(parsed_settings.get("volume").?.integer);
}

pub fn saveSettings(settings: *Settings) !void {
    var file = std.fs.cwd().openFile(settings_path, .{ .mode = .read_write }) catch |err| switch (err) {
        error.FileNotFound => try std.fs.cwd().createFile(settings_path, .{}),
        else => return err
    };
    
    defer file.close();
    
    try file.setEndPos(0);
    try file.seekTo(0);
    
    var buffer: [256]u8 = undefined;
    var file_writer = file.writer(&buffer);
    var file_writer_interface = &file_writer.interface;
    
    var stringify = std.json.Stringify{ .writer = file_writer_interface };
    try stringify.write(settings);
    
    try file_writer_interface.flush();
}

pub fn newSettings() Settings {
    return .{ 
        .volume = 10
    };
}