# Reaper Song Switcher

Lua script that automatically switches between Reaper project files during playback.

## What It Does

1. Loads the first song from `setlist.json`
2. Plays it
3. When the song loops back to the start, stops, loads the next song, waits one frame, then plays it
4. Repeats until the last song, then stops

## Setup

### Option 1: Easy Install (Recommended)

**Install:**
```bash
bash install.sh
```

This installs to Reaper's Scripts folder and adds it to the Scripts menu.

### Option 2: Run Anywhere

Copy `switcher.lua` and `setlist.json` to any folder and run `switcher.lua` directly from Reaper's Script menu via `File > Open file` or drag-and-drop into Reaper.

**Configure `setlist.json`:**
```json
{
  "base_path": "/full/path/to/songs",
  "songs": [
    {"name": "Song 1", "path": "song1.rpp"},
    {"name": "Song 2", "path": "song2.rpp"}
  ]
}
```

**Run:**
Load `switcher.lua` from Reaper's Script menu.

## How It Works

The script monitors playback position. When it detects the position jumped backward (song looped), it:
1. Stops playback
2. Opens the next project file
3. Waits one frame (lets Reaper settle)
4. Starts playing

The one-frame wait prevents record mode from triggering.

After the last song loops, playback stops instead of restarting.

## Requirements

- Reaper 6.20+
- Each song project must loop back to start when it ends
- `setlist.json` in same folder as script

