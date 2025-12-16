#!/usr/bin/env bash
# AI Toolkit - Jira Update Status
# Update Jira ticket status and blocked reasons field

# Get script directory and source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/_integration-common.sh"

# ============================================================================
# USAGE INFORMATION
# ============================================================================

show_usage() {
  cat << 'EOF'
Usage: jira-update-status.sh TICKET-KEY STATUS [OPTIONS]

Update the status of a Jira ticket and optionally set blocked reasons.

Arguments:
  TICKET-KEY    Jira ticket key (e.g., PROJ-123)
  STATUS        Target status (e.g., "In Progress", "Closed")

Options:
  --blocked REASON    Set blocked reason field (default: from config)
  --clear-blocked     Clear the blocked reason field
  -h, --help         Show this help message

Examples:
  # Move ticket to In Progress
  jira-update-status.sh PROJ-123 "In Progress"

  # Set ticket as blocked for code review
  jira-update-status.sh PROJ-123 "Ready" --blocked "Internal - Code Review"

  # Close ticket and clear blocked reason
  jira-update-status.sh PROJ-123 "Closed" --clear-blocked

  # Use default blocked reason from config
  jira-update-status.sh PROJ-456 "Ready" --blocked

Tips:
  - Status names are case-sensitive and must match your Jira workflow
  - If no matching transition is found, available options will be displayed
  - Blocked reason field ID is configured in ~/.ai-toolkit-env

EOF
}

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

# Get available transitions for a ticket
get_transitions() {
  local ticket_key="$1"
  local auth_header="$2"

  local api_url
  api_url=$(jira_api_url "issue/${ticket_key}/transitions")

  debug "Fetching transitions for $ticket_key"

  local response
  if ! response=$(http_request "GET" "$api_url" "$auth_header"); then
    return 1
  fi

  echo "$response"
}

# Find transition ID for target status
find_transition_id() {
  local transitions="$1"
  local target_status="$2"

  local transition_id
  transition_id=$(echo "$transitions" | jq -r \
    --arg status "$target_status" \
    '.transitions[] | select(.to.name == $status) | .id'
  )

  echo "$transition_id"
}

# Execute a transition
execute_transition() {
  local ticket_key="$1"
  local transition_id="$2"
  local auth_header="$3"

  local api_url
  api_url=$(jira_api_url "issue/${ticket_key}/transitions")

  local data
  data=$(jq -n --arg id "$transition_id" '{transition: {id: $id}}')

  debug "Executing transition $transition_id"

  if ! http_request "POST" "$api_url" "$auth_header" "$data" > /dev/null; then
    return 1
  fi

  return 0
}

# Update blocked reasons field
update_blocked_reasons() {
  local ticket_key="$1"
  local value="$2"  # Can be a string or null
  local auth_header="$3"

  require_env "JIRA_FIELD_BLOCKED_REASONS" || return 1

  local api_url
  api_url=$(jira_api_url "issue/${ticket_key}")

  local field_id="${JIRA_FIELD_BLOCKED_REASONS}"
  local data

  if [[ "$value" == "null" ]]; then
    # Clear the field
    data=$(jq -n --arg field "$field_id" '{fields: {($field): null}}')
    debug "Clearing blocked reasons field"
  else
    # Set the field
    data=$(jq -n --arg field "$field_id" --arg value "$value" \
      '{fields: {($field): $value}}')
    debug "Setting blocked reasons: $value"
  fi

  if ! http_request "PUT" "$api_url" "$auth_header" "$data" > /dev/null; then
    return 1
  fi

  return 0
}

# Display available transitions
show_available_transitions() {
  local transitions="$1"

  echo "" >&2
  error_msg "No transition found to the specified status"
  echo "" >&2
  info_msg "Available transitions:" >&2

  echo "$transitions" | jq -r '.transitions[] | "  - \(.to.name)"' >&2
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
  if [[ $# -lt 2 ]]; then
    error_msg "Missing required arguments"
    echo "" >&2
    show_usage
    exit 1
  fi

  local ticket_key="$1"
  local target_status="$2"
  shift 2

  # Parse optional arguments
  local blocked_reason=""
  local clear_blocked=false
  local set_blocked=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --blocked)
        set_blocked=true
        if [[ $# -gt 1 && ! "$2" =~ ^-- ]]; then
          blocked_reason="$2"
          shift 2
        else
          # Use default from config
          shift 1
        fi
        ;;
      --clear-blocked)
        clear_blocked=true
        shift 1
        ;;
      *)
        error_msg "Unknown option: $1"
        show_usage
        exit 1
        ;;
    esac
  done

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
  require_env "JIRA_BASE_URL" || exit 1

  # Get auth header
  local auth_header
  if ! auth_header=$(jira_auth_header); then
    exit 1
  fi

  # Step 1: Get available transitions
  local transitions
  if ! transitions=$(get_transitions "$ticket_key" "$auth_header"); then
    error_msg "Failed to fetch transitions for $ticket_key"
    exit 1
  fi

  # Step 2: Find transition ID for target status
  local transition_id
  transition_id=$(find_transition_id "$transitions" "$target_status")

  if [[ -z "$transition_id" ]]; then
    show_available_transitions "$transitions"
    exit 1
  fi

  debug "Found transition ID: $transition_id for status '$target_status'"

  # Step 3: Execute transition
  if ! execute_transition "$ticket_key" "$transition_id" "$auth_header"; then
    error_msg "Failed to transition $ticket_key to '$target_status'"
    exit 1
  fi

  success_msg "Transitioned $ticket_key to '$target_status'"

  # Step 4: Update blocked reasons field if requested
  if [[ "$set_blocked" == true || "$clear_blocked" == true ]]; then
    if [[ "$clear_blocked" == true ]]; then
      if update_blocked_reasons "$ticket_key" "null" "$auth_header"; then
        success_msg "Cleared blocked reason"
      else
        warn_msg "Status updated but failed to clear blocked reason"
      fi
    else
      # Use provided reason or default from config
      if [[ -z "$blocked_reason" ]]; then
        if [[ -n "${JIRA_BLOCKED_REASON:-}" ]]; then
          blocked_reason="${JIRA_BLOCKED_REASON}"
        else
          error_msg "No blocked reason provided and JIRA_BLOCKED_REASON not set in config"
          exit 1
        fi
      fi

      if update_blocked_reasons "$ticket_key" "$blocked_reason" "$auth_header"; then
        success_msg "Set blocked reason: $blocked_reason"
      else
        warn_msg "Status updated but failed to set blocked reason"
      fi
    fi
  fi
}

# Run main function
main "$@"
