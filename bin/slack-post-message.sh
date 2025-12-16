#!/usr/bin/env bash
# AI Toolkit - Slack Post Message
# Post formatted messages to Slack channel

# Get script directory and source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/_integration-common.sh"

# ============================================================================
# USAGE INFORMATION
# ============================================================================

show_usage() {
  cat << 'EOF'
Usage: slack-post-message.sh MESSAGE [OPTIONS]

Post a formatted message to the configured Slack channel.

Arguments:
  MESSAGE       Message text to post

Options:
  --pr-url URL        Include PR link in formatted message
  --ticket TICKET     Include Jira ticket reference
  --channel CHANNEL   Override default channel (e.g., "engineering")
  -h, --help         Show this help message

Examples:
  # Simple message
  slack-post-message.sh "PR ready for review"

  # With PR link
  slack-post-message.sh "PR ready" \
    --pr-url "https://github.com/org/repo/pull/123"

  # With PR and ticket
  slack-post-message.sh "Authentication feature ready" \
    --pr-url "https://github.com/org/repo/pull/123" \
    --ticket "PROJ-456"

  # Override channel
  slack-post-message.sh "Urgent fix deployed" \
    --channel "incidents"

Tips:
  - Channel names should be without # prefix (e.g., "engineering")
  - Messages support basic Slack markdown (*, _, ~, `, ```)
  - Default channel is configured in ~/.ai-toolkit-env

EOF
}

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

# Build Slack Block Kit message
build_message_blocks() {
  local message="$1"
  local pr_url="$2"
  local ticket_key="$3"

  local blocks="["

  # Main message block
  blocks+=$(jq -n --arg text "$message" '{
    type: "section",
    text: {
      type: "mrkdwn",
      text: $text
    }
  }')

  # Add PR link if provided
  if [[ -n "$pr_url" ]]; then
    blocks+=","
    blocks+=$(jq -n --arg url "$pr_url" '{
      type: "section",
      text: {
        type: "mrkdwn",
        text: ("*PR:* <" + $url + "|View Pull Request>")
      }
    }')
  fi

  # Add Jira ticket link if provided
  if [[ -n "$ticket_key" ]]; then
    require_env "JIRA_BASE_URL" || return 1

    blocks+=","
    local jira_url="${JIRA_BASE_URL}/browse/${ticket_key}"
    blocks+=$(jq -n \
      --arg ticket "$ticket_key" \
      --arg url "$jira_url" \
      '{
        type: "section",
        text: {
          type: "mrkdwn",
          text: ("*Jira:* <" + $url + "|" + $ticket + ">")
        }
      }')
  fi

  blocks+="]"

  echo "$blocks"
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
    error_msg "Missing required argument: MESSAGE"
    echo "" >&2
    show_usage
    exit 1
  fi

  local message="$1"
  shift

  # Parse optional arguments
  local pr_url=""
  local ticket_key=""
  local channel=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --pr-url)
        if [[ $# -lt 2 ]]; then
          error_msg "Missing value for --pr-url"
          exit 1
        fi
        pr_url="$2"
        shift 2
        ;;
      --ticket)
        if [[ $# -lt 2 ]]; then
          error_msg "Missing value for --ticket"
          exit 1
        fi
        ticket_key="$2"
        shift 2
        ;;
      --channel)
        if [[ $# -lt 2 ]]; then
          error_msg "Missing value for --channel"
          exit 1
        fi
        channel="$2"
        shift 2
        ;;
      *)
        error_msg "Unknown option: $1"
        show_usage
        exit 1
        ;;
    esac
  done

  # Validate ticket key format if provided
  if [[ -n "$ticket_key" ]] && ! is_valid_ticket_key "$ticket_key"; then
    error_msg "Invalid ticket key format: $ticket_key"
    exit 1
  fi

  # Load configuration
  if ! load_config; then
    exit 1
  fi

  # Validate required environment variables
  require_env "SLACK_TOKEN" || exit 1
  require_env "SLACK_CHANNEL" || exit 1

  # Use provided channel or default
  if [[ -z "$channel" ]]; then
    channel="${SLACK_CHANNEL}"
  fi

  # Ensure channel name is formatted correctly (no # prefix for API)
  channel=$(slack_channel_name "$channel")

  debug "Posting to Slack channel: $channel"

  # Build message blocks
  local blocks
  if ! blocks=$(build_message_blocks "$message" "$pr_url" "$ticket_key"); then
    error_msg "Failed to build message blocks"
    exit 1
  fi

  debug "Message blocks: $blocks"

  # Build Slack API payload
  local payload
  payload=$(jq -n \
    --arg channel "$channel" \
    --argjson blocks "$blocks" \
    '{
      channel: $channel,
      blocks: $blocks
    }')

  debug "Payload: $payload"

  # Get auth header
  local auth_header
  if ! auth_header=$(slack_auth_header); then
    exit 1
  fi

  # Post to Slack
  local slack_url="https://slack.com/api/chat.postMessage"
  local response

  if ! response=$(http_request "POST" "$slack_url" "$auth_header" "$payload"); then
    error_msg "Failed to post message to Slack"
    exit 1
  fi

  # Check Slack API response
  local ok
  ok=$(echo "$response" | jq -r '.ok')

  if [[ "$ok" != "true" ]]; then
    local error
    error=$(echo "$response" | jq -r '.error')
    error_msg "Slack API returned error: $error"

    # Provide helpful error messages
    case "$error" in
      "channel_not_found")
        info_msg "Channel '$channel' not found. Check the channel name in ~/.ai-toolkit-env"
        ;;
      "not_in_channel")
        info_msg "Bot is not in channel '$channel'. Invite the bot to the channel first"
        ;;
      "invalid_auth")
        info_msg "Invalid Slack token. Check SLACK_TOKEN in ~/.ai-toolkit-env"
        ;;
    esac

    exit 1
  fi

  # Extract message timestamp
  local timestamp
  timestamp=$(echo "$response" | jq -r '.ts')

  success_msg "Posted to #$channel (timestamp: $timestamp)"

  # Output channel and timestamp for potential future use (e.g., threading)
  debug "Message ID: $channel/$timestamp"
}

# Run main function
main "$@"
