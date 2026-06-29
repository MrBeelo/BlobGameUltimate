const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const raylib_dep = b.dependency("raylib_zig", .{
        .target = target,
        .optimize = optimize,
        .linux_display_backend = .X11
    });

    const raylib = raylib_dep.module("raylib");
    const raygui = raylib_dep.module("raygui");
    const raylib_artifact = raylib_dep.artifact("raylib");
    
    exe_mod.addImport("raylib", raylib);
    exe_mod.addImport("raygui", raygui);
    exe_mod.linkLibrary(raylib_artifact);
    
    const sdk_path_opt = b.option([]const u8, "macos-sdk-path", "Path to macOS SDK");
    
    if (sdk_path_opt) |sdk_path| {
        const full_path = try std.fs.path.join(b.allocator, &[_][]const u8{sdk_path, "System/Library/Frameworks"});
        exe_mod.addSystemFrameworkPath(b.path(full_path));
    }

    const exe = b.addExecutable(.{
        .name = "BlobGameUltimate",
        .root_module = exe_mod,
    });

    exe.use_llvm = true;

    b.installArtifact(exe);
    
    b.installDirectory(.{
        .source_dir = b.path("res"),
        .install_dir = .bin,
        .install_subdir = "res",
    });
    
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_unit_tests = b.addTest(.{
        .root_module = exe_mod,
    });

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);
}
