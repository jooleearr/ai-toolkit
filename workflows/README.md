# Workflows

AI-assisted workflows that integrate with Jira, GitHub, and Slack. These workflows guide Claude Code through common development tasks by combining shell scripts with structured processes.

## Available Workflows

| Workflow | Purpose | Scripts Used |
|----------|---------|--------------|
| [Start Work on Ticket](start-work-on-ticket.md) | Fetch ticket details and move to In Progress | `jira-get-ticket.sh`, `jira-update-status.sh` |
| [Create PR and Notify](create-pr-and-notify.md) | Create PR, set ticket blocked, notify team | `jira-update-status.sh`, `slack-post-message.sh` |
| [Complete Ticket](complete-ticket.md) | Merge PR and close ticket | `jira-update-status.sh`, `github-pr-info.sh` |
| [Quick Ticket Lookup](quick-ticket-lookup.md) | Fetch and display ticket information | `jira-get-ticket.sh` |

## Prerequisites

### 1. Scripts Installation

Ensure integration scripts are installed and accessible:

```bash
# Install scripts
cd /Users/juliahide/projects/ai-toolkit/bin
chmod +x *.sh
mkdir -p ~/bin
ln -sf "$(pwd)"/*.sh ~/bin/

# Add to PATH if needed
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

### 2. Configuration

Create `~/.ai-toolkit-env` from template:

```bash
cp templates/ai-toolkit-env.template ~/.ai-toolkit-env
chmod 600 ~/.ai-toolkit-env
# Edit with your credentials
```

### 3. API Tokens

Obtain tokens for:
- **Jira**: Account Settings → Security → API Tokens
- **GitHub**: Settings → Developer → Personal Access Tokens (scopes: `repo`, `read:org`)
- **Slack**: https://api.slack.com/apps → OAuth & Permissions (scopes: `chat:write`, `channels:read`)

### 4. Custom Field IDs

Find your Jira custom field IDs:

```bash
jira-find-fields.sh "acceptance"  # Find acceptance criteria field
jira-find-fields.sh "blocked"     # Find blocked reasons field
```

Update `~/.ai-toolkit-env` with the correct IDs.

## Using Workflows with Claude Code

Reference workflows in your prompts to Claude Code using the `@` syntax:

**When working within ai-toolkit:**
```
@workflows/start-work-on-ticket.md I'm starting work on PROJ-123
```

**When ai-toolkit is cloned as `_ai` in another project:**
```
@_ai/workflows/start-work-on-ticket.md I'm starting work on PROJ-123
```

Claude Code will:
1. Read the workflow markdown
2. Replace template variables (e.g., `{{TICKET_KEY}}` → "PROJ-123")
3. Execute bash commands via the Bash tool
4. Parse JSON output from scripts
5. Present formatted information to you
6. Ask for confirmation before making changes
7. Suggest next steps

## Workflow Descriptions

### Start Work on Ticket

**Use when**: Beginning work on a new Jira ticket

**What it does**:
1. Fetches comprehensive ticket details from Jira
2. Displays summary, description, acceptance criteria, and subtasks
3. Moves ticket to "In Progress" (with confirmation)
4. Suggests creating a feature branch

**Example prompt**:
```
@workflows/start-work-on-ticket.md Start work on PROJ-456
```

### Create PR and Notify

**Use when**: Code is ready for review

**What it does**:
1. Verifies changes are committed and pushed
2. Guides PR creation using GitHub CLI
3. Updates Jira ticket with blocked reason "Internal - Code Review"
4. Posts notification to Slack with PR and ticket links

**Example prompt**:
```
@workflows/create-pr-and-notify.md Create PR for PROJ-456
```

### Complete Ticket

**Use when**: PR has been approved and merged

**What it does**:
1. Verifies PR is merged
2. Closes Jira ticket
3. Clears blocked reasons
4. Cleans up local and remote branches

**Example prompt**:
```
@workflows/complete-ticket.md Complete PROJ-456 after PR #789 merge
```

### Quick Ticket Lookup

**Use when**: You need to reference ticket information without making changes

**What it does**:
1. Fetches and displays ticket details
2. No status changes
3. Suggests next actions based on current status

**Example prompt**:
```
@workflows/quick-ticket-lookup.md Show me PROJ-123
```

## Common Development Flow

A typical development workflow using these tools:

```
1. @workflows/start-work-on-ticket.md Start work on PROJ-456
   ↓
2. [Write code, commit changes]
   ↓
3. @workflows/create-pr-and-notify.md Create PR for PROJ-456
   ↓
4. [Wait for review and approval]
   ↓
5. @workflows/complete-ticket.md Complete PROJ-456 after PR merge
```

## Tips and Best Practices

### For Effective Use

- **Be specific**: Include ticket keys in prompts
- **Confirm actions**: Review Claude Code's suggestions before confirming
- **Check output**: Verify ticket status and Slack messages
- **Iterate**: Workflows can be run multiple times if needed

### Customisation

Workflows are markdown files that you can customise:

1. Copy a workflow to your project
2. Adjust steps for your team's process
3. Add or remove script calls
4. Modify output formatting

### Error Handling

If a workflow fails:

1. Check the error message from the script
2. Verify credentials in `~/.ai-toolkit-env`
3. Ensure required fields exist in Jira
4. Confirm you have necessary permissions
5. Run the script directly to debug: `jira-get-ticket.sh PROJ-123`

## Advanced Usage

### Running Scripts Directly

You can run scripts outside of workflows:

```bash
# Fetch ticket
jira-get-ticket.sh PROJ-456 | jq '.summary'

# Update status
jira-update-status.sh PROJ-456 "In Progress"

# Post to Slack
slack-post-message.sh "Deployment complete" --channel "deployments"
```

### Chaining Commands

Combine multiple operations:

```bash
# Fetch ticket and update status
TICKET="PROJ-456"
jira-get-ticket.sh "$TICKET" && \
jira-update-status.sh "$TICKET" "In Progress"
```

### Debug Mode

Enable verbose logging:

```bash
# Add to ~/.ai-toolkit-env
export DEBUG_MODE="true"

# Or set for single command
DEBUG_MODE=true jira-get-ticket.sh PROJ-123
```

## Troubleshooting

### Workflow doesn't run

- Ensure scripts are in PATH: `which jira-get-ticket.sh`
- Check file permissions: `ls -l ~/bin/*.sh`
- Verify configuration exists: `ls -la ~/.ai-toolkit-env`

### Ticket not found

- Confirm ticket key format: `PROJ-123` (uppercase)
- Verify you have access to the ticket in Jira
- Check JIRA_BASE_URL in configuration

### Slack message fails

- Verify bot token is correct
- Ensure bot is invited to the channel
- Check channel name (without `#` prefix)

### Status transition fails

- Jira workflows vary by project
- Run `jira-update-status.sh TICKET-KEY "Invalid"` to see available transitions
- Check ticket's current status and allowed transitions

## Related Documentation

- [Script Installation](../bin/README.md) - Detailed script setup
- [Configuration Template](../templates/ai-toolkit-env.template) - All available settings
- [CLAUDE.md](../CLAUDE.md) - Claude Code integration guide

## Support

For issues with:
- **Scripts**: Check error messages and run with `DEBUG_MODE=true`
- **Workflows**: Review the workflow markdown for requirements
- **APIs**: Consult Jira, GitHub, or Slack API documentation
