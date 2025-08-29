const std = @import("std");
const notifications = @import("main.zig");

// Example of how to create and send different types of notifications

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    std.debug.print("GitHub Notifications Example\n", .{});
    std.debug.print("============================\n\n", .{});

    // Example 1: Issue notification
    const issue_notification = notifications.GitHubNotification{
        .title = "Bug Report",
        .repository = "ziglang/zig",
        .action = "New issue opened",
        .url = "https://github.com/ziglang/zig/issues/12345",
    };

    std.debug.print("1. Issue Notification:\n", .{});
    issue_notification.sendToConsole();

    // Example 2: Pull Request notification
    const pr_notification = notifications.GitHubNotification{
        .title = "Feature: Add Windows notifications",
        .repository = "your-username/zig-notifications",
        .action = "Pull request opened",
        .url = "https://github.com/your-username/zig-notifications/pull/1",
    };

    std.debug.print("\n2. Pull Request Notification:\n", .{});
    pr_notification.sendToConsole();

    // Example 3: Release notification
    const release_notification = notifications.GitHubNotification{
        .title = "Version 1.0.0 Released",
        .repository = "your-username/awesome-project",
        .action = "New release published",
        .url = "https://github.com/your-username/awesome-project/releases/tag/v1.0.0",
    };

    std.debug.print("\n3. Release Notification:\n", .{});
    release_notification.sendToConsole();

    // Example 4: Custom notification
    std.debug.print("\n4. Custom Notification:\n", .{});
    notifications.sendConsoleNotification(
        "Build Complete",
        "Your Zig project has been successfully compiled!\nNo errors found.",
    );

    // Example 5: Try Windows System Tray notification
    std.debug.print("\n5. Attempting Windows System Tray notification...\n", .{});
    notifications.sendNotification(allocator, "Zig Project", "Hello from Zig! This project can send Windows system tray notifications.") catch |err| {
        std.debug.print("System tray notification failed: {}\n", .{err});
    };

    // Example 6: Enhanced console notification
    std.debug.print("\n6. Enhanced console notification...\n", .{});
    const tray = @import("tray.zig");
    tray.sendConsoleDesktopNotification("Enhanced Display", "This shows a more visual representation of desktop notifications.");

    // Example 7: Try another tray notification
    std.debug.print("\n7. Attempting another tray notification...\n", .{});
    notifications.sendTrayNotification(allocator, "Second Notification", "This is a second system tray notification example.") catch |err| {
        std.debug.print("Second tray notification failed: {}\n", .{err});
    };

    std.debug.print("\nAll examples completed!\n", .{});
    std.debug.print("Try running this on Windows to see the system tray notifications (balloon tips).\n", .{});
    std.debug.print("Enhanced console notifications provide a visual preview of how desktop notifications look.\n", .{});
}
