const std = @import("std");
const rl = @import("raylib");
const main = @import("main.zig");
const crsh = @import("crash.zig");

const savefile_path = "res/data/savefile.json";

pub const SaveFile = struct {
    current_map: usize,
    played_intro: bool,
    coins: i32,
    milk: i32,
    has_sword: bool
};

pub fn loadSaveFile(savefile: *SaveFile) !void {
    var file = std.Io.Dir.cwd().openFile(main.io, savefile_path, .{ .mode = .read_only }) catch |err| switch (err) {
        error.FileNotFound => try std.Io.Dir.cwd().createFile(main.io, savefile_path, .{}),
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
            var new_savefile = newSaveFile();
            try saveSaveFile(&new_savefile);
            savefile.* = new_savefile;
            return;
        },
        else => return err
    };
    defer parsed_value.deinit();
    
    const parsed_savefile = parsed_value.value.object;
    savefile.current_map = @intCast(parsed_savefile.get("current_map").?.integer);
    savefile.played_intro = parsed_savefile.get("played_intro").?.bool;
    savefile.coins = @intCast(parsed_savefile.get("coins").?.integer);
    savefile.milk = @intCast(parsed_savefile.get("milk").?.integer);
    savefile.has_sword = parsed_savefile.get("has_sword").?.bool;
}

pub fn saveSaveFile(savefile: *SaveFile) !void {
    var file = std.Io.Dir.cwd().openFile(main.io, savefile_path, .{ .mode = .read_write }) catch |err| switch (err) {
        error.FileNotFound => try std.Io.Dir.cwd().createFile(main.io, savefile_path, .{}),
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
    try stringify.write(savefile);
    
    try file_writer_interface.flush();
}

pub fn newSaveFile() SaveFile {
    return .{ 
        .current_map = 0, 
        .played_intro = false,
        .coins = 0,
        .milk = 0,
        .has_sword = false
    };
}