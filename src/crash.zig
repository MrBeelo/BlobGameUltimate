const std = @import("std");
const rl = @import("raylib");

const CrashReason = enum {
    RAYLIB_ERROR,
    OUT_OF_MEMORY,
    MAP_ERROR,
    SAVE_ERROR
};

pub fn crashWithMessage(message: []const u8) noreturn {
    @panic(message);
}

pub fn crash(reason: CrashReason) noreturn {
    switch (reason) {
        .RAYLIB_ERROR => crashWithMessage("GAME ERROR: Raylib messed up!"),
        .OUT_OF_MEMORY => crashWithMessage("GAME ERROR: Ran out of memory!"),
        .MAP_ERROR => crashWithMessage("GAME ERROR: Error loading map!"),
        .SAVE_ERROR => crashWithMessage("GAME ERROR: Error while loading/saving saves!")
    }
}

