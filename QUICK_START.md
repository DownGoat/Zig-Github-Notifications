# Quick Start: Check Your GitHub Notifications

## 🚀 **To check YOUR actual GitHub notifications:**

### 1. Get Your GitHub Token
1. Go to https://github.com/settings/tokens
2. Click "Generate new token (classic)"
3. Give it a name: "Zig Notifications"
4. Select scope: ☑️ `notifications`
5. Click "Generate token"
6. **Copy the token** (starts with `ghp_`)

### 2. Set the Token and Run
```powershell
# Replace with your actual token
$env:GITHUB_TOKEN = "ghp_your_actual_token_here"

# Check your notifications
zig build github
```

## 💡 **What You'll See:**

- **Real notifications** from repositories you're watching
- **Desktop notifications** for unread items
- **Full details**: repository, reason, links, timestamps
- **Smart filtering**: only unread notifications trigger desktop alerts

## 🔧 **Token Scopes Needed:**
- ✅ `notifications` (required)
- ❌ No other scopes needed

## 🛡️ **Security:**
- Keep your token private
- Don't commit it to git
- You can revoke it anytime from GitHub settings

## 📱 **Sample Output:**
```
GitHub Notifications Checker
===========================

Fetching GitHub notifications...
Attempting to fetch real GitHub notifications...
Making request to GitHub API...
Token: ghp_your_to...

Found 3 notifications:

1. 🐛 Issue New issue: Bug in notifications
   Repository: your-repo/project
   Reason: You were mentioned
   Unread: true
   
[Desktop notification appears]

📢 GitHub Summary: You have 2 unread notifications
```

## ⚡ **Try it now:**
```powershell
# Set your real GitHub token
$env:GITHUB_TOKEN = "ghp_YOUR_ACTUAL_TOKEN_HERE"

# Run the checker
zig build github
```

That's it! You'll see your actual GitHub notifications both in the console and as Windows desktop notifications.
