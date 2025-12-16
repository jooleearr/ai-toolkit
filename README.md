# 🤖 AI Toolkit

> A personal library of reusable AI templates, prompts, custom agents, and workflows to accelerate AI-assisted development.

**Includes Jira, GitHub, and Slack integration** for streamlined development workflows with Claude Code.

---

## ⚡ Quick Start

Install into your project:
```bash
cd ~/projects/ai-toolkit
./install-to-project.sh ../your-project
```

Configure credentials (one-time):
```bash
cp _ai/templates/ai-toolkit-env.template ~/.ai-toolkit-env
# Edit ~/.ai-toolkit-env with your API tokens
```

Use with Claude Code:
```
@_ai/workflows/start-work-on-ticket.md Start work on PROJ-123
```

---

## 🎯 Purpose

This repository serves as a **centralized collection** of AI resources that can be quickly integrated into any project. Rather than recreating prompts and configurations from scratch, clone this repo into your project's `_ai` directory and reference, use, copy, or customize the resources as needed.

## 🚀 Usage

### Adding to a Project

**From the ai-toolkit directory**, run the install script with your target project path:

```bash
cd /path/to/ai-toolkit
./install-to-project.sh /path/to/your/project
```

**Example**:
```bash
cd ~/projects/ai-toolkit
./install-to-project.sh ../my-web-app
```

This will:
- Clone ai-toolkit as `_ai/` into your project
- Add `_ai/` to your project's `.gitignore`
- Verify git is properly ignoring the directory

**Manual alternative**:
```bash
cd /path/to/your/project
git clone /path/to/ai-toolkit _ai
echo "_ai/" >> .gitignore
```

### Initial Setup (One-time)

After installing `_ai/` in your project, configure your API credentials:

**1. Create credentials file:**
```bash
cp _ai/templates/ai-toolkit-env.template ~/.ai-toolkit-env
chmod 600 ~/.ai-toolkit-env
```

**2. Edit `~/.ai-toolkit-env` with your credentials:**
- **Jira**: Base URL, email, API token
- **GitHub**: Use GitHub CLI (`gh auth login`) - no token needed
- **Slack**: Bot token and channel name

**3. Install scripts (optional - for direct use):**
```bash
cd _ai/bin && chmod +x *.sh
mkdir -p ~/bin && ln -sf $(pwd)/*.sh ~/bin/
```

See [`bin/README.md`](bin/README.md) for detailed setup instructions.

### Using Workflows with Claude Code

Reference workflows from your project using the `@` syntax:

```
@_ai/workflows/start-work-on-ticket.md Start work on PROJ-123
```

**Example workflow session:**

```
You: @_ai/workflows/start-work-on-ticket.md Start work on CCCSC-372

Claude Code will:
1. Fetch ticket details from Jira
2. Display summary, description, and acceptance criteria
3. Ask: "Shall I move this ticket to 'In Progress'?"
4. Update ticket status on confirmation
5. Suggest creating a feature branch
```

**Available workflows:**

| Workflow | Usage | What it does |
|----------|-------|-------------|
| **Start work on ticket** | `@_ai/workflows/start-work-on-ticket.md Start work on PROJ-123` | Fetch ticket, move to In Progress, suggest branch |
| **Create PR and notify** | `@_ai/workflows/create-pr-and-notify.md Create PR for PROJ-123` | Create PR, set blocked status, notify team on Slack |
| **Complete ticket** | `@_ai/workflows/complete-ticket.md Complete PROJ-123 after PR merge` | Verify PR merged, close ticket, clean up branches |
| **Quick ticket lookup** | `@_ai/workflows/quick-ticket-lookup.md Show me PROJ-123` | Fetch and display ticket info (no status changes) |

### Using Scripts Directly

You can also run integration scripts directly from the command line:

```bash
# Fetch ticket details
jira-get-ticket.sh PROJ-123

# Update ticket status
jira-update-status.sh PROJ-123 "In Progress"

# Mark ticket blocked for code review
jira-update-status.sh PROJ-123 "Ready" --blocked "Internal - Code Review"

# Post to Slack
slack-post-message.sh "PR ready for review" \
  --pr-url "https://github.com/org/repo/pull/123" \
  --ticket "PROJ-123"
```

### 🔄 Workflow

| Action | Description |
|--------|-------------|
| 🔗 **Reference** | Link to templates and prompts directly from the `_ai` directory |
| ⚡ **Use** | Apply custom agents and configurations as-is |
| 📋 **Copy** | Duplicate resources into your project for one-time use |
| ✏️ **Customize** | Modify copies for project-specific requirements |

## 📁 Structure

```
📂 ai-toolkit/
├── 🔧 bin/         - Integration scripts (Jira, GitHub, Slack)
├── 💬 prompts/     - Reusable prompt templates
├── 🤖 agents/      - Custom agent configurations
├── 💭 chatmodes/   - Chat mode configurations
├── 📄 templates/   - Code and documentation templates
└── 🔁 workflows/   - AI-assisted development workflows
```

### Key Components

**Integration Scripts** (`bin/`):
- `jira-get-ticket.sh` - Fetch Jira ticket details
- `jira-update-status.sh` - Update ticket status and blocked reasons
- `slack-post-message.sh` - Post notifications to Slack
- `github-pr-info.sh` - Get PR details and review status

**Workflows** (`workflows/`):
- Start work on ticket
- Create PR and notify team
- Complete ticket after merge
- Quick ticket lookup

## ✨ Benefits

| Benefit | Description |
|---------|-------------|
| 🎯 **Consistency** | Maintain standardized AI interactions across projects |
| ⚡ **Speed** | Skip setup time by reusing proven resources |
| 📈 **Evolution** | Continuously improve your AI toolkit in one place |
| 🚀 **Portability** | Easily bring your AI tools to any new project |

## 🔧 Maintenance

### Updating AI Toolkit

To get the latest workflows and scripts in your projects:

```bash
cd /path/to/your/project/_ai
git pull
```

Or reinstall from ai-toolkit:
```bash
cd ~/projects/ai-toolkit
./install-to-project.sh /path/to/your/project
```

### Adding New Resources

Keep this repository updated with new resources and improvements discovered during project work:
- Add new workflow patterns to `workflows/`
- Create reusable prompts in `prompts/`
- Share useful scripts in `bin/`

Better prompts and workflows benefit all future projects.

### Credentials

Credentials are stored in `~/.ai-toolkit-env` (outside the repository):
- Never committed to git
- Shared across all projects using ai-toolkit
- Update API tokens here when they expire

## 📚 Documentation

- **[bin/README.md](bin/README.md)** - Integration scripts setup and usage
- **[workflows/README.md](workflows/README.md)** - Detailed workflow documentation
- **[CLAUDE.md](CLAUDE.md)** - Claude Code integration guide
