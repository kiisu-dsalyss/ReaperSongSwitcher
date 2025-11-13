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

# Copy all scripts
cp "$SCRIPT_DIR/switcher.lua" "$REAPER_SCRIPTS/switcher.lua"
echo "✅ Installed switcher.lua"

cp "$SCRIPT_DIR/switcher_transport.lua" "$REAPER_SCRIPTS/switcher_transport.lua"
echo "✅ Installed switcher_transport.lua"

cp "$SCRIPT_DIR/setlist_editor.lua" "$REAPER_SCRIPTS/setlist_editor.lua"
echo "✅ Installed setlist_editor.lua"

# Copy font if it exists
if [ -f "$SCRIPT_DIR/Hacked-KerX.ttf" ]; then
    cp "$SCRIPT_DIR/Hacked-KerX.ttf" "$REAPER_SCRIPTS/Hacked-KerX.ttf"
    echo "✅ Installed Hacked-KerX.ttf font"
fi

# Copy helper script and generate fonts list
if [ -f "$SCRIPT_DIR/get_fonts.sh" ]; then
    cp "$SCRIPT_DIR/get_fonts.sh" "$REAPER_SCRIPTS/get_fonts.sh"
    chmod +x "$REAPER_SCRIPTS/get_fonts.sh"
    echo "✅ Installed get_fonts.sh"
    
    # Generate fonts_list.txt
    if sh "$REAPER_SCRIPTS/get_fonts.sh" > "$REAPER_SCRIPTS/fonts_list.txt" 2>&1; then
        FONT_COUNT=$(wc -l < "$REAPER_SCRIPTS/fonts_list.txt")
        echo "✅ Generated fonts_list.txt ($FONT_COUNT fonts)"
    else
        echo "⚠️  Could not generate fonts_list.txt, will use fallback list"
    fi
fi

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
echo "🎵 Run switcher_transport.lua from REAPER Scripts menu (recommended)"
echo "🎵 Or run switcher.lua for headless auto-switching"
echo ""
