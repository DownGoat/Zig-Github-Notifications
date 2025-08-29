const std = @import("std");
const windows = std.os.windows;

// Windows Runtime and COM types
const HRESULT = windows.HRESULT;
const GUID = windows.GUID;
const HSTRING = ?*anyopaque;
const IUnknown = ?*anyopaque;

// Windows API functions
extern "ole32" fn CoInitializeEx(pvReserved: ?*anyopaque, dwCoInit: u32) callconv(windows.WINAPI) HRESULT;
extern "ole32" fn CoUninitialize() callconv(windows.WINAPI) void;
extern "runtimeobject" fn WindowsCreateString(sourceString: [*:0]const u16, length: u32, string: *HSTRING) callconv(windows.WINAPI) HRESULT;
extern "runtimeobject" fn WindowsDeleteString(string: HSTRING) callconv(windows.WINAPI) HRESULT;
extern "runtimeobject" fn RoGetActivationFactory(activatableClassId: HSTRING, iid: *const GUID, factory: *IUnknown) callconv(windows.WINAPI) HRESULT;

// COM constants
const COINIT_APARTMENTTHREADED: u32 = 0x2;
const S_OK: HRESULT = 0;

// Toast Notification Manager GUIDs
const IID_IToastNotificationManagerStatics = GUID{
    .Data1 = 0x50ac103f,
    .Data2 = 0xd235,
    .Data3 = 0x4598,
    .Data4 = [8]u8{ 0xbb, 0x07, 0x4e, 0xe4, 0x50, 0x6b, 0x2d, 0x5f },
};

const IID_IToastNotifier = GUID{
    .Data1 = 0x75927b93,
    .Data2 = 0x03f3,
    .Data3 = 0x41ec,
    .Data4 = [8]u8{ 0x91, 0xd9, 0x95, 0x14, 0x73, 0x52, 0xd3, 0x3c },
};

const IID_IToastNotificationFactory = GUID{
    .Data1 = 0x04124b20,
    .Data2 = 0x82c6,
    .Data3 = 0x4229,
    .Data4 = [8]u8{ 0xb1, 0x09, 0xfd, 0x9e, 0xd4, 0x66, 0x2b, 0x53 },
};

const IID_IXmlDocument = GUID{
    .Data1 = 0xf7f3a506,
    .Data2 = 0x1e87,
    .Data3 = 0x42d6,
    .Data4 = [8]u8{ 0xbc, 0xfb, 0xb8, 0xc8, 0x09, 0xfa, 0x59, 0x94 },
};

pub const ToastError = error{
    ComInitFailed,
    CreateStringFailed,
    ActivationFactoryFailed,
    CreateNotifierFailed,
    CreateNotificationFailed,
    ShowNotificationFailed,
    OutOfMemory,
};

fn utf8ToWide(allocator: std.mem.Allocator, utf8: []const u8) ![:0]u16 {
    const wide_len = try std.unicode.calcUtf16LeLen(utf8);
    const wide = try allocator.allocSentinel(u16, wide_len, 0);
    _ = try std.unicode.utf8ToUtf16Le(wide, utf8);
    return wide;
}

fn createHString(allocator: std.mem.Allocator, text: []const u8) !HSTRING {
    const wide_text = try utf8ToWide(allocator, text);
    defer allocator.free(wide_text);

    var hstring: HSTRING = null;
    const hr = WindowsCreateString(wide_text.ptr, @intCast(wide_text.len), &hstring);
    if (hr != S_OK) {
        return ToastError.CreateStringFailed;
    }
    return hstring;
}

pub fn sendToastNotification(allocator: std.mem.Allocator, title: []const u8, message: []const u8) ToastError!void {
    // Initialize COM
    const hr_init = CoInitializeEx(null, COINIT_APARTMENTTHREADED);
    if (hr_init != S_OK and hr_init != 0x80010106) { // S_FALSE means already initialized
        return ToastError.ComInitFailed;
    }
    defer CoUninitialize();

    // Create XML content for the toast
    const xml_content = try std.fmt.allocPrint(allocator,
        \\<toast>
        \\  <visual>
        \\    <binding template="ToastGeneric">
        \\      <text>{s}</text>
        \\      <text>{s}</text>
        \\    </binding>
        \\  </visual>
        \\</toast>
    , .{ title, message });
    defer allocator.free(xml_content);

    // Create HSTRING for class name
    const class_name = try createHString(allocator, "Windows.UI.Notifications.ToastNotificationManager");
    defer _ = WindowsDeleteString(class_name);

    // Get activation factory
    var factory: IUnknown = null;
    const hr = RoGetActivationFactory(class_name, &IID_IToastNotificationManagerStatics, &factory);
    if (hr != S_OK) {
        return ToastError.ActivationFactoryFailed;
    }

    // For now, fall back to console notification if toast fails
    // This is a simplified implementation - full toast notifications require more complex WinRT interop
    std.debug.print("🔔 TOAST NOTIFICATION\n", .{});
    std.debug.print("Title: {s}\n", .{title});
    std.debug.print("Message: {s}\n", .{message});
    std.debug.print("(This would appear as a Windows toast notification)\n", .{});
    std.debug.print("─────────────────────────────\n", .{});
}

// Simplified fallback using Windows notification area
pub fn sendTrayNotification(allocator: std.mem.Allocator, title: []const u8, message: []const u8) ToastError!void {
    // This is a placeholder for system tray notifications
    // Implementation would use Shell_NotifyIcon with NIF_INFO
    _ = allocator;

    std.debug.print("🔔 SYSTEM TRAY NOTIFICATION\n", .{});
    std.debug.print("Title: {s}\n", .{title});
    std.debug.print("Message: {s}\n", .{message});
    std.debug.print("(This would appear as a system tray balloon)\n", .{});
    std.debug.print("─────────────────────────────\n", .{});
}
