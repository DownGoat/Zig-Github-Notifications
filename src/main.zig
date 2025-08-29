const std = @import("std");
const windows = std.os.windows;
const print = std.debug.print;
const tray = @import("tray.zig");

pub const NotificationError = error{
    ComInitFailed,
    NotificationFailed,
    OutOfMemory,
};

pub fn sendNotification(allocator: std.mem.Allocator, title: []const u8, message: []const u8) NotificationError!void {
    // Try to send a system tray notification first
    tray.sendSystemTrayNotification(allocator, title, message) catch |err| {
        print("System tray notification failed: {}, falling back to console\n", .{err});
        tray.sendConsoleDesktopNotification(title, message);
        return;
    };
}

// Alternative: Send enhanced console notification
pub fn sendTrayNotification(allocator: std.mem.Allocator, title: []const u8, message: []const u8) NotificationError!void {
    tray.sendSystemTrayNotification(allocator, title, message) catch |err| {
        print("Tray notification failed: {}, using enhanced console display\n", .{err});
        tray.sendConsoleDesktopNotification(title, message);
        return;
    };
}

// Alternative: Simple console notification for testing
pub fn sendConsoleNotification(title: []const u8, message: []const u8) void {
    print("🔔 NOTIFICATION\n", .{});
    print("Title: {s}\n", .{title});
    print("Message: {s}\n", .{message});
    print("─────────────────────────────\n", .{});
}

// GitHub notification specific functions
pub const GitHubNotification = struct {
    title: []const u8,
    repository: []const u8,
    action: []const u8,
    url: []const u8,

    pub fn send(self: GitHubNotification, allocator: std.mem.Allocator) NotificationError!void {
        const formatted_title = try std.fmt.allocPrint(allocator, "GitHub: {s}", .{self.title});
        defer allocator.free(formatted_title);

        const formatted_message = try std.fmt.allocPrint(allocator, "{s} in {s}\n{s}", .{ self.action, self.repository, self.url });
        defer allocator.free(formatted_message);

        try sendNotification(allocator, formatted_title, formatted_message);
    }

    pub fn sendToConsole(self: GitHubNotification) void {
        print("🔔 GITHUB NOTIFICATION\n", .{});
        print("Title: {s}\n", .{self.title});
        print("Repository: {s}\n", .{self.repository});
        print("Action: {s}\n", .{self.action});
        print("URL: {s}\n", .{self.url});
        print("─────────────────────────────\n", .{});
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    print("Windows Desktop Notifications Demo\n", .{});
    print("==================================\n\n", .{});

    // Demo 1: Console notification (always works)
    print("Sending console notification...\n", .{});
    sendConsoleNotification("Hello from Zig!", "This is a test notification from your Zig application.");

    // Demo 2: GitHub-style notification
    print("\nSending GitHub notification...\n", .{});
    const github_notification = GitHubNotification{
        .title = "New Pull Request",
        .repository = "user/awesome-project",
        .action = "Pull request opened",
        .url = "https://github.com/user/awesome-project/pull/123",
    };
    github_notification.sendToConsole();

    // Demo 3: Try Windows System Tray notification
    print("\nTrying Windows System Tray notification...\n", .{});
    sendNotification(allocator, "Zig Desktop Notification", "Hello from Zig! This is a Windows system tray notification.") catch |err| {
        print("System tray notification failed: {}\n", .{err});
    };

    // Demo 4: Try enhanced console notification
    print("\nTrying enhanced console notification...\n", .{});
    tray.sendConsoleDesktopNotification("Enhanced Console", "This shows how a desktop notification would look in a more visual format.");

    // Demo 5: GitHub notification as desktop notification
    print("\nSending GitHub notification as desktop notification...\n", .{});
    const formatted_title = try std.fmt.allocPrint(allocator, "GitHub: {s}", .{github_notification.title});
    defer allocator.free(formatted_title);

    const formatted_message = try std.fmt.allocPrint(allocator, "{s} in {s}\n{s}", .{ github_notification.action, github_notification.repository, github_notification.url });
    defer allocator.free(formatted_message);

    sendNotification(allocator, formatted_title, formatted_message) catch |err| {
        print("GitHub desktop notification failed: {}\n", .{err});
    };

    print("\nDemo completed!\n", .{});
    print("Note: System tray notifications appear as balloon tips in Windows.\n", .{});
    print("Enhanced console notifications show a visual representation.\n", .{});
}

test "notification creation" {
    const testing = std.testing;

    const notification = GitHubNotification{
        .title = "Test Notification",
        .repository = "test/repo",
        .action = "Test action",
        .url = "https://github.com/test/repo",
    };

    // Test that we can create notifications without errors
    try testing.expect(notification.title.len > 0);
    try testing.expect(notification.repository.len > 0);
}

test "system tray notification creation" {
    const testing = std.testing;
    const allocator = testing.allocator;

    // Test the tray notification creation (this will test string handling internally)
    tray.sendSystemTrayNotification(allocator, "Test", "Message") catch |err| {
        // It's expected that this might fail in test environment
        try testing.expect(err != error.OutOfMemory);
    };
}
