#!/usr/bin/env pwsh

Write-Host "Building Zig Notifications Project..." -ForegroundColor Green
zig build

Write-Host "`nRunning main demo..." -ForegroundColor Yellow
zig build run

Write-Host "`nRunning examples..." -ForegroundColor Yellow
zig build examples

Write-Host "`nRunning GitHub notifications checker..." -ForegroundColor Yellow
zig build github

Write-Host "`nRunning tests..." -ForegroundColor Yellow
zig build test

Write-Host "`nAll done! Check above for any Windows system tray notifications." -ForegroundColor Green
Write-Host "To use real GitHub notifications, set GITHUB_TOKEN environment variable." -ForegroundColor Cyan
Read-Host "Press Enter to continue"
