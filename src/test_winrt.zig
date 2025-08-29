const std = @import("std");
const windows = std.os.windows;

// Test if we can import Windows Runtime APIs without runtimeobject
extern "ole32" fn CoInitializeEx(pvReserved: ?*anyopaque, dwCoInit: windows.DWORD) windows.HRESULT;
extern "ole32" fn CoUninitialize() void;

// Declare Windows Runtime functions using different library names
extern "kernel32" fn RoInitialize(initType: u32) callconv(windows.WINAPI) windows.HRESULT;
extern "kernel32" fn RoUninitialize() callconv(windows.WINAPI) void;

pub fn main() !void {
    std.debug.print("Testing Windows Runtime availability...\n", .{});

    // Try to initialize COM first
    const hr_com = CoInitializeEx(null, 0);
    std.debug.print("COM initialization result: 0x{X}\n", .{hr_com});

    // Try to initialize Windows Runtime
    const hr_winrt = RoInitialize(1); // RO_INIT_SINGLETHREADED
    std.debug.print("WinRT initialization result: 0x{X}\n", .{hr_winrt});

    if (hr_winrt == 0) {
        std.debug.print("✅ Windows Runtime is available!\n", .{});
        RoUninitialize();
    } else {
        std.debug.print("❌ Windows Runtime not available (error: 0x{X})\n", .{hr_winrt});
    }

    CoUninitialize();
}
