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

### 4. Update Jira Status

Set the ticket's "Blocked Reasons" field to indicate it's waiting for code review:

```bash
jira-update-status.sh {{TICKET_KEY}} "Ready" --blocked "Internal - Code Review"
```

**Note**: The target status might be "Ready", "In Review", or remain "In Progress" depending on the workflow. Use the appropriate status for this Jira instance.

### 5. Notify Team on Slack

Post a formatted message to the team's Slack channel:

```bash
slack-post-message.sh "PR ready for review: {{PR_TITLE}}" \
  --pr-url "{{PR_URL}}" \
  --ticket "{{TICKET_KEY}}"
```

### 6. Confirm Completion

Inform the user:
- PR #{{PR_NUMBER}} has been created: {{PR_URL}}
- Jira ticket {{TICKET_KEY}} marked as blocked on code review
- Team notified in #{{SLACK_CHANNEL}}

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
   - Runs: `jira-update-status.sh PROJ-456 "Ready" --blocked "Internal - Code Review"`
   - Runs: `slack-post-message.sh "PR ready for review: Add user authentication" --pr-url "..." --ticket "PROJ-456"`
6. Confirms: "PR #789 created and team notified in #engineering"

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
