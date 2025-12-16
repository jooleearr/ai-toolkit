# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **personal AI resource library** — a curated collection of reusable AI templates, prompts, custom agent configurations, chat modes, and workflows. It's designed to be cloned into other projects as a `_ai` directory, providing standardised AI resources without recreating them from scratch.

**This is not an application** — there are no build steps, dependencies, tests, or runtime. All resources are Markdown-based configuration and documentation files.

## Repository Structure

```
ai-toolkit/
├── bin/            # Integration shell scripts (Jira, GitHub, Slack)
├── prompts/        # Reusable prompt templates for various tasks
├── agents/         # Custom agent configurations
├── chatmodes/      # Chat mode configurations (e.g., accessibility expert)
├── templates/      # Code and documentation templates
└── workflows/      # Common AI-assisted workflows
```

Empty directories contain `.gitkeep` files to preserve them in version control.

## Key Principles

1. **Documentation-first** — Resources must be self-explanatory and well-documented
2. **Portability** — Keep resources generic enough to work across different projects
3. **Organisation** — Categorise by type (prompts, agents, templates, workflows)
4. **New Zealand English** — Use New Zealand spelling conventions (e.g., "organise", "standardised", not American spelling)

## Common Tasks

### Adding Resources

- **Prompts**: Create `.md` files in `/prompts` with clear structure, usage examples, and variable placeholders like `{{PROJECT_REQUIREMENTS}}`
- **Chat modes**: Create `.chatmode.md` files in `/chatmodes` with YAML frontmatter specifying description, model, and tools
- **Agents**: Place configuration files in `/agents` with documentation on purpose and invocation
- **Templates**: Add reusable code/doc templates to `/templates` with inline comments for customisation points
- **Workflows**: Document step-by-step processes in `/workflows` with commands and tool configurations

### File Naming

Use kebab-case for filenames (e.g., `technical-planning.md`, `accessibility.chatmode.md`)

### The .gitignore

The `.gitignore` file handles standard ignores for this repository (macOS files, editor configs, etc.).

**Important**: When installing this repo as `_ai/` in another project, use the `install-to-project.sh` script to automatically add `_ai/` to the parent project's `.gitignore`:
```bash
./install-to-project.sh /path/to/target/project
```

## Existing Resources

### Prompts

- **technical-planning.md** — Creates detailed implementation plans with prerequisites, steps, testing, and considerations. Takes `{{PROJECT_REQUIREMENTS}}` variable.

### Chat Modes

- **accessibility.chatmode.md** — Expert assistant for web accessibility (WCAG 2.1/2.2), inclusive UX, and a11y testing. Comprehensive guidance for designers, developers, and QA.

## Integration Scripts and Workflows

This repository includes integration scripts and workflows for Jira, GitHub, and Slack to streamline development workflows with Claude Code.

### Quick Start

**1. Install scripts:**
```bash
cd bin && chmod +x *.sh
mkdir -p ~/bin && ln -sf "$(pwd)"/*.sh ~/bin/
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.zshrc && source ~/.zshrc
```

**2. Configure credentials:**
```bash
cp templates/ai-toolkit-env.template ~/.ai-toolkit-env
chmod 600 ~/.ai-toolkit-env
# Edit ~/.ai-toolkit-env with your tokens and URLs
```

**3. Find Jira custom field IDs:**
```bash
jira-find-fields.sh "acceptance"  # Find acceptance criteria field
jira-find-fields.sh "blocked"     # Find blocked reasons field
# Update field IDs in ~/.ai-toolkit-env
```

**4. Verify installation:**
```bash
jira-get-ticket.sh --help
jira-get-ticket.sh YOUR-TICKET-KEY
```

See [bin/README.md](bin/README.md) for detailed installation instructions.

### Available Scripts

Located in `bin/` directory:
- **jira-get-ticket.sh** - Fetch ticket details (summary, description, acceptance criteria, subtasks)
- **jira-update-status.sh** - Update ticket status and blocked reasons field
- **jira-find-fields.sh** - Helper to discover custom field IDs
- **slack-post-message.sh** - Post formatted message with PR and ticket links
- **github-pr-info.sh** - Get PR details and review status
- **_integration-common.sh** - Shared utility functions

All scripts:
- Return JSON output for structured data
- Support `--help` flag for usage information
- Include error handling with helpful messages
- Support `DEBUG_MODE=true` for verbose logging

### Available Workflows

Located in `workflows/` directory:

#### 1. Start Work on Ticket
**Purpose**: Fetch ticket details and move to "In Progress"
**Usage**: `@workflows/start-work-on-ticket.md Start work on PROJ-123`
**Steps**:
- Fetches ticket from Jira
- Displays summary, description, acceptance criteria, subtasks
- Moves to "In Progress" (with confirmation)
- Suggests creating feature branch

#### 2. Create PR and Notify
**Purpose**: Create PR, set ticket blocked, notify team
**Usage**: `@workflows/create-pr-and-notify.md Create PR for PROJ-123`
**Steps**:
- Verifies changes are committed and pushed
- Guides PR creation using `gh pr create`
- Sets Jira blocked reason to "Internal - Code Review"
- Posts Slack notification with PR and ticket links

#### 3. Complete Ticket
**Purpose**: Merge PR and close ticket
**Usage**: `@workflows/complete-ticket.md Complete PROJ-123 after PR merge`
**Steps**:
- Verifies PR is merged
- Closes Jira ticket and clears blocked reasons
- Closes subtasks if needed
- Cleans up local and remote branches

#### 4. Quick Ticket Lookup
**Purpose**: View ticket info without changes
**Usage**: `@workflows/quick-ticket-lookup.md Show me PROJ-123`
**Steps**:
- Fetches and displays ticket details
- No status changes
- Suggests next actions based on status

### Using with Claude Code

Reference workflows using the `@` syntax:

**Within ai-toolkit:**
```
@workflows/start-work-on-ticket.md I'm starting work on PROJ-123
```

**When cloned as `_ai`:**
```
@_ai/workflows/start-work-on-ticket.md I'm starting work on PROJ-123
```

Claude Code will execute the workflow steps automatically, calling integration scripts via the Bash tool.

### Configuration

Integration requires `~/.ai-toolkit-env` with:
- **Jira**: Base URL, email, API token, custom field IDs
- **GitHub**: Personal access token, repository owner and name
- **Slack**: Bot token, default channel

See [templates/ai-toolkit-env.template](templates/ai-toolkit-env.template) for all configuration options.

### Your Jira Workflow

**States**: Ready → In Progress → Closed

**Blocked Reasons Field**: Set to "Internal - Code Review" when PR is ready for review

**Subtasks**: Supported on stories - workflows handle subtask status

### Dependencies

- `jq` - Required for JSON parsing (`brew install jq`)
- `gh` - Optional but recommended for PR creation (`brew install gh`)

### Documentation

- [bin/README.md](bin/README.md) - Script installation and troubleshooting
- [workflows/README.md](workflows/README.md) - Workflow details and examples
- [templates/ai-toolkit-env.template](templates/ai-toolkit-env.template) - Configuration reference

## Git Conventions

Use conventional commits format:
- Types: `feat`, `docs`, `chore`, `fix`
- Example: `feat(prompts): add code review template`
