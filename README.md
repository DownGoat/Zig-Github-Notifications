# Zig Windows Desktop Notifications

A Zig project that demonstrates how to send desktop notifications on Windows. This project includes examples for both simple notifications and GitHub-style notifications.

## Features

- ✅ Console notifications (cross-platform)
- ✅ Windows System Tray notifications (balloon tips)
- ✅ Enhanced console notification display
- ✅ GitHub API integration for checking notifications
- ✅ GitHub-style notification formatting
- ✅ Error handling and memory management
- 🚧 Real-time GitHub notification monitoring (planned)

## Requirements

- Zig 0.11.0 or later
- Windows 10/11 (for native notifications)
- Visual C++ runtime libraries

## Quick Start

### Option 1: Run the demo scripts
```powershell
# Windows Batch
.\run_demo.bat

# PowerShell
.\run_demo.ps1
```

### Option 2: Manual commands
```powershell
# Build the project
zig build

# Run the main demo
zig build run

# Run examples
zig build examples

# Check GitHub notifications
zig build github

# Run tests
zig build test
```

### Option 3: GitHub Integration
```powershell
# Set your GitHub token (see GITHUB_SETUP.md for details)
$env:GITHUB_TOKEN = "your_github_token_here"

# Check your GitHub notifications
zig build github
```

## Usage

### Basic Notification

```zig
const std = @import("std");
const notifications = @import("main.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Send a simple notification
    try notifications.sendNotification(allocator, "Title", "Message");
}
```

### GitHub Notification

```zig
const notification = notifications.GitHubNotification{
    .title = "New Issue",
    .repository = "user/repo",
    .action = "Issue opened",
    .url = "https://github.com/user/repo/issues/123",
};

try notification.send(allocator);
```

### Console Notification (for testing)

```zig
notifications.sendConsoleNotification("Title", "Message");
```

## Project Structure

```
├── build.zig              # Build configuration
├── src/
│   ├── main.zig           # Main application code
│   ├── tray.zig           # System tray notifications
│   ├── github.zig         # GitHub API integration
│   ├── github_checker.zig # GitHub notification checker app
│   ├── examples.zig       # Usage examples
│   └── config.zig         # Configuration structures
├── README.md              # This file
├── GITHUB_SETUP.md        # GitHub API setup instructions
├── run_demo.bat           # Windows demo script
└── run_demo.ps1           # PowerShell demo script
```

## Implementation Details

### Current Implementation

The project currently implements:

1. **Console Notifications**: Cross-platform text-based notifications for development and testing
2. **Windows MessageBox**: Simple Windows dialog-based notifications using `MessageBoxW`
3. **GitHub Integration Ready**: Structured notification types for GitHub events

### Planned Features

1. **Windows Toast Notifications**: Native Windows 10/11 toast notifications using WinRT APIs
2. **Notification Icons**: Custom icons for different notification types
3. **Action Buttons**: Interactive notifications with callback actions
4. **Sound Support**: Custom notification sounds

### Windows Toast Implementation (Future)

The project includes the foundation for Windows Toast notifications using:

- Windows Runtime (WinRT) APIs
- COM interop through Zig's Windows bindings
- Toast Notification Manager for modern Windows notifications

## Error Handling

The project includes comprehensive error handling:

```zig
pub const NotificationError = error{
    ComInitFailed,
    CreateInstanceFailed,
    CreateStringFailed,
    NotificationFailed,
    OutOfMemory,
};
```

## Dependencies

### System Libraries

- `ole32.lib` - COM support
- `oleaut32.lib` - COM automation
- `runtimeobject.lib` - Windows Runtime support

### Zig Standard Library

- `std.os.windows` - Windows API bindings
- `std.unicode` - UTF-8 to UTF-16 conversion
- `std.heap` - Memory management

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass: `zig build test`
5. Submit a pull request

## License

This project is provided as an example and learning resource. Feel free to use and modify as needed.

## Troubleshooting

### Common Issues

1. **COM Initialization Failed**: Make sure you're running on Windows with proper permissions
2. **Missing Libraries**: Ensure Visual C++ redistributables are installed
3. **Build Errors**: Verify you're using Zig 0.11.0 or later

### Debug Mode

Run with debug information:

```powershell
zig build -Doptimize=Debug run
```

## Examples

The main function includes several demonstration examples:

1. Simple console notification
2. GitHub-style notification formatting
3. Windows MessageBox notification attempt

Run the project to see all examples in action!
