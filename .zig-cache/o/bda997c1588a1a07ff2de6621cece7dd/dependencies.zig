pub const packages = struct {
    pub const @"N-V-__8AABHMqAWYuRdIlflwi8gksPnlUMQBiSxAqQAAZFms" = struct {
        pub const available = false;
    };
    pub const @"N-V-__8AAJl1DwBezhYo_VE6f53mPVm00R-Fk28NPW7P14EQ" = struct {
        pub const available = true;
        pub const build_root = "/home/mrbeelo/.cache/zig/p/N-V-__8AAJl1DwBezhYo_VE6f53mPVm00R-Fk28NPW7P14EQ";
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"N-V-__8AAOQabwCjOjMI2uUTw4Njc0tAUOO6Lw2kCydLbvVG" = struct {
        pub const build_root = "/home/mrbeelo/.cache/zig/p/N-V-__8AAOQabwCjOjMI2uUTw4Njc0tAUOO6Lw2kCydLbvVG";
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"raylib-5.5.0-whq8uBlJxwRAvOHHNQIi8WS0QTbQJcdx7FbjSSOnPn6n" = struct {
        pub const build_root = "/home/mrbeelo/.cache/zig/p/raylib-5.5.0-whq8uBlJxwRAvOHHNQIi8WS0QTbQJcdx7FbjSSOnPn6n";
        pub const build_zig = @import("raylib-5.5.0-whq8uBlJxwRAvOHHNQIi8WS0QTbQJcdx7FbjSSOnPn6n");
        pub const deps: []const struct { []const u8, []const u8 } = &.{
            .{ "xcode_frameworks", "N-V-__8AABHMqAWYuRdIlflwi8gksPnlUMQBiSxAqQAAZFms" },
            .{ "emsdk", "N-V-__8AAJl1DwBezhYo_VE6f53mPVm00R-Fk28NPW7P14EQ" },
        };
    };
    pub const @"raylib-zig" = struct {
        pub const build_root = "/home/mrbeelo/Projects/Games/BlobGameUltimate/raylib-zig";
        pub const build_zig = @import("raylib-zig");
        pub const deps: []const struct { []const u8, []const u8 } = &.{
            .{ "raylib", "raylib-5.5.0-whq8uBlJxwRAvOHHNQIi8WS0QTbQJcdx7FbjSSOnPn6n" },
            .{ "raygui", "N-V-__8AAOQabwCjOjMI2uUTw4Njc0tAUOO6Lw2kCydLbvVG" },
        };
    };
};

pub const root_deps: []const struct { []const u8, []const u8 } = &.{
    .{ "raylib_zig", "raylib-zig" },
};
