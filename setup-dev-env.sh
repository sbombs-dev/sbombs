#!/bin/bash
# Setup script for SBOMBS development environment
# This installs local Git hooks and configures the environment

set -e

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Setting up SBOMBS development environment..."
echo ""

# Configure Git hooks
echo "📝 Configuring Git hooks..."
git config core.hooksPath .git-hooks

# Make pre-commit hook executable
chmod +x "$REPO_ROOT/.git-hooks/pre-commit"

echo "✅ Git hooks configured"
echo ""

# Install Python dev dependencies (optional)
if command -v pip &> /dev/null; then
    echo "📦 Installing Python dev dependencies..."
    pip install -e ".[dev]" 2>/dev/null || {
        echo "⚠️  Could not install Python dependencies. Run manually:"
        echo "   pip install -e '.[dev]'"
    }
    echo "✅ Python dependencies installed"
    echo ""
fi

# Install Node.js dev dependencies (optional)
if command -v npm &> /dev/null; then
    echo "📦 Installing Node.js dev dependencies for canaries..."
    for pkg in canaries/npm/canary-nightly canaries/npm/canary-anchor; do
        if [[ -d "$REPO_ROOT/$pkg" ]]; then
            (cd "$pkg" && npm ci --silent) || echo "⚠️  Could not install npm deps for $pkg"
        fi
    done
    echo "✅ Node.js dependencies installed"
    echo ""
fi

echo "🎉 Development environment setup complete!"
echo ""
echo "Next steps:"
echo "  1. Read CONTRIBUTING.md for development guidelines"
echo "  2. Read VERSION_CONTROL.md to understand versioning strategy"
echo "  3. Run 'pytest tests/' to verify the test suite"
echo ""
