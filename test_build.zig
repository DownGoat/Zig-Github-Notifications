const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Test executable to check for Windows Runtime APIs
    const test_exe = b.addExecutable(.{
        .name = "test-winrt",
        .root_source_file = b.path("src/test_winrt.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Try to link common Windows libraries to test if SDK is available
    test_exe.linkSystemLibrary("advapi32");
    test_exe.linkSystemLibrary("kernel32");
    test_exe.linkSystemLibrary("ole32");
    test_exe.linkSystemLibrary("shell32");
    test_exe.linkSystemLibrary("user32");
    test_exe.linkLibC();

    b.installArtifact(test_exe);

    const test_step = b.step("test-runtime", "Test if runtimeobject library is available");
    test_step.dependOn(&b.addInstallArtifact(test_exe, .{}).step);
}
