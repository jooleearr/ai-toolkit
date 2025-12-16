# Integration Scripts

Shell scripts for integrating Jira, GitHub, and Slack with Claude Code workflows.

## Overview

These scripts enable Claude Code to interact with your development tools:
- **Jira**: Fetch tickets, update status, manage blocked reasons
- **GitHub**: Get PR information, review status
- **Slack**: Post notifications to team channels

## Quick Start

### 1. Install Dependencies

```bash
brew install jq  # Required for JSON parsing
```

Optional but recommended:
```bash
brew install gh  # GitHub CLI for PR creation
```

### 2. Install Scripts

```bash
cd /Users/juliahide/projects/ai-toolkit/bin
chmod +x *.sh
mkdir -p ~/bin
ln -sf "$(pwd)"/*.sh ~/bin/
```

Add `~/bin` to your PATH (if not already). Add to `~/.zshrc`:
```bash
export PATH="$HOME/bin:$PATH"
```

Then reload:
```bash
source ~/.zshrc
```

### 3. Configure Credentials

```bash
# Copy template
cp /Users/juliahide/projects/ai-toolkit/templates/ai-toolkit-env.template ~/.ai-toolkit-env

# Secure the file
chmod 600 ~/.ai-toolkit-env

# Edit with your credentials
nano ~/.ai-toolkit-env  # or use your preferred editor
```

### 4. Find Jira Custom Field IDs

Your Jira instance has unique field IDs. Find them using:

```bash
# Find acceptance criteria field
jira-find-fields.sh "acceptance"

# Find blocked reasons field
jira-find-fields.sh "blocked"

# See all custom fields
jira-find-fields.sh "customfield"
```

Update `~/.ai-toolkit-env` with the correct field IDs:
```bash
export JIRA_FIELD_ACCEPTANCE_CRITERIA="customfield_XXXXX"
export JIRA_FIELD_BLOCKED_REASONS="customfield_YYYYY"
```

### 5. Verify Installation

```bash
# Test each script's help
jira-get-ticket.sh --help
jira-update-status.sh --help
slack-post-message.sh --help

# Test with a real ticket
jira-get-ticket.sh YOUR-TICKET-KEY
```

## Available Scripts

### Core Scripts

| Script | Purpose | Usage Example |
|--------|---------|---------------|
| `jira-get-ticket.sh` | Fetch ticket details | `jira-get-ticket.sh PROJ-123` |
| `jira-update-status.sh` | Update ticket status | `jira-update-status.sh PROJ-123 "In Progress"` |
| `slack-post-message.sh` | Post to Slack | `slack-post-message.sh "PR ready"` |
| `github-pr-info.sh` | Get PR details | `github-pr-info.sh 456` |

### Helper Scripts

| Script | Purpose | Usage Example |
|--------|---------|---------------|
| `jira-find-fields.sh` | Find custom field IDs | `jira-find-fields.sh "acceptance"` |
| `_integration-common.sh` | Shared utilities | (sourced by other scripts) |

## Configuration Reference

### Required Environment Variables

**Jira:**
- `JIRA_BASE_URL` - Your Jira instance URL
- `JIRA_EMAIL` - Your Jira email address
- `JIRA_TOKEN` - Jira API token
- `JIRA_FIELD_ACCEPTANCE_CRITERIA` - Acceptance criteria field ID
- `JIRA_FIELD_BLOCKED_REASONS` - Blocked reasons field ID

**GitHub:**
- `GITHUB_TOKEN` - Personal access token
- `GITHUB_REPO_OWNER` - Repository owner/org
- `GITHUB_REPO_NAME` - Repository name

**Slack:**
- `SLACK_TOKEN` - Bot token (starts with `xoxb-`)
- `SLACK_CHANNEL` - Default channel name (without `#`)

### Optional Variables

- `SLACK_USER_ID` - Your Slack user ID for mentions
- `JIRA_BLOCKED_REASON` - Default blocked reason text
- `DEBUG_MODE` - Set to `"true"` for verbose logging

## Obtaining API Credentials

### Jira API Token

