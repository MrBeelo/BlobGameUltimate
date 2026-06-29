const std = @import("std");
const rl = @import("raylib");
const main = @import("main.zig");
const crsh = @import("crash.zig");

const settings_path = "res/data/settings.json";

pub const Settings = struct {
    volume: i32,
    arrow_keys: bool,
    x_jump_key: bool,
    z_attack_key: bool,
};

pub fn loadSettings(settings: *Settings) !void {
    var file = std.Io.Dir.cwd().openFile(main.io, settings_path, .{ .mode = .read_only }) catch |err| switch (err) {
        error.FileNotFound => try std.Io.Dir.cwd().createFile(main.io, settings_path, .{}),
        else => return err
    };
    defer file.close(main.io);
    
    const file_size = try file.length(main.io);
    const buffer = try main.allocator.alloc(u8, file_size);
    defer main.allocator.free(buffer);

    var read_buffer: [4096]u8 = undefined;
    var reader = file.reader(main.io, &read_buffer);
    var reader_interface = &reader.interface;
    
    _ = try reader_interface.readSliceAll(buffer);
    
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
    settings.arrow_keys = parsed_settings.get("arrow_keys").?.bool;
    settings.x_jump_key = parsed_settings.get("x_jump_key").?.bool;
    settings.z_attack_key = parsed_settings.get("z_attack_key").?.bool;
}

pub fn saveSettings(settings: *Settings) !void {
    var file = std.Io.Dir.cwd().openFile(main.io, settings_path, .{ .mode = .read_write }) catch |err| switch (err) {
        error.FileNotFound => try std.Io.Dir.cwd().createFile(main.io, settings_path, .{}),
        else => return err
    };
    
    defer file.close(main.io);
    
    try file.setLength(main.io, 0);
    var read_buf: [4096]u8 = undefined;
    var reader = file.reader(main.io, &read_buf);
    
    try reader.seekTo(0);
    
    var buffer: [256]u8 = undefined;
    var file_writer = file.writer(main.io, &buffer);
    var file_writer_interface = &file_writer.interface;
    
    var stringify = std.json.Stringify{ .writer = file_writer_interface };
    try stringify.write(settings);
    
    try file_writer_interface.flush();
}

pub fn newSettings() Settings {
    return .{ 
        .volume = 10,
        .arrow_keys = false,
        .x_jump_key = false,
        .z_attack_key = false,
    };
}