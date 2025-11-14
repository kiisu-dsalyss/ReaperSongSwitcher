# Reaper Song Switcher

Lua scripts for Reaper that automatically switch between project files during live performances.

## What It Does

Automatically switches between project files during live performances by detecting when each song reaches its **End marker**, then loading and playing the next song in the setlist. Manual transport controls (play, stop, skip) let you override or navigate as needed.

## Architecture

Modular Lua design with 9 focused modules:

```
switcher_transport.lua - Main entry point + loop/UI control
├── modules/state.lua - State initialization
├── modules/config.lua - Configuration persistence
├── modules/fonts.lua - Font system integration
├── modules/ui.lua - Dialog rendering
├── modules/ui_components.lua - Main UI components
├── modules/input.lua - Keyboard/mouse input handling
├── modules/playback.lua - Song loading & auto-switch logic
├── modules/setlist.lua - JSON parsing for setlists
└── modules/utils.lua - Logging and helper functions
```

## Scripts Included

### Main Scripts

#### `switcher_transport.lua` (Main UI - Recommended)

Full-featured transport control interface with:

- **Setlist display** - Shows all songs in the queue with current/selected highlighting
- **Transport controls** - Back (<<), Play/Stop, Skip (>>)
- **Loop toggle** - Large button to control intro/main section playback
  - 🟡 Yellow when **LOOP ON** - Plays the intro loop continuously (ambient sound between songs)
  - 🟢 Green pulsing when **LOOP OFF** - Plays the full song from intro through to end, pulses in sync with tempo!
- **Cyberpunk styling** - Dark blue background with neon cyan/magenta/green accents
- **File clicking** - Click any song in the list to select it, then press Play
- **Manual navigation** - Use << and >> buttons to jump songs
- **Font picker** - Gear icon in header to customize UI font and size
- **Auto-switch detection** - Watches for End markers and switches songs automatically

#### `switcher.lua` (Headless Auto-Switch)

Background auto-switch script without UI:

- Pure auto-switching based on loop detection
- No visual feedback
- Use if you prefer minimal overhead or keyboard control

#### `setlist_editor.lua` (Setlist Editor)

Full gfx-based UI editor for managing your setlist:

- Add/edit/delete songs
- Drag to reorder
- File picker for easy path selection
- Automatic backup on save (`setlist.json.bak`)

## Setup

### Option 1: Easy Install (Recommended)

```bash
bash install.sh
```

This installs all scripts and modules to Reaper's Scripts folder.

### Option 2: Manual Setup

Copy all files to:
```
~/Library/Application Support/REAPER/Scripts/ReaperSongSwitcher/
```

**Directory structure after installation:**

```
ReaperSongSwitcher/
├── switcher_transport.lua (main script)
├── switcher.lua
├── setlist_editor.lua
├── config.json
├── setlist.json
├── Hacked-KerX.ttf
└── modules/
    ├── state.lua
    ├── config.lua
    ├── fonts.lua
    ├── ui.lua
    ├── ui_components.lua
    ├── input.lua
    ├── playback.lua
    ├── setlist.lua
    └── utils.lua
```

**Configure `setlist.json`:**

```json
{
  "base_path": "/full/path/to/your/songs",
  "songs": [
    {"name": "Song 1", "path": "song1.rpp"},
    {"name": "Song 2", "path": "song2.rpp"},
    {"name": "Song 3", "path": "song3.rpp"}
  ]
}
```

## Running

### Transport UI (Recommended for Live)

`Scripts > ReaperSongSwitcher > switcher_transport.lua`

Shows a clean transport interface with the big LOOP button and song list.

### Auto-Switch Only

`Scripts > ReaperSongSwitcher > switcher.lua`

Runs silently in the background, no UI.

### Edit Setlist

`Scripts > ReaperSongSwitcher > setlist_editor.lua`

Open to add/edit/reorder songs in your setlist.

## How It Works

**End Marker Detection:**

- Looks for a marker named `"End"` in each project - this marks the exact switch point
- When playback reaches or passes this marker, the script automatically stops and loads the next song
- Also detects if playback stops near the End marker (within 2 seconds) to catch Reaper's auto-stop before the exact marker position
- Waits one frame for the next project to load, then starts playing

**Module Responsibilities:**

- **state.lua** - Initializes all global state variables with safe defaults
- **config.lua** - Loads/saves font configuration from JSON
- **fonts.lua** - Detects and manages system fonts
- **ui.lua** - Renders font picker and setlist load dialogs
- **ui_components.lua** - Draws main UI (header, buttons, song list, loop toggle, transport controls)
- **input.lua** - Handles keyboard and mouse input
- **playback.lua** - Manages song loading and auto-switch detection with End marker logic
- **setlist.lua** - Parses and manages setlist JSON files
- **utils.lua** - Provides logging and UI helper functions

**Important:** Each song project MUST have an `"End"` marker. Without it, that song won't auto-switch and you'll need to manually skip.

## Features

✅ **Automatic song switching** at loop points  
✅ **Manual transport controls** (play, stop, skip, back)  
✅ **Loop toggle** with tempo-synced visual feedback  
✅ **Visual setlist** with current song highlighting  
✅ **Cyberpunk UI** with neon colors  
✅ **File picker** for easy path selection  
✅ **Backup on save** (setlist.json.bak)  
✅ **Keyboard support** in editor (backspace, tab, enter, escape)  
✅ **Drag to reorder** songs in setlist  

## Requirements

- Reaper 6.20+
- `setlist.json` in script folder with correct `base_path`
- **Each song project MUST have an `"End"` marker** to trigger auto-switching

## Troubleshooting

**Songs not switching?**
- Verify each song has an `"End"` marker at the exact switch point
- Check that `setlist.json` has correct `base_path` and song paths (.rpp files exist)
- Ensure LOOP is OFF (green button) to play full songs through to the End marker

**UI looks weird?**

- Reload the script with F5 (or re-run from Scripts menu)
- Check Reaper's dock settings - gfx window should appear as a floating panel

