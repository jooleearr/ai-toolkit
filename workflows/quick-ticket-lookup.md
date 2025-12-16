# Workflow: Quick Ticket Lookup

Quickly fetch and display Jira ticket information without changing status.

## Objective

Retrieve ticket details for reference, planning, or context without modifying the ticket.

## Prerequisites

- Jira ticket key (e.g., {{TICKET_KEY}})
- Integration scripts configured

## Steps

### 1. Fetch Ticket Information

```bash
jira-get-ticket.sh {{TICKET_KEY}}
```

### 2. Parse and Display

Extract and format key information:

```
Ticket: {{TICKET_KEY}} - [SUMMARY]

Status: [CURRENT_STATUS]
Assignee: [ASSIGNEE]
Priority: [PRIORITY]

Description:
[DESCRIPTION]

Acceptance Criteria:
[ACCEPTANCE_CRITERIA]

Subtasks:
- [SUBTASK_1] ([STATUS])
- [SUBTASK_2] ([STATUS])

Link: [JIRA_URL]
```

### 3. Suggest Next Actions

Based on the ticket status, suggest appropriate actions:

**If status is "Ready" or "To Do"**:
- "Would you like to start work on this ticket?" → [Start Work on Ticket](start-work-on-ticket.md)

**If status is "In Progress"**:
- "Continue working on this ticket?"
- "Ready to create a PR?" → [Create PR and Notify](create-pr-and-notify.md)

**If ticket has blocked reasons set**:
- Display the blocked reason
- "Check PR status?" (if blocked on code review)
- "Ready to close ticket?" → [Complete Ticket](complete-ticket.md)

**If status is "Closed"**:
- "This ticket is already closed."
- Display completion information if available

## Example Interactions

### Single Ticket Lookup

**User**: What's PROJ-789 about?

**Claude Code**:
1. Executes: `jira-get-ticket.sh PROJ-789`
2. Displays formatted summary with all details
3. Reads status: "In Progress"
4. Suggests: "This ticket is in progress. Ready to create a PR?"

### Multiple Tickets

**User**: Show me PROJ-123, PROJ-456, and PROJ-789

**Claude Code**:
1. Executes three jira-get-ticket.sh commands (can run in parallel)
2. Displays comparison:

```
╔══════════╦═══════════════════════╦══════════════╦══════════╗
║ Ticket   ║ Summary               ║ Status       ║ Priority ║
╠══════════╬═══════════════════════╬══════════════╬══════════╣
║ PROJ-123 ║ Feature A             ║ Ready        ║ High     ║
║ PROJ-456 ║ Bug fix               ║ In Progress  ║ Medium   ║
║ PROJ-789 ║ Enhancement           ║ Closed       ║ Low      ║
╚══════════╩═══════════════════════╩══════════════╩══════════╝
```

3. Asks: "Which ticket would you like to work on?"

### With Subtasks

**User**: Show me PROJ-456 with subtasks

**Claude Code**:
1. Executes: `jira-get-ticket.sh PROJ-456`
2. Displays main ticket details
3. Lists subtasks with their individual statuses
4. Identifies: 2 of 3 subtasks complete
5. Suggests: "One subtask remaining. Would you like to view it?"

## Use Cases

### Sprint Planning

Review multiple tickets to prioritise work:

```
@workflows/quick-ticket-lookup.md Show me all tickets in the current sprint
```

Provide ticket keys and Claude will fetch and compare them.

### Standup Preparation

Quickly check status of tickets you're working on:

```
@workflows/quick-ticket-lookup.md What's the status of PROJ-456?
```

### Context Switching

Refresh memory on ticket details when returning to work:

```
@workflows/quick-ticket-lookup.md Remind me what PROJ-789 is about
```

### Dependency Checking

View related tickets mentioned in descriptions:

```
@workflows/quick-ticket-lookup.md Show me PROJ-123 and its related tickets
```

## Error Handling

**Ticket doesn't exist**:
- Display error: "Ticket {{TICKET_KEY}} not found"
- Suggest: "Check the ticket key spelling"
- Ask: "Would you like to try a different ticket?"

**Access denied**:
- Display: "You don't have permission to view this ticket"
- Suggest: "Contact your Jira administrator for access"

**Network or API errors**:
- Display error message
- Suggest: "Check your Jira credentials in ~/.ai-toolkit-env"
- Offer to retry

**Missing custom fields**:
- Display available fields
- Acceptance criteria or blocked reasons may show as "Not specified"
- Suggest: "Run jira-find-fields.sh to update field IDs in config"

## Related Workflows

- [Start Work on Ticket](start-work-on-ticket.md) - Begin work after reviewing
- [Create PR and Notify](create-pr-and-notify.md) - Create PR for in-progress ticket
- [Complete Ticket](complete-ticket.md) - Close ticket after merge
