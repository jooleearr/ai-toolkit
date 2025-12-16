# Workflow: Start Work on Ticket

Guide for starting work on a Jira ticket.

## Objective

Fetch ticket details, understand requirements, and move the ticket to "In Progress" status.

## Prerequisites

- Jira ticket key (e.g., {{TICKET_KEY}})
- Integration scripts installed and configured
- User is assigned to the ticket or has permission to start work

## Steps

### 1. Fetch Ticket Details

Retrieve comprehensive ticket information:

```bash
jira-get-ticket.sh {{TICKET_KEY}}
```

Parse the JSON output and extract:
- Summary/title
- Full description
- Acceptance criteria
- Subtasks (if any)
- Current status
- Priority
- Assignee

### 2. Present Summary to User

Format and display key information:

```
Ticket: {{TICKET_KEY}} - [SUMMARY]

Status: [CURRENT_STATUS]
Priority: [PRIORITY]
Assigned to: [ASSIGNEE]

Description:
[DESCRIPTION]

Acceptance Criteria:
[ACCEPTANCE_CRITERIA]

Subtasks:
- [SUBTASK_1] ([STATUS])
- [SUBTASK_2] ([STATUS])
```

### 3. Confirm Status Transition

Ask user: "Shall I move this ticket to 'In Progress'?"

If user confirms, proceed to step 4. Otherwise, skip to step 5.

### 4. Update Ticket Status

Move ticket to "In Progress":

```bash
jira-update-status.sh {{TICKET_KEY}} "In Progress"
```

Confirm success: "✓ Ticket moved to In Progress"

### 5. Suggest Feature Branch

Propose creating a feature branch using ticket key and brief description:

```bash
git checkout -b feature/{{TICKET_KEY}}-[brief-description-slug]
```

Example: `feature/PROJ-456-add-user-authentication`

### 6. Confirm Next Steps

Ask the user how they'd like to proceed:
- Start implementing specific acceptance criteria
- Review existing code related to the feature
- Set up necessary dependencies or scaffolding
- Other (let user specify)

## Example Interaction

**User**: Start work on PROJ-456

**Claude Code**:
1. Executes: `jira-get-ticket.sh PROJ-456`
2. Displays formatted summary with acceptance criteria
3. Asks: "Shall I move PROJ-456 to 'In Progress' and create a feature branch?"
4. On confirmation:
   - Executes: `jira-update-status.sh PROJ-456 "In Progress"`
   - Suggests: `git checkout -b feature/PROJ-456-add-authentication`

## Error Handling

**Ticket doesn't exist**:
- Display error and ask user to verify ticket key
- Suggest: "Did you mean a different ticket?"

**Ticket already "In Progress"**:
- Inform user of current status
- Ask: "The ticket is already in progress. Would you like to continue anyway?"

**Status transition fails**:
- Display available statuses from error message
- Show current status and available transitions
- Ask user which status to use

**No subtasks to display**:
- Simply omit the subtasks section from summary
- This is normal for many tickets

## Related Workflows

- [Create PR and Notify](create-pr-and-notify.md) - Next step after implementation
- [Quick Ticket Lookup](quick-ticket-lookup.md) - View ticket without status change
