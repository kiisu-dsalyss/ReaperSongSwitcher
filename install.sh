#!/bin/bash
# Universal Reaper Song Switcher Installation Script (macOS & Linux)
# Automatically detects OS and runs Python installer

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=================================================="
echo "🎵 Reaper Song Switcher - Universal Installer"
echo "=================================================="
echo ""

# Check if Python 3 is available
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is not installed or not in PATH"
    echo "Please install Python 3 and try again"
    exit 1
fi

echo "✅ Found Python 3: $(python3 --version)"
echo ""

# Run the Python installer
python3 "$SCRIPT_DIR/install.py"
