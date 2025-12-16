#!/usr/bin/env bash
# AI Toolkit - Install to Project
# Run this from the ai-toolkit directory to install into another project

set -euo pipefail

echo "🤖 AI Toolkit - Install to Project"
echo ""

# Check arguments
if [[ $# -eq 0 ]]; then
  echo "Usage: ./install-to-project.sh <target-project-path>"
  echo ""
  echo "Examples:"
  echo "  ./install-to-project.sh ../my-project"
  echo "  ./install-to-project.sh /path/to/project"
  echo ""
  exit 1
fi

TARGET_PROJECT="$1"

# Resolve to absolute path
TARGET_PROJECT=$(cd "$TARGET_PROJECT" && pwd)

echo "Target project: $TARGET_PROJECT"
echo ""

# Check if target exists and is a directory
if [[ ! -d "$TARGET_PROJECT" ]]; then
  echo "❌ Target directory does not exist: $TARGET_PROJECT"
  exit 1
fi

# Check if target is a git repository
if [[ ! -d "$TARGET_PROJECT/.git" ]]; then
  echo "❌ Target is not a git repository: $TARGET_PROJECT"
  exit 1
fi

echo "✓ Target is a git repository"
echo ""

# Check if _ai directory already exists
if [[ -d "$TARGET_PROJECT/_ai" ]]; then
  echo "⚠️  _ai directory already exists in target project"
  read -p "Remove and reinstall? (y/N): " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Removing existing _ai directory..."
    rm -rf "$TARGET_PROJECT/_ai"
  else
    echo "Aborting."
    exit 1
  fi
fi

# Clone this repository as _ai
echo "📦 Cloning ai-toolkit as _ai..."
TOOLKIT_DIR=$(pwd)
git clone "$TOOLKIT_DIR" "$TARGET_PROJECT/_ai"

echo "✓ Cloned ai-toolkit to $TARGET_PROJECT/_ai"
echo ""

# Add _ai/ to .gitignore
GITIGNORE_FILE="$TARGET_PROJECT/.gitignore"

if [[ ! -f "$GITIGNORE_FILE" ]]; then
  echo "📝 Creating .gitignore file..."
  touch "$GITIGNORE_FILE"
fi

if grep -q "^_ai/$" "$GITIGNORE_FILE" 2>/dev/null; then
  echo "✓ _ai/ is already in .gitignore"
else
  echo "➕ Adding _ai/ to .gitignore..."
  echo "" >> "$GITIGNORE_FILE"
  echo "# AI Toolkit directory" >> "$GITIGNORE_FILE"
  echo "_ai/" >> "$GITIGNORE_FILE"
  echo "✓ Added _ai/ to .gitignore"
fi

echo ""

# Check git status to verify _ai is ignored
cd "$TARGET_PROJECT"
if git status --porcelain | grep -q "_ai/"; then
  echo "⚠️  Warning: _ai/ appears in git status (may not be properly ignored)"
  echo "You may need to run: git rm -r --cached _ai/"
else
  echo "✓ _ai/ is properly ignored by git"
fi

echo ""
echo "🎉 Installation complete!"
echo ""
echo "Next steps:"
echo "  1. Configure credentials (if not already done):"
echo "     cp _ai/templates/ai-toolkit-env.template ~/.ai-toolkit-env"
echo "     # Then edit ~/.ai-toolkit-env with your API tokens"
echo ""
echo "  2. Install scripts to your PATH (if not already done):"
echo "     cd _ai/bin && chmod +x *.sh"
echo "     mkdir -p ~/bin && ln -sf \$(pwd)/*.sh ~/bin/"
echo ""
echo "  3. Use workflows with Claude Code:"
echo "     @_ai/workflows/start-work-on-ticket.md Start work on PROJ-123"
echo ""
echo "See _ai/README.md for full documentation"
