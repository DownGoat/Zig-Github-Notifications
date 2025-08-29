# GitHub Notifications Configuration

## Setup Instructions

1. **Get a GitHub Personal Access Token:**
   - Go to GitHub.com → Settings → Developer settings → Personal access tokens → Tokens (classic)
   - Click "Generate new token (classic)"
   - Select scopes: `notifications` (required)
   - Copy the generated token

2. **Set Environment Variable:**
   ```powershell
   # Windows PowerShell
   $env:GITHUB_TOKEN = "your_token_here"
   
   # Windows Command Prompt
   set GITHUB_TOKEN=your_token_here
   
   # Or add to system environment variables permanently
   ```

3. **Run the GitHub Checker:**
   ```powershell
   zig build github
   ```

## Usage Examples

### Basic Check
```powershell
# Check notifications once
zig build github
```

### With Custom Token
```powershell
# Set token for current session
$env:GITHUB_TOKEN = "ghp_your_token_here"
zig build github
```

### Monitor Mode (Future Feature)
```powershell
# This would check every 5 minutes (not implemented yet)
zig build github -- --monitor --interval 300
```

## GitHub API Endpoints Used

- `GET /notifications` - List notifications for the authenticated user
- Requires authentication with `notifications` scope

## Sample Output

```
GitHub Notifications Checker
===========================

Fetching GitHub notifications...
Found 3 notifications:

1. 🐛 Issue: Fix memory leak in parser
   Repository: ziglang/zig
   Reason: You were mentioned
   Updated: 2025-08-28T10:30:00Z
   Unread: true
   URL: https://github.com/ziglang/zig/issues/12345

2. 🔀 PullRequest: Add Windows notifications
   Repository: your-username/zig-notifications
   Reason: Review requested
   Updated: 2025-08-28T09:15:00Z
   Unread: true
   URL: https://github.com/your-username/zig-notifications/pull/42

📢 GitHub Summary: You have 2 unread notifications
```

## Troubleshooting

### "No GitHub token found!"
- Make sure you've set the `GITHUB_TOKEN` environment variable
- Verify the token has `notifications` scope

### "Failed to fetch GitHub notifications: NetworkError"
- Check your internet connection
- Verify the GitHub token is valid
- Check if you've hit the GitHub API rate limit

### "Failed to send desktop notification"
- This is normal on systems without proper Windows notification support
- The console output will still show all notifications

## Security Notes

- Keep your GitHub token secure
- Don't commit tokens to version control
- Tokens can be revoked at any time from GitHub settings
- Use environment variables or secure config files only
