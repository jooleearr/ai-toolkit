#!/usr/bin/env bash
# AI Toolkit Integration - Common Utilities
# Shared functions for Jira, GitHub, and Slack integration scripts

# Exit on error, undefined variables, and pipe failures
set -euo pipefail

# ============================================================================
# CONFIGURATION MANAGEMENT
# ============================================================================

# Load configuration from ~/.ai-toolkit-env
load_config() {
  local config_file="${HOME}/.ai-toolkit-env"

  if [[ ! -f "$config_file" ]]; then
    echo "ERROR: Configuration file not found at $config_file" >&2
    echo "" >&2
    echo "To set up:" >&2
    echo "  1. Copy the template: cp templates/ai-toolkit-env.template ~/.ai-toolkit-env" >&2
    echo "  2. Edit ~/.ai-toolkit-env with your credentials" >&2
    echo "  3. Secure the file: chmod 600 ~/.ai-toolkit-env" >&2
    return 1
  fi

  # Source the configuration file
  # shellcheck disable=SC1090
  source "$config_file"

  debug "Configuration loaded from $config_file"
  return 0
}

# Validate that a required environment variable is set
# Usage: require_env "VAR_NAME"
require_env() {
  local var_name="$1"
  local var_value="${!var_name:-}"

  if [[ -z "$var_value" ]]; then
    echo "ERROR: Required environment variable $var_name is not set" >&2
    echo "Please add it to ~/.ai-toolkit-env" >&2
    return 1
  fi

  debug "Validated environment variable: $var_name"
  return 0
}

# ============================================================================
# HTTP REQUEST HANDLING
# ============================================================================

# Make an HTTP request with error handling
# Usage: http_request "METHOD" "URL" "AUTH_HEADER" ["DATA"]
http_request() {
  local method="$1"
  local url="$2"
  local auth_header="$3"
  local data="${4:-}"

  local response
  local http_code
  local temp_file

  # Create temporary file for response
  temp_file=$(mktemp)

  debug "HTTP $method $url"

  # Build curl command
  local curl_cmd=(
    curl
    -s
    -w "\n%{http_code}"
    -X "$method"
    "$url"
    -H "Authorization: $auth_header"
    -H "Content-Type: application/json"
    -o "$temp_file"
  )

  # Add data if provided
  if [[ -n "$data" ]]; then
    curl_cmd+=(-d "$data")
    debug "Request body: $data"
  fi

  # Execute curl and capture HTTP code
  http_code=$("${curl_cmd[@]}")

  # Read response body
  response=$(cat "$temp_file")
  rm "$temp_file"

  debug "HTTP response code: $http_code"

  # Check if request was successful
  if [[ "$http_code" -ge 200 && "$http_code" -lt 300 ]]; then
    echo "$response"
    return 0
  else
    echo "ERROR: HTTP $http_code" >&2
    echo "URL: $url" >&2
    if [[ -n "$response" ]]; then
      echo "Response: $response" >&2
    fi
    return 1
  fi
}

# ============================================================================
# OUTPUT FORMATTING
# ============================================================================

# Format a simple key-value pair as JSON
# Usage: json_output "key" "value"
json_output() {
  local key="$1"
  local value="$2"

  # Escape quotes in value
  value="${value//\"/\\\"}"

  echo "{\"$key\": \"$value\"}"
}

# Print a success message with checkmark
# Usage: success_msg "Message"
success_msg() {
  echo "✓ $*"
}

# Print an info message
# Usage: info_msg "Message"
info_msg() {
  echo "ℹ $*"
}

# Print a warning message
# Usage: warn_msg "Message"
warn_msg() {
  echo "⚠ $*" >&2
}

# Print an error message
# Usage: error_msg "Message"
error_msg() {
  echo "✗ ERROR: $*" >&2
}

# ============================================================================
# DEBUGGING
# ============================================================================

# Print debug message if DEBUG_MODE is enabled
# Usage: debug "Message"
debug() {
  if [[ "${DEBUG_MODE:-false}" == "true" ]]; then
    echo "[DEBUG] $*" >&2
  fi
}

# ============================================================================
# JIRA HELPERS
# ============================================================================

# Build Jira Basic Auth header
# Returns: "Basic <base64-encoded-credentials>"
jira_auth_header() {
  require_env "JIRA_EMAIL" || return 1
  require_env "JIRA_TOKEN" || return 1

  local credentials="${JIRA_EMAIL}:${JIRA_TOKEN}"
  local encoded
  encoded=$(echo -n "$credentials" | base64)

  echo "Basic $encoded"
}

# Build Jira API URL
# Usage: jira_api_url "/issue/PROJ-123"
jira_api_url() {
  local path="$1"
  require_env "JIRA_BASE_URL" || return 1

  # Remove leading slash from path if present
  path="${path#/}"

  echo "${JIRA_BASE_URL}/rest/api/3/${path}"
}

# ============================================================================
# GITHUB HELPERS
# ============================================================================

# Build GitHub Auth header
# Returns: "Bearer <token>"
github_auth_header() {
  require_env "GITHUB_TOKEN" || return 1
  echo "Bearer ${GITHUB_TOKEN}"
}

# Build GitHub API URL
# Usage: github_api_url "/repos/owner/repo/pulls/123"
github_api_url() {
  local path="$1"

  # Remove leading slash from path if present
  path="${path#/}"

  echo "https://api.github.com/${path}"
}

# ============================================================================
# SLACK HELPERS
# ============================================================================

# Build Slack Auth header
# Returns: "Bearer <token>"
slack_auth_header() {
  require_env "SLACK_TOKEN" || return 1
  echo "Bearer ${SLACK_TOKEN}"
}

# Format Slack channel name
# Ensures channel has # prefix for display, but removes it for API calls
# Usage: slack_channel_name "engineering"  # Returns: engineering (no #)
slack_channel_name() {
  local channel="$1"

  # Remove # prefix if present
  channel="${channel#\#}"

  echo "$channel"
}

# ============================================================================
# INPUT VALIDATION
# ============================================================================

# Check if a string is a valid Jira ticket key
# Usage: is_valid_ticket_key "PROJ-123"
is_valid_ticket_key() {
  local ticket_key="$1"

  if [[ "$ticket_key" =~ ^[A-Z]+-[0-9]+$ ]]; then
    return 0
  else
    return 1
  fi
}

# Check if a string is a valid number
# Usage: is_number "123"
is_number() {
  local value="$1"

  if [[ "$value" =~ ^[0-9]+$ ]]; then
    return 0
  else
    return 1
  fi
}

# ============================================================================
# HELP TEXT UTILITIES
# ============================================================================

# Check if help flag is present in arguments
# Usage: if check_help_flag "$@"; then show_usage; exit 0; fi
check_help_flag() {
  for arg in "$@"; do
    if [[ "$arg" == "-h" || "$arg" == "--help" ]]; then
      return 0
    fi
  done
  return 1
}
