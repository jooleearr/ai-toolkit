#!/usr/bin/env bash
# AI Toolkit - Jira Field Finder
# Helper script to discover Jira custom field IDs

# Get script directory and source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/_integration-common.sh"

# ============================================================================
# USAGE INFORMATION
# ============================================================================

show_usage() {
  cat << 'EOF'
Usage: jira-find-fields.sh [SEARCH_TERM]

Discover Jira custom field IDs for your instance.

Arguments:
  SEARCH_TERM    Optional search term to filter fields (case-insensitive)
                 If omitted, displays all fields

Options:
  -h, --help     Show this help message

Output:
  JSON array of field objects with:
  - id: Field ID (e.g., "customfield_10000")
  - name: Field name (e.g., "Acceptance Criteria")
  - custom: Whether it's a custom field (true/false)
  - type: Field type (e.g., "string", "array", "option")

Examples:
  jira-find-fields.sh                    # List all fields
  jira-find-fields.sh "acceptance"       # Find acceptance criteria field
  jira-find-fields.sh "blocked"          # Find blocked reasons field
  jira-find-fields.sh "sprint"           # Find sprint-related fields

  # Use with jq to format nicely:
  jira-find-fields.sh "custom" | jq '.[] | {id, name}'

Tips:
  - Search for "customfield" to see all custom fields
  - Look for fields starting with "customfield_" for IDs to use in config
  - Update ~/.ai-toolkit-env with the field IDs you find

Common fields to find:
  - Acceptance Criteria (often customfield_10000-10010)
  - Blocked Reasons (often a select list field)
  - Story Points (often customfield_10016)
  - Sprint (often customfield_10020)

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

  # Get search term if provided
  local search_term="${1:-}"

  # Load configuration
  if ! load_config; then
    exit 1
  fi

  # Validate required environment variables
  if ! require_env "JIRA_BASE_URL"; then
    exit 1
  fi

  # Build API URL
  local api_url
  api_url=$(jira_api_url "field")

  debug "Fetching fields from: $api_url"

  # Get auth header
  local auth_header
  if ! auth_header=$(jira_auth_header); then
    exit 1
  fi

  # Fetch all fields
  local response
  if ! response=$(http_request "GET" "$api_url" "$auth_header"); then
    error_msg "Failed to fetch fields from Jira"
    exit 1
  fi

  # Filter and format output
  local output
  if [[ -n "$search_term" ]]; then
    debug "Filtering fields by: $search_term"
    # Case-insensitive search in id, name, or type
    output=$(echo "$response" | jq --arg term "$search_term" '
      [.[] | select(
        (.id | ascii_downcase | contains($term | ascii_downcase)) or
        (.name | ascii_downcase | contains($term | ascii_downcase)) or
        (.schema.type | ascii_downcase | contains($term | ascii_downcase))
      ) | {
        id: .id,
        name: .name,
        custom: .custom,
        type: .schema.type
      }]
    ')
  else
    # Return all fields
    output=$(echo "$response" | jq '[.[] | {
      id: .id,
      name: .name,
      custom: .custom,
      type: .schema.type
    }]')
  fi

  # Count results
  local count
  count=$(echo "$output" | jq 'length')

  # Print output
  echo "$output"

  # Print summary to stderr
  if [[ -n "$search_term" ]]; then
    info_msg "Found $count fields matching '$search_term'" >&2
  else
    info_msg "Found $count total fields" >&2
  fi
}

# Run main function
main "$@"
