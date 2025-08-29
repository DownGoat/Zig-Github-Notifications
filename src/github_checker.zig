const std = @import("std");
const print = std.debug.print;
const github = @import("github.zig");
const notifications = @import("main.zig");
const tray = @import("tray.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    print("GitHub Notifications Checker\n", .{});
    print("===========================\n\n", .{});

    // For demo purposes, we'll use a placeholder token
    // In real usage, you'd get this from environment variables or config file
    const github_token = std.process.getEnvVarOwned(allocator, "GITHUB_TOKEN") catch "your_github_token_here";
    defer if (!std.mem.eql(u8, github_token, "your_github_token_here")) allocator.free(github_token);

    if (std.mem.eql(u8, github_token, "your_github_token_here")) {
        print("⚠️  No GitHub token found!\n", .{});
        print("Set the GITHUB_TOKEN environment variable with your personal access token.\n", .{});
        print("For now, showing mock notifications...\n\n", .{});
    }

    // Initialize GitHub client
    var github_client = github.GitHubClient.init(allocator, github_token);
    defer github_client.deinit();

    // Fetch notifications
    print("Fetching GitHub notifications...\n", .{});
    const github_notifications = github_client.fetchNotifications() catch |err| {
        print("Failed to fetch GitHub notifications: {}\n", .{err});
        return;
    };
    defer github_client.freeNotifications(github_notifications);

    if (github_notifications.len == 0) {
        print("No notifications found.\n", .{});
        tray.sendConsoleDesktopNotification("GitHub", "No new notifications");
        return;
    }

    print("Found {d} notifications:\n\n", .{github_notifications.len});

    // Display each notification
    for (github_notifications, 0..) |notification, i| {
        const icon = github.getNotificationIcon(notification.notification_type);
        const reason_desc = github.getReasonDescription(notification.reason);

        print("{d}. {s} {s} {s}\n", .{ i + 1, icon, notification.notification_type, notification.title });
        print("   Repository: {s}\n", .{notification.repository});
        print("   Reason: {s}\n", .{reason_desc});
        print("   Updated: {s}\n", .{notification.updated_at});
        print("   Unread: {}\n", .{notification.unread});
        print("   URL: {s}\n\n", .{notification.url});

        // Send desktop notification for unread notifications
        if (notification.unread) {
            const title = try std.fmt.allocPrint(allocator, "{s} GitHub: {s}", .{ icon, notification.notification_type });
            defer allocator.free(title);

            const message = try std.fmt.allocPrint(allocator, "{s}\n{s}\n{s}", .{ notification.title, notification.repository, reason_desc });
            defer allocator.free(message);

            print("Sending desktop notification for: {s}\n", .{notification.title});
            notifications.sendNotification(allocator, title, message) catch |err| {
                print("Failed to send desktop notification: {}\n", .{err});
            };

            // Add a small delay between notifications to avoid overwhelming the user
            std.time.sleep(1000000000); // 1 second
        }
    }

    // Summary notification
    const unread_count = blk: {
        var count: usize = 0;
        for (github_notifications) |notification| {
            if (notification.unread) count += 1;
        }
        break :blk count;
    };

    if (unread_count > 0) {
        const summary_title = "📢 GitHub Summary";

        const summary_message = try std.fmt.allocPrint(allocator, "You have {d} unread notification{s}", .{ unread_count, if (unread_count == 1) @as([]const u8, "") else @as([]const u8, "s") });
        defer allocator.free(summary_message);

        print("\nSending summary notification...\n", .{});
        notifications.sendNotification(allocator, summary_title, summary_message) catch |err| {
            print("Failed to send summary notification: {}\n", .{err});
        };
    }

    print("\nGitHub notifications check completed!\n", .{});
}

// Helper function to demonstrate notification monitoring
pub fn startNotificationMonitor(allocator: std.mem.Allocator, github_token: []const u8, check_interval_seconds: u32) !void {
    print("Starting GitHub notification monitor (checking every {d} seconds)...\n", .{check_interval_seconds});

    var github_client = github.GitHubClient.init(allocator, github_token);
    defer github_client.deinit();

    var last_check_time: i64 = std.time.timestamp();

    while (true) {
        const current_time = std.time.timestamp();

        // Check for new notifications
        const github_notifications = github_client.fetchNotifications() catch |err| {
            print("Monitor: Failed to fetch notifications: {}\n", .{err});
            std.time.sleep(check_interval_seconds * std.time.ns_per_s);
            continue;
        };
        defer github_client.freeNotifications(github_notifications);

        // Look for notifications newer than last check
        var new_notifications: usize = 0;
        for (github_notifications) |notification| {
            if (notification.unread) {
                // In a real implementation, you'd parse the updated_at timestamp
                // and compare it with last_check_time
                new_notifications += 1;

                const title = try std.fmt.allocPrint(allocator, "🔔 New GitHub {s}", .{notification.notification_type});
                defer allocator.free(title);

                notifications.sendNotification(allocator, title, notification.title) catch |err| {
                    print("Monitor: Failed to send notification: {}\n", .{err});
                };
            }
        }

        if (new_notifications > 0) {
            print("Monitor: Found {d} new notifications\n", .{new_notifications});
        }

        last_check_time = current_time;
        std.time.sleep(check_interval_seconds * std.time.ns_per_s);
    }
}
