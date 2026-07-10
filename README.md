# ai-toolkit

A personal **Claude Code plugin marketplace** — reusable skills, agents, and shared
settings that drop cleanly into any project.

Instead of copying files around, you register this repo once as a marketplace and then
install what you want, where you want it. Updates are a single command.

## Quick start

```bash
# One-time, per machine — register the marketplace
claude plugin marketplace add jooleearr/ai-toolkit
#   ...or inside a Claude Code session:  /plugin marketplace add jooleearr/ai-toolkit

# Per project (or globally) — install a plugin
claude plugin install core@ai-toolkit
#   ...or inside a session:  /plugin install core@ai-toolkit
```

Or run the helper. By default it only registers the marketplace — the agent-safe part:

```bash
git clone https://github.com/jooleearr/ai-toolkit.git
cd ai-toolkit
./install.sh                       # registers the marketplace only
```

The shared permission defaults (`shared/settings.template.json`) are a **manual
reference** — copy the tiers you want into a project's `.claude/settings.json`. A
**human must apply them**: Claude Code's self-modification guardrail blocks an agent
from writing permission rules for you. To merge them with the helper (run it
yourself, not via an agent):

```bash
./install.sh --settings            # merge into ./.claude/settings.json (this project)
./install.sh --settings --project /path/to/repo   # into another project
./install.sh --settings --global   # into ~/.claude/settings.json (explicit opt-in)
```

Keep everything current with `/plugin marketplace update` (or `claude plugin marketplace update ai-toolkit`).

## What's here

```
ai-toolkit/
├── .claude-plugin/
│   └── marketplace.json        # the catalog — lists every plugin below
├── plugins/
│   └── core/                   # a plugin (skills that apply to any project)
│       ├── .claude-plugin/plugin.json
│       ├── skills/<name>/SKILL.md
│       └── README.md
├── shared/
│   └── settings.template.json  # default permissions (installed separately — see below)
└── install.sh
```

### Plugins

| Plugin | Install | Contents |
| :----- | :------ | :------- |
| `core` | `core@ai-toolkit` | General skills, e.g. `ai-ready-repo`. See [plugins/core](plugins/core/README.md). |

## Adding resources

- **New skill in an existing plugin** — add `plugins/<plugin>/skills/<name>/SKILL.md`
  with `name` + `description` frontmatter. Run `/reload-plugins` to test.
- **New plugin** — create `plugins/<name>/.claude-plugin/plugin.json`, add its
  components, then add an entry to `.claude-plugin/marketplace.json`.
- **Test locally without installing** — `claude --plugin-dir ./plugins/<name>`.
- **Validate before pushing** — `claude plugin validate .`

See [AGENTS.md](AGENTS.md) for conventions (`CLAUDE.md` just imports it — see below).

## Agent instructions convention

Repo guidance for AI agents lives in a tool-agnostic [`AGENTS.md`](AGENTS.md), and each
tool's own file imports it. Here, `CLAUDE.md` contains only `@AGENTS.md`. This keeps
instructions in one place and portable across AI tooling — use the same pattern in every
project (the `ai-ready-repo` skill sets it up for you).
