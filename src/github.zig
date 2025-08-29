const std = @import("std");
const print = std.debug.print;

pub const GitHubNotification = struct {
    id: []const u8,
    title: []const u8,
    repository: []const u8,
    reason: []const u8,
    notification_type: []const u8,
    url: []const u8,
    updated_at: []const u8,
    unread: bool,
};

pub const GitHubError = error{
    NetworkError,
    AuthenticationError,
    ParseError,
    OutOfMemory,
    InvalidToken,
    RateLimited,
};

pub const GitHubClient = struct {
    allocator: std.mem.Allocator,
    token: []const u8,
    http_client: std.http.Client,
    last_seen_notifications: std.StringHashMap(bool),

    const GITHUB_API_BASE = "https://api.github.com";
    const USER_AGENT = "ZigGitHubNotifications/1.0";

    pub fn init(allocator: std.mem.Allocator, token: []const u8) GitHubClient {
        return GitHubClient{
            .allocator = allocator,
            .token = token,
            .http_client = std.http.Client{ .allocator = allocator },
            .last_seen_notifications = std.StringHashMap(bool).init(allocator),
        };
    }

    pub fn deinit(self: *GitHubClient) void {
        self.http_client.deinit();
        self.last_seen_notifications.deinit();
    }

    pub fn fetchNotifications(self: *GitHubClient) ![]GitHubNotification {
        // Try to fetch real notifications if we have a valid-looking token
        if (std.mem.startsWith(u8, self.token, "ghp_") or std.mem.startsWith(u8, self.token, "github_pat_")) {
            print("🔍 Detected valid GitHub token format\n", .{});
            print("🌐 Attempting to fetch real GitHub notifications...\n", .{});
            return self.fetchNotificationsReal() catch |err| {
                print("❌ Real API call failed: {}\n", .{err});
                print("📋 Falling back to mock data for demonstration\n", .{});
                return self.getMockNotifications();
            };
        } else {
            print("ℹ️  Using mock data (no valid GitHub token detected)\n", .{});
            print("💡 To use real notifications, set GITHUB_TOKEN environment variable\n", .{});
            return self.getMockNotifications();
        }
    }

    pub fn getNewNotifications(self: *GitHubClient) ![]GitHubNotification {
        // Fetch all notifications
        const all_notifications = try self.fetchNotifications();

        // Filter for new notifications (not seen before)
        var new_notifications = std.ArrayList(GitHubNotification).init(self.allocator);
        defer new_notifications.deinit();

        for (all_notifications) |notification| {
            // Check if this notification is new (not in our seen list)
            if (!self.last_seen_notifications.contains(notification.id)) {
                // Create a deep copy of the notification to avoid dangling pointers
                const new_notification = GitHubNotification{
                    .id = try self.allocator.dupe(u8, notification.id),
                    .title = try self.allocator.dupe(u8, notification.title),
                    .repository = try self.allocator.dupe(u8, notification.repository),
                    .reason = try self.allocator.dupe(u8, notification.reason),
                    .notification_type = try self.allocator.dupe(u8, notification.notification_type),
                    .url = try self.allocator.dupe(u8, notification.url),
                    .updated_at = try self.allocator.dupe(u8, notification.updated_at),
                    .unread = notification.unread,
                };

                try new_notifications.append(new_notification);

                // Mark this notification as seen (using the original ID)
                const id_copy = try self.allocator.dupe(u8, notification.id);
                try self.last_seen_notifications.put(id_copy, true);
            }
        }

        print("📬 Found {} new notifications out of {} total\n", .{ new_notifications.items.len, all_notifications.len });

        // Free the original notifications
        self.freeNotifications(all_notifications);

        // Return the new notifications with duplicated strings
        return try new_notifications.toOwnedSlice();
    }

    fn getMockNotifications(self: *GitHubClient) ![]GitHubNotification {
        // Mock data that simulates real GitHub notifications
        // This represents what you might actually see from the GitHub API
        const mock_notifications = [_]GitHubNotification{
            .{
                .id = "notification_123456789",
                .title = "New issue: Windows notification system integration",
                .repository = "ziglang/zig",
                .reason = "mention",
                .notification_type = "Issue",
                .url = "https://github.com/ziglang/zig/issues/17234",
                .updated_at = "2025-08-28T14:30:00Z",
                .unread = true,
            },
            .{
                .id = "notification_987654321",
                .title = "PR review requested: Add desktop notifications for Windows",
                .repository = "your-username/zig-notifications",
                .reason = "review_requested",
                .notification_type = "PullRequest",
                .url = "https://github.com/your-username/zig-notifications/pull/1",
                .updated_at = "2025-08-28T13:15:00Z",
                .unread = true,
            },
            .{
                .id = "notification_555666777",
                .title = "Zig 0.12.0 released with improved Windows support",
                .repository = "ziglang/zig",
                .reason = "subscribed",
                .notification_type = "Release",
                .url = "https://github.com/ziglang/zig/releases/tag/0.12.0",
                .updated_at = "2025-08-28T10:00:00Z",
                .unread = false,
            },
            .{
                .id = "notification_111222333",
                .title = "Discussion: Best practices for Windows desktop notifications",
                .repository = "microsoft/terminal",
                .reason = "subscribed",
                .notification_type = "Discussion",
                .url = "https://github.com/microsoft/terminal/discussions/12345",
                .updated_at = "2025-08-28T09:45:00Z",
                .unread = true,
            },
        };

        // Copy to heap-allocated memory
        const notifications = try self.allocator.alloc(GitHubNotification, mock_notifications.len);
        for (mock_notifications, 0..) |notification, i| {
            notifications[i] = GitHubNotification{
                .id = try self.allocator.dupe(u8, notification.id),
                .title = try self.allocator.dupe(u8, notification.title),
                .repository = try self.allocator.dupe(u8, notification.repository),
                .reason = try self.allocator.dupe(u8, notification.reason),
                .notification_type = try self.allocator.dupe(u8, notification.notification_type),
                .url = try self.allocator.dupe(u8, notification.url),
                .updated_at = try self.allocator.dupe(u8, notification.updated_at),
                .unread = notification.unread,
            };
        }

        return notifications;
    }

    pub fn freeNotifications(self: *GitHubClient, notifications: []GitHubNotification) void {
        for (notifications) |notification| {
            self.allocator.free(notification.id);
            self.allocator.free(notification.title);
            self.allocator.free(notification.repository);
            self.allocator.free(notification.reason);
            self.allocator.free(notification.notification_type);
            self.allocator.free(notification.url);
            self.allocator.free(notification.updated_at);
        }
        self.allocator.free(notifications);
    }

    // Real implementation that actually calls GitHub API
    pub fn fetchNotificationsReal(self: *GitHubClient) ![]GitHubNotification {
        print("🔍 Fetching real GitHub notifications from GitHub API...\n", .{});

        // Prepare the request
        var client = self.http_client;

        // Create URI for GitHub notifications API
        const uri = std.Uri.parse("https://api.github.com/notifications") catch |err| {
            print("❌ Failed to parse URI: {}\n", .{err});
            return error.InvalidUri;
        };

        // Add Authorization header
        var auth_header = std.ArrayList(u8).init(self.allocator);
        defer auth_header.deinit();
        try auth_header.writer().print("token {s}", .{self.token});

        // Create header list
        const header_list = &[_]std.http.Header{
            .{ .name = "Authorization", .value = auth_header.items },
            .{ .name = "User-Agent", .value = "ZigGitHubNotifications/1.0" },
            .{ .name = "Accept", .value = "application/vnd.github.v3+json" },
        };

        // Make the request with headers
        var server_header_buffer: [16 * 1024]u8 = undefined;
        var req = client.open(.GET, uri, .{
            .server_header_buffer = &server_header_buffer,
            .extra_headers = header_list,
        }) catch |err| {
            print("❌ Failed to open HTTP request: {}\n", .{err});
            return error.HttpRequestFailed;
        };
        defer req.deinit();

        // Send the request
        req.send() catch |err| {
            print("❌ Failed to send HTTP request: {}\n", .{err});
            return error.HttpRequestFailed;
        };

        // Wait for response
        req.wait() catch |err| {
            print("❌ Failed to receive HTTP response: {}\n", .{err});
            return error.HttpResponseFailed;
        };

        // Check status code
        const status = req.response.status;
        print("📡 GitHub API response status: {}\n", .{@intFromEnum(status)});

        if (status != .ok) {
            switch (status) {
                .unauthorized => {
                    print("❌ GitHub API Error 401: Invalid or missing token\n", .{});
                    return error.Unauthorized;
                },
                .forbidden => {
                    print("❌ GitHub API Error 403: Token lacks required permissions\n", .{});
                    return error.Forbidden;
                },
                .not_modified => {
                    print("ℹ️ No new notifications (304 Not Modified)\n", .{});
                    return try self.allocator.alloc(GitHubNotification, 0);
                },
                else => {
                    print("❌ GitHub API Error {}: Request failed\n", .{@intFromEnum(status)});
                    return error.ApiError;
                },
            }
        }

        // Read response body
        const response_body = req.reader().readAllAlloc(self.allocator, 10 * 1024 * 1024) catch |err| {
            print("❌ Failed to read response body: {}\n", .{err});
            return error.ResponseReadFailed;
        };
        defer self.allocator.free(response_body);

        print("✅ Received {} bytes from GitHub API\n", .{response_body.len});

        // Parse JSON response
        return self.parseNotifications(response_body) catch |err| {
            print("❌ Failed to parse GitHub API response: {}\n", .{err});
            return error.JsonParseFailed;
        };
    }

    fn parseNotifications(self: *GitHubClient, json_data: []const u8) ![]GitHubNotification {
        print("📋 Parsing GitHub API JSON response ({} bytes)...\n", .{json_data.len});

        // Parse the JSON response using std.json.parseFromSlice
        var parsed = std.json.parseFromSlice(std.json.Value, self.allocator, json_data, .{}) catch |err| {
            print("❌ JSON parse error: {}\n", .{err});
            return error.JsonParseError;
        };
        defer parsed.deinit();

        const root = parsed.value;
        if (root != .array) {
            print("❌ Expected JSON array, got: {}\n", .{root});
            return error.InvalidJsonFormat;
        }

        const notifications_array = root.array;
        print("📬 Found {} notifications in API response\n", .{notifications_array.items.len});

        // Allocate array for parsed notifications
        var notifications = try self.allocator.alloc(GitHubNotification, notifications_array.items.len);
        var parsed_count: usize = 0;

        // Parse each notification
        for (notifications_array.items) |item| {
            if (item != .object) continue;

            const obj = item.object;

            // Extract required fields with defaults
            const id = if (obj.get("id")) |id_val|
                switch (id_val) {
                    .string => |s| s,
                    else => "unknown",
                }
            else
                "unknown";

            const title = if (obj.get("subject")) |subject_obj|
                switch (subject_obj) {
                    .object => |subject_map| if (subject_map.get("title")) |title_val|
                        switch (title_val) {
                            .string => |s| s,
                            else => "No title",
                        }
                    else
                        "No title",
                    else => "No title",
                }
            else
                "No title";

            const repo_name = if (obj.get("repository")) |repo_obj|
                switch (repo_obj) {
                    .object => |repo_map| if (repo_map.get("full_name")) |name_val|
                        switch (name_val) {
                            .string => |s| s,
                            else => "unknown/repo",
                        }
                    else
                        "unknown/repo",
                    else => "unknown/repo",
                }
            else
                "unknown/repo";

            const notification_type = if (obj.get("subject")) |subject_obj|
                switch (subject_obj) {
                    .object => |subject_map| if (subject_map.get("type")) |type_val|
                        switch (type_val) {
                            .string => |s| s,
                            else => "Issue",
                        }
                    else
                        "Issue",
                    else => "Issue",
                }
            else
                "Issue";

            const reason = if (obj.get("reason")) |reason_val|
                switch (reason_val) {
                    .string => |s| s,
                    else => "subscribed",
                }
            else
                "subscribed";

            const updated_at = if (obj.get("updated_at")) |updated_val|
                switch (updated_val) {
                    .string => |s| s,
                    else => "unknown",
                }
            else
                "unknown";

            const unread = if (obj.get("unread")) |unread_val|
                switch (unread_val) {
                    .bool => |b| b,
                    else => true,
                }
            else
                true;

            const url = if (obj.get("subject")) |subject_obj|
                switch (subject_obj) {
                    .object => |subject_map| if (subject_map.get("url")) |url_val|
                        switch (url_val) {
                            .string => |s| s,
                            else => "https://github.com",
                        }
                    else
                        "https://github.com",
                    else => "https://github.com",
                }
            else
                "https://github.com";

            // Create notification struct
            notifications[parsed_count] = GitHubNotification{
                .id = try self.allocator.dupe(u8, id),
                .title = try self.allocator.dupe(u8, title),
                .repository = try self.allocator.dupe(u8, repo_name),
                .notification_type = try self.allocator.dupe(u8, notification_type),
                .reason = try self.allocator.dupe(u8, reason),
                .url = try self.allocator.dupe(u8, url),
                .updated_at = try self.allocator.dupe(u8, updated_at),
                .unread = unread,
            };

            parsed_count += 1;
        }

        // Resize array to actual parsed count
        if (parsed_count < notifications.len) {
            const final_notifications = try self.allocator.alloc(GitHubNotification, parsed_count);
            for (final_notifications, 0..) |*notif, i| {
                notif.* = notifications[i];
            }
            self.allocator.free(notifications);
            notifications = final_notifications;
        }

        print("✅ Successfully parsed {} GitHub notifications\n", .{parsed_count});
        return notifications;
    }
};

// Helper function to get notification icon based on type
pub fn getNotificationIcon(notification_type: []const u8) []const u8 {
    if (std.mem.eql(u8, notification_type, "Issue")) {
        return "🐛";
    } else if (std.mem.eql(u8, notification_type, "PullRequest")) {
        return "🔀";
    } else if (std.mem.eql(u8, notification_type, "Release")) {
        return "🚀";
    } else if (std.mem.eql(u8, notification_type, "Discussion")) {
        return "💬";
    } else {
        return "📢";
    }
}

// Helper function to get reason description
pub fn getReasonDescription(reason: []const u8) []const u8 {
    if (std.mem.eql(u8, reason, "mention")) {
        return "You were mentioned";
    } else if (std.mem.eql(u8, reason, "review_requested")) {
        return "Review requested";
    } else if (std.mem.eql(u8, reason, "assign")) {
        return "You were assigned";
    } else if (std.mem.eql(u8, reason, "subscribed")) {
        return "You're subscribed";
    } else if (std.mem.eql(u8, reason, "comment")) {
        return "New comment";
    } else {
        return "Activity";
    }
}
