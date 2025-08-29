const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "zig-notifications",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Link Windows libraries needed for notifications
    exe.linkSystemLibrary("ole32");
    exe.linkSystemLibrary("shell32");
    exe.linkSystemLibrary("user32");
    exe.linkLibC();

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // Examples executable
    const examples_exe = b.addExecutable(.{
        .name = "examples",
        .root_source_file = b.path("src/examples.zig"),
        .target = target,
        .optimize = optimize,
    });

    examples_exe.linkSystemLibrary("ole32");
    examples_exe.linkSystemLibrary("shell32");
    examples_exe.linkSystemLibrary("user32");
    examples_exe.linkLibC();

    b.installArtifact(examples_exe);

    const run_examples_cmd = b.addRunArtifact(examples_exe);
    run_examples_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_examples_cmd.addArgs(args);
    }

    const run_examples_step = b.step("examples", "Run the examples");
    run_examples_step.dependOn(&run_examples_cmd.step);

    // GitHub checker executable
    const github_checker_exe = b.addExecutable(.{
        .name = "github-checker",
        .root_source_file = b.path("src/github_checker.zig"),
        .target = target,
        .optimize = optimize,
    });

    github_checker_exe.linkSystemLibrary("ole32");
    github_checker_exe.linkSystemLibrary("shell32");
    github_checker_exe.linkSystemLibrary("user32");
    github_checker_exe.linkLibC();

    b.installArtifact(github_checker_exe);

    const run_github_checker_cmd = b.addRunArtifact(github_checker_exe);
    run_github_checker_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_github_checker_cmd.addArgs(args);
    }

    const run_github_checker_step = b.step("github", "Check GitHub notifications");
    run_github_checker_step.dependOn(&run_github_checker_cmd.step);

    // GitHub background service executable
    const github_service_exe = b.addExecutable(.{
        .name = "github-service",
        .root_source_file = b.path("src/github_service.zig"),
        .target = target,
        .optimize = optimize,
    });

    github_service_exe.linkSystemLibrary("ole32");
    github_service_exe.linkSystemLibrary("shell32");
    github_service_exe.linkSystemLibrary("user32");
    github_service_exe.linkLibC();

    b.installArtifact(github_service_exe);

    const run_github_service_cmd = b.addRunArtifact(github_service_exe);
    run_github_service_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_github_service_cmd.addArgs(args);
    }

    const run_github_service_step = b.step("service", "Run GitHub notifications background service");
    run_github_service_step.dependOn(&run_github_service_cmd.step);

    // Tests
    const unit_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_unit_tests = b.addRunArtifact(unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}
