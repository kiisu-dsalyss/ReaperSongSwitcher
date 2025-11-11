#!/bin/bash
# Reaper Song Switcher Installation Script (macOS & Linux)

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=================================================="
echo "🎵 Reaper Song Switcher - Installer"
echo "=================================================="
echo ""

# Determine OS
if [[ "$OSTYPE" == "darwin"* ]]; then
    REAPER_SCRIPTS="$HOME/Library/Application Support/REAPER/Scripts/ReaperSongSwitcher"
else
    REAPER_SCRIPTS="$HOME/.config/REAPER/Scripts/ReaperSongSwitcher"
fi

echo "📁 Installing to: $REAPER_SCRIPTS"

# Create the directory if it doesn't exist
mkdir -p "$REAPER_SCRIPTS"

# Copy the main script
cp "$SCRIPT_DIR/switcher.lua" "$REAPER_SCRIPTS/switcher.lua"
echo "✅ Installed switcher.lua"

# Copy example setlist if not present
if [ ! -f "$REAPER_SCRIPTS/setlist.json" ]; then
    cp "$SCRIPT_DIR/example_setlist.json" "$REAPER_SCRIPTS/setlist.json"
    echo "✅ Created setlist.json from example"
else
    echo "ℹ️  setlist.json already exists, not overwriting"
fi

echo ""
echo "=================================================="
echo "✅ Installation complete!"
echo "=================================================="
echo ""
echo "📝 Edit setlist.json to add your songs"
echo "🎵 Run switcher.lua from REAPER Scripts menu"
echo ""
