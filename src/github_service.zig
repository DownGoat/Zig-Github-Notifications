const std = @import("std");
const print = std.debug.print;
const github = @import("github.zig");
const notifications = @import("main.zig");
const tray = @import("tray.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    print("GitHub Notifications Background Service\n", .{});
    print("======================================\n\n", .{});

    // Get GitHub token from environment
    const github_token = std.process.getEnvVarOwned(allocator, "GITHUB_TOKEN") catch {
        print("❌ No GitHub token found!\n", .{});
        print("Set the GITHUB_TOKEN environment variable with your personal access token.\n", .{});
        print("Example: $env:GITHUB_TOKEN=\"ghp_your_token_here\"\n", .{});
        return;
    };
    defer allocator.free(github_token);

    if (github_token.len == 0) {
        print("❌ GitHub token is empty!\n", .{});
        return;
    }

    // Initialize GitHub client
    var github_client = github.GitHubClient.init(allocator, github_token);
    defer github_client.deinit();

    print("🚀 Starting background service...\n", .{});
    print("⏰ Checking for new GitHub notifications every 60 seconds\n", .{});
    print("🔔 Desktop notifications will appear for new items only\n", .{});
    print("📝 Press Ctrl+C to stop the service\n\n", .{});

    // Send initial notification that service started
    tray.sendSystemTrayNotification(allocator, "GitHub Service", "Background monitoring started") catch {
        print("⚠️  Failed to send system tray notification\n", .{});
    };

    var check_count: u32 = 0;

    // Main service loop
    while (true) {
        check_count += 1;
        const timestamp = std.time.timestamp();

        print("🔍 Check #{} at timestamp {}\n", .{ check_count, timestamp });

        // Check for new notifications
        const new_notifications = github_client.getNewNotifications() catch |err| {
            print("❌ Failed to fetch notifications: {}\n", .{err});

            // Send error notification
            tray.sendSystemTrayNotification(allocator, "GitHub Error", "Failed to check notifications") catch {};

            // Wait before next check
            std.time.sleep(60 * std.time.ns_per_s); // 60 seconds
            continue;
        };

        if (new_notifications.len > 0) {
            print("🔔 {} new notification(s) found!\n", .{new_notifications.len});

            // Send desktop notifications for each new notification
            for (new_notifications, 0..) |notification, i| {
                const icon = github.getNotificationIcon(notification.notification_type);
                const reason_desc = github.getReasonDescription(notification.reason);

                print("   {}. {s} {s} {s}\n", .{ i + 1, icon, notification.notification_type, notification.title });
                print("      Repository: {s}\n", .{notification.repository});
                print("      Reason: {s}\n", .{reason_desc});
                print("      URL: {s}\n", .{notification.url});

                // Create desktop notification title and message
                var title_buffer: [256]u8 = undefined;
                const notification_title = std.fmt.bufPrint(title_buffer[0..], "GitHub: {s}", .{notification.repository}) catch "GitHub Notification";

                var message_buffer: [512]u8 = undefined;
                const notification_message = std.fmt.bufPrint(message_buffer[0..], "{s}: {s}\n{s}", .{ notification.notification_type, notification.title, reason_desc }) catch notification.title;

                // Send system tray notification
                tray.sendSystemTrayNotification(allocator, notification_title, notification_message) catch {
                    print("⚠️  Failed to send notification for: {s}\n", .{notification.title});
                };

                // Small delay between notifications to avoid spam
                if (i < new_notifications.len - 1) {
                    std.time.sleep(2 * std.time.ns_per_s); // 2 seconds
                }
            }

            // Send summary notification if more than 3 new notifications
            if (new_notifications.len > 3) {
                var summary_buffer: [256]u8 = undefined;
                const summary_message = std.fmt.bufPrint(summary_buffer[0..], "You have {} new GitHub notifications", .{new_notifications.len}) catch "Multiple new notifications";

                tray.sendSystemTrayNotification(allocator, "GitHub Summary", summary_message) catch {};
            }
        } else {
            print("✅ No new notifications\n", .{});
        }

        // Free notifications
        github_client.freeNotifications(new_notifications);

        print("⏳ Waiting 60 seconds until next check...\n\n", .{});

        // Wait 60 seconds before next check
        std.time.sleep(60 * std.time.ns_per_s);
    }
}
