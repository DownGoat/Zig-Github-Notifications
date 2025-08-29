const std = @import("std");
const windows = std.os.windows;

// Windows Shell API for system tray notifications
extern "shell32" fn Shell_NotifyIconW(dwMessage: u32, lpData: *NOTIFYICONDATAW) callconv(windows.WINAPI) windows.BOOL;

// System tray notification constants
const NIM_ADD: u32 = 0x00000000;
const NIM_MODIFY: u32 = 0x00000001;
const NIM_DELETE: u32 = 0x00000002;
const NIM_SETVERSION: u32 = 0x00000004;

const NIF_MESSAGE: u32 = 0x00000001;
const NIF_ICON: u32 = 0x00000002;
const NIF_TIP: u32 = 0x00000004;
const NIF_STATE: u32 = 0x00000008;
const NIF_INFO: u32 = 0x00000010;

const NIIF_NONE: u32 = 0x00000000;
const NIIF_INFO: u32 = 0x00000001;
const NIIF_WARNING: u32 = 0x00000002;
const NIIF_ERROR: u32 = 0x00000003;

// NOTIFYICONDATA structure
const NOTIFYICONDATAW = extern struct {
    cbSize: u32,
    hWnd: ?windows.HWND,
    uID: u32,
    uFlags: u32,
    uCallbackMessage: u32,
    hIcon: ?windows.HICON,
    szTip: [128]u16,
    dwState: u32,
    dwStateMask: u32,
    szInfo: [256]u16,
    uVersion: u32, // Also used for uTimeout
    szInfoTitle: [64]u16,
    dwInfoFlags: u32,
    guidItem: windows.GUID,
    hBalloonIcon: ?windows.HICON,
};

pub const TrayNotificationError = error{
    NotificationFailed,
    OutOfMemory,
};

fn utf8ToWide(allocator: std.mem.Allocator, utf8: []const u8) ![:0]u16 {
    const wide_len = try std.unicode.calcUtf16LeLen(utf8);
    const wide = try allocator.allocSentinel(u16, wide_len, 0);
    _ = try std.unicode.utf8ToUtf16Le(wide, utf8);
    return wide;
}

fn copyToFixedArray(comptime T: type, comptime size: usize, source: []const T) [size]T {
    var result: [size]T = [_]T{0} ** size;
    const copy_len = @min(source.len, size - 1); // Leave space for null terminator
    @memcpy(result[0..copy_len], source[0..copy_len]);
    return result;
}

pub fn sendSystemTrayNotification(allocator: std.mem.Allocator, title: []const u8, message: []const u8) TrayNotificationError!void {
    // Convert UTF-8 to UTF-16
    const title_wide = utf8ToWide(allocator, title) catch return TrayNotificationError.OutOfMemory;
    defer allocator.free(title_wide);

    const message_wide = utf8ToWide(allocator, message) catch return TrayNotificationError.OutOfMemory;
    defer allocator.free(message_wide);

    // Create notification data
    var nid = NOTIFYICONDATAW{
        .cbSize = @sizeOf(NOTIFYICONDATAW),
        .hWnd = null,
        .uID = 1,
        .uFlags = NIF_INFO,
        .uCallbackMessage = 0,
        .hIcon = null,
        .szTip = [_]u16{0} ** 128,
        .dwState = 0,
        .dwStateMask = 0,
        .szInfo = copyToFixedArray(u16, 256, message_wide),
        .uVersion = 5000, // 5 second timeout
        .szInfoTitle = copyToFixedArray(u16, 64, title_wide),
        .dwInfoFlags = NIIF_INFO,
        .guidItem = std.mem.zeroes(windows.GUID),
        .hBalloonIcon = null,
    };

    // Show the notification
    const result = Shell_NotifyIconW(NIM_ADD, &nid);
    if (result == 0) {
        return TrayNotificationError.NotificationFailed;
    }

    // Clean up - remove the icon after showing
    _ = Shell_NotifyIconW(NIM_DELETE, &nid);
}

// Fallback: Simple console notification that looks like a desktop notification
pub fn sendConsoleDesktopNotification(title: []const u8, message: []const u8) void {
    std.debug.print("\n┌─────────────────────────────────────────┐\n", .{});
    std.debug.print("│ 🔔 DESKTOP NOTIFICATION                │\n", .{});
    std.debug.print("├─────────────────────────────────────────┤\n", .{});
    std.debug.print("│ {s:<39} │\n", .{title});
    std.debug.print("│                                         │\n", .{});

    // Split message into lines if it's too long
    var lines = std.mem.splitScalar(u8, message, '\n');
    while (lines.next()) |line| {
        if (line.len <= 39) {
            std.debug.print("│ {s:<39} │\n", .{line});
        } else {
            // Simple word wrapping
            var i: usize = 0;
            while (i < line.len) {
                const end = @min(i + 39, line.len);
                const segment = line[i..end];
                std.debug.print("│ {s:<39} │\n", .{segment});
                i = end;
            }
        }
    }

    std.debug.print("└─────────────────────────────────────────┘\n", .{});
    std.debug.print("(This simulates a desktop notification)\n\n", .{});
}
