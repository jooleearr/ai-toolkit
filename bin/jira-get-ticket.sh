#!/usr/bin/env bash
# AI Toolkit - Jira Get Ticket
# Fetch comprehensive details for a Jira ticket

# Get script directory and source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/_integration-common.sh"

# ============================================================================
# USAGE INFORMATION
# ============================================================================

show_usage() {
  cat << 'EOF'
Usage: jira-get-ticket.sh TICKET-KEY

Fetch comprehensive details for a Jira ticket.

Arguments:
  TICKET-KEY    Jira ticket key (e.g., PROJ-123)

Options:
  -h, --help    Show this help message

Output:
  JSON object with ticket details including:
  - key: Ticket key
  - summary: Ticket summary/title
  - status: Current status
  - description: Full description
  - acceptanceCriteria: Acceptance criteria (if present)
  - subtasks: Array of subtask objects with key, summary, status
  - assignee: Assigned user
  - priority: Priority level

Examples:
  jira-get-ticket.sh PROJ-123
  jira-get-ticket.sh PROJ-456 | jq '.summary'
  jira-get-ticket.sh PROJ-789 | jq '.subtasks[]'

Tips:
  - Pipe output to jq for formatted display
  - Check ~/.ai-toolkit-env for custom field configuration
  - Use jira-find-fields.sh to discover field IDs

EOF
}

# ============================================================================
# MAIN FUNCTION
# ============================================================================

main() {
  # Check for help flag
  if check_help_flag "$@"; then
    show_usage
    exit 0
  fi

  # Check arguments
  if [[ $# -eq 0 ]]; then
    error_msg "Missing required argument: TICKET-KEY"
    echo "" >&2
    show_usage
    exit 1
  fi

  local ticket_key="$1"

  # Validate ticket key format
  if ! is_valid_ticket_key "$ticket_key"; then
    error_msg "Invalid ticket key format: $ticket_key"
    info_msg "Expected format: PROJ-123 (uppercase letters, hyphen, numbers)"
    exit 1
  fi

  # Load configuration
  if ! load_config; then
    exit 1
  fi

  # Validate required environment variables
  if ! require_env "JIRA_BASE_URL"; then
    exit 1
  fi
  if ! require_env "JIRA_FIELD_ACCEPTANCE_CRITERIA"; then
    warn_msg "JIRA_FIELD_ACCEPTANCE_CRITERIA not set - acceptance criteria may not be fetched"
  fi
  if ! require_env "JIRA_FIELD_BLOCKED_REASONS"; then
    warn_msg "JIRA_FIELD_BLOCKED_REASONS not set - blocked reasons may not be fetched"
  fi

  # Build API URL with fields parameter
  local fields="summary,description,status,assignee,priority,subtasks"
  fields="${fields},${JIRA_FIELD_ACCEPTANCE_CRITERIA},${JIRA_FIELD_BLOCKED_REASONS}"

  local api_url
  api_url=$(jira_api_url "issue/${ticket_key}?fields=${fields}")

  debug "Fetching ticket: $ticket_key from $api_url"

  # Get auth header
  local auth_header
  if ! auth_header=$(jira_auth_header); then
    exit 1
  fi

  # Fetch ticket data
  local response
  if ! response=$(http_request "GET" "$api_url" "$auth_header"); then
    error_msg "Failed to fetch ticket $ticket_key"
    info_msg "Verify the ticket exists and you have access to it"
    exit 1
  fi

  # Parse and format response using jq
  local acceptance_field="${JIRA_FIELD_ACCEPTANCE_CRITERIA}"
  local blocked_field="${JIRA_FIELD_BLOCKED_REASONS}"

  local output
  output=$(echo "$response" | jq \
    --arg acceptance_field "$acceptance_field" \
    --arg blocked_field "$blocked_field" \
    --arg base_url "$JIRA_BASE_URL" \
    '{
      key: .key,
      summary: .fields.summary,
      status: .fields.status.name,
      description: (.fields.description // "No description"),
      acceptanceCriteria: (.fields[$acceptance_field] // "Not specified"),
      blockedReasons: (.fields[$blocked_field] // null),
      subtasks: [.fields.subtasks[]? | {
        key: .key,
        summary: .fields.summary,
        status: .fields.status.name
      }],
      assignee: (.fields.assignee.displayName // "Unassigned"),
      priority: .fields.priority.name,
      url: ($base_url + "/browse/" + .key)
    }' <<< "$response" 2>/dev/null
  )

  # Check if jq parsing was successful
  if [[ $? -ne 0 ]]; then
    error_msg "Failed to parse Jira response"
    debug "Raw response: $response"
    exit 1
  fi

  # Output the formatted ticket data
  echo "$output"

  # Print success message to stderr
  debug "Successfully fetched ticket $ticket_key"
}

# Run main function
main "$@"