1. Log into Jira
2. Go to **Account Settings** → **Security**
3. Select **Create and manage API tokens**
4. Click **Create API token**
5. Copy the token immediately (it won't be shown again)

### GitHub Personal Access Token

1. Go to **GitHub** → **Settings** → **Developer Settings**
2. Select **Personal Access Tokens** → **Tokens (classic)**
3. Click **Generate new token**
4. Select scopes: `repo`, `read:org`
5. Generate and copy the token immediately

### Slack Bot Token

1. Go to [https://api.slack.com/apps](https://api.slack.com/apps)
2. Create a new app or select existing
3. Navigate to **OAuth & Permissions**
4. Add bot token scopes: `chat:write`, `channels:read`
5. Install app to workspace
6. Copy **Bot User OAuth Token** (starts with `xoxb-`)

## Usage Examples

### Fetch Ticket Details

```bash
# Basic usage
jira-get-ticket.sh PROJ-123

# Format with jq
jira-get-ticket.sh PROJ-123 | jq '.summary'

# Get subtasks
jira-get-ticket.sh PROJ-123 | jq '.subtasks[]'
```

### Update Ticket Status

```bash
# Move to In Progress
jira-update-status.sh PROJ-123 "In Progress"

# Mark as blocked for code review
jira-update-status.sh PROJ-123 "Ready" --blocked "Internal - Code Review"

# Close ticket and clear blocked reason
jira-update-status.sh PROJ-123 "Closed" --clear-blocked
```

### Post Slack Message

```bash
# Simple message
slack-post-message.sh "PR ready for review"

# With PR link
slack-post-message.sh "PR ready" \
  --pr-url "https://github.com/org/repo/pull/123"

# With both PR and ticket
slack-post-message.sh "Authentication feature ready" \
  --pr-url "https://github.com/org/repo/pull/123" \
  --ticket "PROJ-456"

# Override channel
slack-post-message.sh "Urgent fix deployed" \
  --channel "incidents"
```

### Get GitHub PR Info

```bash
# Basic usage
github-pr-info.sh 123

# Check merge status
github-pr-info.sh 123 | jq '.state'

# Count approvals
github-pr-info.sh 123 | jq '.reviews.approved'
```

## Troubleshooting

### "command not found"

**Problem**: Script not found when running command

**Solutions**:
```bash
# Check if scripts are executable
ls -l ~/bin/*.sh

# Check if ~/bin is in PATH
echo $PATH | grep "$HOME/bin"

# Reload shell configuration
source ~/.zshrc
```

### "Configuration file not found"

**Problem**: `~/.ai-toolkit-env` doesn't exist

**Solution**:
```bash
# Copy template and edit
cp templates/ai-toolkit-env.template ~/.ai-toolkit-env
chmod 600 ~/.ai-toolkit-env
nano ~/.ai-toolkit-env
```

### "Failed to fetch ticket" or API errors

**Problem**: API authentication failing

**Solutions**:
```bash
# Verify credentials in config
cat ~/.ai-toolkit-env | grep -E "(TOKEN|EMAIL|URL)"

# Test Jira URL
curl -I https://your-company.atlassian.net

# Check token hasn't expired
# Tokens can be revoked - generate a new one if needed
```

### "jq: command not found"

**Problem**: JSON parser not installed

**Solution**:
```bash
brew install jq
```

### Wrong custom field IDs

**Problem**: Fields not showing in output or errors about fields

**Solution**:
```bash
# Find the correct field IDs
jira-find-fields.sh "acceptance"
jira-find-fields.sh "blocked"

# Update ~/.ai-toolkit-env with the correct customfield_XXXXX values
```

## Security Best Practices

1. **Never commit** `~/.ai-toolkit-env` to version control
2. Use file permissions `600` for credential files:
   ```bash
   chmod 600 ~/.ai-toolkit-env
   ```
3. Regularly rotate API tokens
4. Review token scopes - use minimum necessary permissions
5. Use different tokens for different projects if needed

## Integration with Claude Code

These scripts are designed to be called by Claude Code via the Bash tool. See the [workflows documentation](../workflows/README.md) for examples of how to use them in AI-assisted development workflows.

**Example workflow usage:**
```
@workflows/start-work-on-ticket.md I'm starting work on PROJ-123
```

Claude Code will execute the scripts, parse the JSON output, and present formatted information to you.

## Script Architecture

All scripts follow these patterns:
- **Portable**: `#!/usr/bin/env bash` shebang
- **Strict mode**: `set -euo pipefail`
- **Help text**: `-h` or `--help` flag
- **JSON output**: Structured data for machine parsing
- **Error handling**: Exit codes and stderr for errors
- **Debug mode**: Verbose logging with `DEBUG_MODE=true`

## Getting Help

For each script, run with `--help` to see detailed usage:
```bash
jira-get-ticket.sh --help
jira-update-status.sh --help
slack-post-message.sh --help
github-pr-info.sh --help
jira-find-fields.sh --help
```

For workflow guidance, see [`../workflows/README.md`](../workflows/README.md)
