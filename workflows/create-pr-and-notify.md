# Workflow: Create PR and Notify Team

Guide for creating a GitHub PR, setting Jira ticket to blocked status, and notifying the team on Slack.

## Objective

After completing implementation work:
1. Create a GitHub Pull Request
2. Update Jira ticket to indicate it's blocked on code review
3. Post notification to Slack channel

## Prerequisites

- Changes committed to feature branch
- Feature branch pushed to GitHub (or ready to push)
- Jira ticket key (e.g., {{TICKET_KEY}})
- GitHub CLI (`gh`) installed and authenticated
- Integration scripts configured

## Steps

### 1. Verify Work is Complete

Check that all changes are committed:

```bash
git status
```

Expected output: "nothing to commit, working tree clean"

Review commits to be included:

```bash
git log origin/main..HEAD --oneline
```

Ensure commit messages reference the ticket (e.g., "feat: add authentication [PROJ-456]")

### 2. Push Feature Branch

If not already pushed:

```bash
git push -u origin {{BRANCH_NAME}}
```

Get current branch name with:

```bash
git branch --show-current
```

### 3. Create Pull Request

Use GitHub CLI to create PR:

```bash
gh pr create \
  --title "{{TICKET_KEY}}: {{PR_TITLE}}" \
  --body "Resolves {{TICKET_KEY}}

{{PR_DESCRIPTION}}

## Changes
- {{CHANGE_1}}
- {{CHANGE_2}}
" \
  --base main
```

Capture the PR URL from the output.

**Alternative**: If `gh` CLI is not available, guide user to create PR manually via GitHub UI and ask for PR URL.

### 4. Update Jira Blocked Reasons

Set the ticket's "Blocked Reasons" field to indicate it's waiting for code review, while keeping it in "In Progress" status:

```bash
jira-update-status.sh {{TICKET_KEY}} "In Progress" --blocked "Internal - Code Review"
```

**Important**: Keep the ticket in "In Progress" status when setting blocked reasons. The ticket should remain "In Progress" until the PR is merged, at which point it will be closed. If the jira-update-status.sh script indicates the ticket is already in the target status, that's expected - the blocked reason field will still be updated.

### 5. Notify Team on Slack

Check if GitHub has already posted a PR notification to Slack, then post if needed:

```bash
slack-post-message.sh "PR ready for review: {{PR_TITLE}}" \
  --pr-url "{{PR_URL}}" \
  --ticket "{{TICKET_KEY}}" \
  --check-existing
```

The `--check-existing` flag will:
- Fetch recent messages from the Slack channel (last 30 minutes)
- Check if any bot/integration has already posted about this PR or ticket
- Skip posting if an automated message already exists
- Post the message if no existing notification is found

**Note**: This prevents duplicate notifications in repositories with GitHub-Slack integrations.

### 6. Confirm Completion

Inform the user:
- PR #{{PR_NUMBER}} has been created: {{PR_URL}}
- Jira ticket {{TICKET_KEY}} remains in "In Progress" and marked as blocked on code review
- Team notification status:
  - If new message posted: "Team notified in #{{SLACK_CHANNEL}}"
  - If existing message found: "Existing GitHub notification found in #{{SLACK_CHANNEL}}, skipped duplicate"

Suggest next steps:
- Monitor PR for review comments
- Address any CI/CD failures
- Be ready to respond to reviewer feedback

## Example Interaction

**User**: Create PR for my authentication work on PROJ-456

**Claude Code**:
1. Runs: `git status` - confirms clean working tree
2. Runs: `git log origin/main..HEAD` - shows 3 commits
3. Identifies branch: `feature/PROJ-456-add-authentication`
4. Asks: "Create PR from this branch? (3 commits to be included)"
5. On confirmation:
   - Runs: `gh pr create` with ticket reference
   - Captures PR URL: https://github.com/org/repo/pull/789
   - Runs: `jira-update-status.sh PROJ-456 "In Progress" --blocked "Internal - Code Review"`
   - Runs: `slack-post-message.sh "PR ready for review: Add user authentication" --pr-url "..." --ticket "PROJ-456" --check-existing`
6. Confirms: "PR #789 created, ticket blocked on code review, and team notified in #engineering" (or "PR #789 created, existing notification found in Slack")

## Customisation

### PR Template

If repository has a PR template (`.github/pull_request_template.md`), format the PR body to match its structure.

Common template sections:
- Description
- Related Ticket
- Type of Change (bug fix / new feature / breaking change)
- Testing
- Checklist

### Slack Message Format

Customise the message for your team:
- Add mentions: `@channel` or `<@USER_ID>`
- Include additional context
- Use custom emoji
- Add deployment notes

## Error Handling

**PR creation fails**:
- Check if `gh` is installed: `which gh`
- Verify authentication: `gh auth status`
- If unavailable, guide user to create PR manually

**Jira update fails**:
- Display error message
- Show available status transitions
- Ask user to select correct status
- Offer to skip this step and continue

**Slack post fails**:
- Check error message (channel not found / not in channel / invalid auth)
- Verify channel name in config
- Offer to retry with different channel
- Allow user to post manually

**Branch not pushed**:
- Detect with `git status` showing "ahead of origin"
- Prompt: "Branch needs to be pushed. Shall I push it now?"
- Execute push on confirmation

## Related Workflows

- [Start Work on Ticket](start-work-on-ticket.md) - Previous step
- [Complete Ticket](complete-ticket.md) - Next step after PR approval
- [Quick Ticket Lookup](quick-ticket-lookup.md) - Check ticket status anytime
