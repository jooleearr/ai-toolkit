# AI Toolkit - Copilot Instructions

## Project Overview

This is a **personal AI resource library** — a curated collection of reusable AI templates, prompts, custom agent configurations, and workflows. The repository is designed to be cloned into other projects as a `_ai` directory, providing quick access to standardized AI resources without recreating them from scratch.

## Tech Stack

- **Format**: Markdown-based documentation and configuration files
- **Version Control**: Git
- **Usage Pattern**: Clone-and-reference library (not a standalone application)

## Project Structure

```
ai-toolkit/
├── .github/
│   └── copilot-instructions.md    # This file
├── .gitignore                      # Prevents _ai directory from being committed in parent projects
├── README.md                       # Main documentation
├── prompts/                        # Reusable prompt templates
├── agents/                         # Custom agent configurations
├── templates/                      # Code and documentation templates
└── workflows/                      # Common AI-assisted workflows
```

## Key Principles

1. **This is a resource library, not an application** - There are no build steps, dependencies, or tests to run
2. **Documentation-first** - All resources should be well-documented and self-explanatory
3. **Portability** - Resources should be generic enough to work across different projects
4. **Organization** - Keep resources categorized by type (prompts, agents, templates, workflows)

## Working with This Repository

### Adding New Resources

- Place files in the appropriate directory based on type
- Use clear, descriptive filenames (kebab-case preferred)
- Include inline documentation or comments explaining usage
- Consider adding README.md files in subdirectories if they contain multiple related resources

### The .gitignore File

The `.gitignore` is specifically designed to prevent the `_ai` directory from being committed when this repo is cloned into other projects. It's a critical file — be careful when modifying it.

### Commit Conventions

- Use conventional commits format: `type(scope): description`
- Common types: `feat`, `docs`, `chore`, `fix`
- Example: `feat(prompts): add code review template`

## Common Tasks

### Adding a new prompt template
- Create a `.md` file in `/prompts`
- Use clear headings and structure
- Include usage examples

### Adding a custom agent configuration
- Place configuration files in `/agents`
- Document agent purpose, capabilities, and invocation method

### Adding a template
- Place in `/templates` directory
- Include inline comments explaining customization points

### Adding a workflow
- Document step-by-step processes in `/workflows`
- Include any relevant commands or tool configurations

## Important Notes

- **No build process** - This is a documentation/configuration repository
- **No dependencies** - Resources should be self-contained
- **No tests** - Validation happens through usage in real projects
- **Keep it simple** - The goal is quick reference and reuse, not complexity
- **New Zealand based** - no american spelling
