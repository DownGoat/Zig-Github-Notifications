@echo off
echo Building Zig Notifications Project...
zig build

echo.
echo Running main demo...
zig build run

echo.
echo Running examples...
zig build examples

echo.
echo Running GitHub notifications checker...
zig build github

echo.
echo Running tests...
zig build test

echo.
echo All done! Check the output above for any Windows system tray notifications.
echo To use real GitHub notifications, set GITHUB_TOKEN environment variable.
pause
