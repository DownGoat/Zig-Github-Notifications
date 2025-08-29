# GitHub Notifications Background Service

## Overview
The GitHub Notifications Background Service monitors your GitHub notifications every minute and sends desktop notifications only for **new** notifications that haven't been seen before.

## Features
- ✅ **Real GitHub API Integration**: Uses your GitHub token to fetch actual notifications
- ✅ **Background Monitoring**: Runs continuously, checking every 60 seconds
- ✅ **Smart Filtering**: Only shows notifications for new/unseen items
- ✅ **Desktop Notifications**: Uses Windows system tray notifications
- ✅ **Memory Tracking**: Remembers which notifications you've already seen
- ✅ **Error Handling**: Gracefully handles API errors and network issues

## Usage

### 1. Set up your GitHub Token
First, create a GitHub Personal Access Token:
1. Go to GitHub Settings → Developer settings → Personal access tokens
2. Generate a new token with `notifications` scope
3. Copy the token (starts with `ghp_` or `github_pat_`)

### 2. Run the Background Service
```powershell
# Set your GitHub token
$env:GITHUB_TOKEN="ghp_your_actual_token_here"

# Start the background service
.\zig-out\bin\github-service.exe
```

### 3. Build Commands
```powershell
# Build all executables
zig build

# Run the one-time checker
zig build github

# Run the background service
zig build service
```

## How It Works

### First Run
- ✅ Fetches all current notifications from GitHub
- ✅ Marks them all as "seen" in memory
- ✅ Shows desktop notifications for all current notifications
- ✅ Starts the 60-second monitoring loop

### Subsequent Checks
- ✅ Fetches current notifications from GitHub API
- ✅ Compares with previously seen notifications
- ✅ Only shows desktop notifications for **new** notifications
- ✅ Updates the "seen" list with any new notification IDs

### Desktop Notifications
Each new GitHub notification triggers a Windows system tray notification with:
- **Title**: `GitHub: repository-name`
- **Message**: `Type: notification-title\nReason`
- **Summary**: If more than 3 new notifications, shows a summary count

## Stopping the Service
- Press `Ctrl+C` in the terminal window
- The service will stop gracefully

## Example Output
```
GitHub Notifications Background Service
======================================

🚀 Starting background service...
⏰ Checking for new GitHub notifications every 60 seconds
🔔 Desktop notifications will appear for new items only
📝 Press Ctrl+C to stop the service

🔍 Check #1 at timestamp 1756385157
🔍 Detected valid GitHub token format
🌐 Attempting to fetch real GitHub notifications...
📡 GitHub API response status: 200
📬 Found 2 new notifications out of 5 total
🔔 2 new notification(s) found!
   1. 🐛 Issue New bug report in main repository
      Repository: your-org/your-repo
      Reason: You were mentioned
   2. 🔀 PullRequest Code review requested
      Repository: your-org/another-repo
      Reason: Review requested
⏳ Waiting 60 seconds until next check...

🔍 Check #2 at timestamp 1756385217
✅ No new notifications
⏳ Waiting 60 seconds until next check...
```

## Error Handling
- **Invalid Token**: Falls back to mock data for demonstration
- **Network Issues**: Shows error notification and continues monitoring
- **API Rate Limits**: Handles GitHub API rate limiting gracefully
- **JSON Parse Errors**: Logs errors and continues operation

## Files
- `github-service.exe` - Background service executable
- `github-checker.exe` - One-time notification checker
- `zig-notifications.exe` - Original demo application
