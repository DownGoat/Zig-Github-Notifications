// Example configuration for GitHub notifications
// This shows how you might configure the notification system

const std = @import("std");

pub const NotificationConfig = struct {
    // Notification settings
    enabled: bool = true,
    sound_enabled: bool = true,
    show_in_tray: bool = true,

    // GitHub settings
    github_token: ?[]const u8 = null,
    repositories: []const []const u8 = &.{},
    notification_types: NotificationTypes = .{},

    // Display settings
    duration_ms: u32 = 5000,
    max_notifications: u8 = 5,
};

pub const NotificationTypes = struct {
    issues: bool = true,
    pull_requests: bool = true,
    releases: bool = true,
    commits: bool = false,
    stars: bool = false,
    forks: bool = false,
};

// Example configuration
pub const default_config = NotificationConfig{
    .enabled = true,
    .sound_enabled = true,
    .show_in_tray = true,
    .github_token = null, // Set this to your GitHub personal access token
    .repositories = &.{
        "microsoft/vscode",
        "ziglang/zig",
        "your-username/your-repo",
    },
    .notification_types = .{
        .issues = true,
        .pull_requests = true,
        .releases = true,
        .commits = false,
        .stars = true,
        .forks = false,
    },
    .duration_ms = 5000,
    .max_notifications = 3,
};

pub fn loadConfig(allocator: std.mem.Allocator, path: []const u8) !NotificationConfig {
    // In a real implementation, this would load from a JSON/TOML file
    _ = allocator; // TODO: implement file loading
    _ = path; // TODO: implement file loading

    // For now, return the default config
    return default_config;
}

pub fn saveConfig(config: NotificationConfig, allocator: std.mem.Allocator, path: []const u8) !void {
    // In a real implementation, this would save to a JSON/TOML file
    _ = config; // TODO: implement file saving
    _ = allocator; // TODO: implement file saving
    _ = path; // TODO: implement file saving

    std.debug.print("Config would be saved to: {s}\n", .{path});
}
