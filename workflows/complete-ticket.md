# Workflow: Complete Ticket

Guide for completing a Jira ticket after PR approval and merge.

## Objective

After PR is approved and merged:
1. Verify PR has been merged
2. Move Jira ticket to "Closed" status
3. Clear blocked reasons field
4. Clean up local and remote branches

## Prerequisites

- PR has been approved and merged
- Jira ticket key (e.g., {{TICKET_KEY}})
- PR number (e.g., {{PR_NUMBER}})
- Integration scripts configured

## Steps

### 1. Verify PR Status

Check that the PR has been successfully merged:

```bash
github-pr-info.sh {{PR_NUMBER}}
```

Parse the state field from JSON output.

**If state is "merged"**: Proceed to step 2

**If state is "open"**:
- Display: "PR #{{PR_NUMBER}} is still open"
- Show review status (approved, changes requested)
- Ask: "Would you like to wait and check again later?"
- Exit workflow

**If state is "closed" but not merged**:
- Display: "PR #{{PR_NUMBER}} was closed without merging"
- Ask: "Proceed with closing the ticket anyway?"

### 2. Close Jira Ticket

Move ticket to "Closed" status and clear blocked reasons:

```bash
jira-update-status.sh {{TICKET_KEY}} "Closed" --clear-blocked
```

### 3. Check Subtasks

Fetch ticket details to check for subtasks:

```bash
jira-get-ticket.sh {{TICKET_KEY}}
```

Parse subtasks array. If any subtasks exist and are not closed:
- Display: "Found {{COUNT}} subtask(s):"
- List subtasks with their status
- Ask: "Should these subtasks also be closed?"
- If yes, close each subtask:
  ```bash
  jira-update-status.sh {{SUBTASK_KEY}} "Closed"
  ```

### 4. Clean Up Local Branch

Get current branch and switch to main:

```bash
git branch --show-current  # Note the feature branch name
git checkout main
git pull origin main
```

Delete the feature branch locally:

```bash
git branch -d {{FEATURE_BRANCH}}
```

If force delete is needed (branch not fully merged to current HEAD):
- Display: "Branch {{FEATURE_BRANCH}} may have unmerged changes"
- Ask: "Force delete anyway? (changes are in the merged PR)"
- If confirmed: `git branch -D {{FEATURE_BRANCH}}`

### 5. Clean Up Remote Branch

Check if remote branch still exists:

```bash
git ls-remote --heads origin {{FEATURE_BRANCH}}
```

If it exists:
- Display: "Remote branch origin/{{FEATURE_BRANCH}} still exists"
- Ask: "Delete remote branch?"
- If confirmed:
  ```bash
  git push origin --delete {{FEATURE_BRANCH}}
  ```

**Note**: Many teams configure GitHub to auto-delete branches after merge. If branch doesn't exist remotely, skip this step.

### 6. Confirm Completion

Display summary:
- ✓ PR #{{PR_NUMBER}} was merged
- ✓ Ticket {{TICKET_KEY}} closed
- ✓ Blocked reasons cleared
- ✓ Local branch {{FEATURE_BRANCH}} deleted
- ✓ Remote branch deleted (or "Auto-deleted by GitHub")
- ✓ All subtasks closed (if applicable)

Suggest: "Ready to start work on the next ticket?"

## Example Interaction

**User**: Complete PROJ-456, PR #789 has been merged

**Claude Code**:
1. Executes: `github-pr-info.sh 789`
2. Parses state: "merged"
3. Confirms: "PR #789 was merged ✓"
4. Executes: `jira-update-status.sh PROJ-456 "Closed" --clear-blocked"`
5. Confirms: "Ticket PROJ-456 closed ✓"
6. Executes: `jira-get-ticket.sh PROJ-456`
7. Checks subtasks: none found
8. Gets current branch: `feature/PROJ-456-add-authentication`
9. Executes: `git checkout main && git pull`
10. Executes: `git branch -d feature/PROJ-456-add-authentication`
11. Checks remote: branch auto-deleted
12. Displays summary with all checkmarks

## Error Handling

### PR Not Yet Merged

**If state is "open"**:
- Display current review status
- Show: "Approvals: {{APPROVED}}, Changes Requested: {{CHANGES_REQUESTED}}"
- Suggest: "PR needs approval before closing ticket"
- Ask: "Check again later?"
- Do not close ticket

### Subtasks Still Open

**If subtasks exist and are incomplete**:
- List open subtasks
- Ask: "Close parent ticket anyway?"
- If yes: close parent but leave subtasks open
- If no: exit without closing
- Suggest: "Complete subtasks first"

### Ticket Already Closed

**If ticket is already "Closed"**:
- Inform user: "Ticket {{TICKET_KEY}} is already closed"
- Display when it was closed (if available)
- Ask: "Proceed with branch cleanup only?"
- If yes: skip to step 4

### Branch Cleanup Fails

**If branch can't be deleted**:
- Display error message
- Suggest: "Branch may have been already deleted"
- Or: "Use -D flag to force delete: git branch -D {{BRANCH}}"
- Continue with workflow (don't fail completely)

### GitHub API Errors

**If PR info fails to fetch**:
- Display error
- Ask: "Skip PR verification and close ticket anyway?"
- If yes: proceed with ticket closure
- If no: exit workflow

## Alternative Paths

### Minimal Cleanup

User wants to close ticket without branch cleanup:
- Run steps 1-3 only
- Skip branch deletion
- Useful if working in a monorepo or shared codebase

### Manual PR Verification

User confirms PR is merged without API check:
- Skip step 1
- Proceed directly to step 2
- Ask user: "Confirm PR #{{PR_NUMBER}} is merged?"

### Partial Subtask Closure

Some subtasks should remain open:
- List all subtasks with checkboxes
- Ask user to select which to close
- Close only selected subtasks
- Leave others open for future work

## Related Workflows

- [Create PR and Notify](create-pr-and-notify.md) - Previous step
- [Start Work on Ticket](start-work-on-ticket.md) - Start next ticket
- [Quick Ticket Lookup](quick-ticket-lookup.md) - View closed ticket details
