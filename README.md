# Reaper Song Switcher

Lua scripts for Reaper that automatically switch between project files during live performances.

## What It Does

1. Loads the first song from `setlist.json`
2. Plays it
3. When the song loops back to the start, stops, loads the next song, waits one frame, then plays it
4. Repeats until the last song, then stops

## Scripts Included

### `switcher_transport.lua` (Main UI - Recommended)
Full-featured transport control interface with:

- **Setlist display** - Shows all songs in the queue with current/selected highlighting
- **Transport controls** - Back (<<), Play/Stop, Skip (>>)
- **Loop toggle** - Large button to control intro/main section playback
  - 🟡 Yellow when **LOOP ON** - Plays the intro loop continuously (ambient sound between songs)
  - 🟢 Green pulsing when **LOOP OFF** - Plays the full song from intro through to end, pulses in sync with tempo!
- **Cyberpunk styling** - Dark blue background with neon cyan/magenta/green accents
- **File clicking** - Click any song in the list to select it, then press Play
- **Manual navigation** - Use << and >> buttons to jump songs

### `switcher.lua` (Headless Auto-Switch)
Background auto-switch script without UI:
- Pure auto-switching based on loop detection
- No visual feedback
- Use if you prefer minimal overhead or keyboard control

### `setlist_editor.lua` (Setlist Editor)
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

This installs all scripts to Reaper's Scripts folder.

### Option 2: Manual Setup

Copy all `.lua` files and `setlist.json` to:
```
~/Library/Application Support/REAPER/Scripts/ReaperSongSwitcher/
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

The script monitors playback position. When it detects the position jumped backward (song looped), it:
1. Stops playback
2. Opens the next project file
3. Waits one frame (lets Reaper settle)
4. Starts playing

The one-frame wait prevents accidental record mode triggering.

After the last song loops, playback stops instead of restarting (or cycles back to song 1 if loop is enabled).

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
- Each song project must loop back to start when it ends
- `setlist.json` in script folder with proper `base_path`

## Troubleshooting

**Songs not switching?**

- Make sure loop is disabled (LOOP OFF - green button) to play full songs
- Check that `setlist.json` has correct `base_path` and paths to .rpp files
- Verify each song project has the intro loop set up properly

**UI looks weird?**

- Reload the script with F5 (or re-run from Scripts menu)
- Check Reaper's dock settings - gfx window should appear as a floating panel

