const std = @import("std");
const rl = @import("raylib");

const CrashReason = enum {
    RAYLIB_ERROR,
    OUT_OF_MEMORY,
    MAP_ERROR
};

pub fn crashWithMessage(message: []const u8) noreturn {
    @panic(message);
}

pub fn crash(reason: CrashReason) noreturn {
    switch (reason) {
        .RAYLIB_ERROR => crashWithMessage("ERROR: Raylib messed up!"),
        .OUT_OF_MEMORY => crashWithMessage("ERROR: Ran out of memory!"),
        .MAP_ERROR => crashWithMessage("ERROR: Error loading map!")
    }
}

