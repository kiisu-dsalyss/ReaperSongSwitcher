# Reaper Song Switcher

A Lua script for automatically switching between songs in a Reaper setlist during live performances. Perfect for backing track-based live sets where you need seamless transitions between pre-arranged songs.

## Features

- **🔄 Automatic Song Switching**: Monitors playback and automatically switches to the next song when the current one loops back to the start
- **🎵 No Recording Trigger**: Works with armed tracks (required for vocal input routing) without accidentally triggering recording
- **⏸️ Clean Stop**: Stops playback after the last song in setlist (doesn't loop back)
- **📁 Relative Path Support**: Portable setlist configuration that works across different systems
- **🎯 Loop Detection**: Automatically detects when a song loops and switches to the next one
- **📝 Console Logging**: Real-time logging for monitoring playback and switches
- **🎤 Live Performance Ready**: Designed for backing track scenarios with armed tracks

## Setup

### 1. Installation

**macOS & Linux:**
```bash
cd ReaperSongSwitcher
bash install.sh
```

**Windows:**
```
Double-click: install.bat
```

### 2. Configuration

Edit `setlist.json`:
```json
{
  "base_path": "/full/path/to/your/songs/folder",
  "songs": [
    {
      "name": "Song 1 Display Name",
      "path": "relative/path/to/song1.rpp"
    },
    {
      "name": "Song 2 Display Name", 
      "path": "relative/path/to/song2.rpp"
    }
  ]
}
```

- **base_path**: Full path to your songs root folder
- **name**: Display name shown in logs
- **path**: Relative path from base_path

### 3. How It Works

1. Load `switcher.lua` from Reaper's Script menu
2. First song automatically loads and starts playing
3. When a song loops (position jumps back to start), the script:
   - Stops playback
   - Loads the next song
   - Waits 1 frame (gives Reaper time to settle)
   - Starts playback
4. After the last song loops, playback stops

### 4. Requirements

- Reaper 6.20+ (tested on recent versions)
- `setlist.json` in the same folder as the script
- Song project files (.rpp) all contain loops that restart from the beginning

## Troubleshooting

**Songs not switching?**
- Check `setlist.json` format is valid
- Verify `base_path` is correct
- Make sure songs loop (position jumps from end back to start)
- Check Reaper console for error messages

**Recording triggers when it shouldn't?**
- The script uses a 1-frame wait after loading before playing to prevent this
- Make sure armed tracks are configured for input, not monitoring

**Script doesn't start?**
- Run `bash install.sh` to reinstall
- Check that switcher.lua is in: `~/Library/Application Support/REAPER/Scripts/ReaperSongSwitcher/` (macOS)


## Usage

### During Performance

1. **Load Script**: Run the switcher script (manually or via auto-start)
2. **First Song Loads**: The script automatically loads the first song in your setlist
3. **Start Playback**: Press play in Reaper
4. **Automatic Transitions**: When the song reaches the "End" marker, the next song loads and plays automatically
5. **Last Song**: After the final song ends, playback stops

### UI Controls

The ImGui dockable window provides:

- **◀ Skip Back**: Jump to the previous song immediately
- **▶ Play / ⏸ Pause**: Control playback
- **Skip Next ▶**: Jump to the next song immediately
- **Setlist Display**: Shows all songs with current song highlighted in green
- **Drag-and-Drop Reordering**: Click and drag songs to reorder (saved automatically)
- **Real-time Status**: Shows current song, playback status, and time position

### Console Output

The Reaper console provides detailed logging:
- Song load/switch events
- End marker detection and timing
- User control actions
- Error messages and warnings

## Troubleshooting

### "End" Marker Not Found

- Verify each song has an "End" marker
- Check that the marker name is exactly "End"
- Songs without "End" markers will log a warning but may not switch properly
- The script will not automatically switch for songs without end markers

### Song Doesn't Load

- Verify the file path in `setlist.json` is correct
- Paths should be relative to your configured `base_path`
- Check that the `.rpp` file exists at that location
- Check Reaper's console for detailed error messages

### Script Doesn't Auto-Start

- Verify the script is in the correct Scripts directory
- Check that startup action is properly configured
- Try manually loading the script to test functionality
- Check Reaper's action list for the script entry

### ImGui Window Not Appearing

- ImGui dockable windows are integrated into Reaper's layout
- The window should appear in the docking system
- If not visible, try: `Window > Dockable windows` and look for "Song Switcher"
- You can dock it alongside other panels

### MIDI Signal Not Working

- The MIDI signal handling is completely separate from this script
- This script handles project switching only
- Verify your MIDI setup in each individual project file
- MIDI will work independently once projects are loaded

### Performance Issues

- Script checks playback position every ~100ms (minimal overhead)
- ImGui rendering is lightweight and doesn't impact audio
- If you experience stuttering, check your Reaper buffer settings

## File Structure

```
ReaperSongSwitcher/
├── switcher.py           # Main script
├── setlist.json          # Your setlist (pre-populated)
├── example_setlist.json  # Template for reference
└── README.md             # This file
```

## JSON Setlist Format

```json
{
  "songs": [
    {
      "name": "Song Display Name",
      "path": "Relative/Path/To/Project.rpp"
    }
  ]
}
```

**Path Format**:
- Use forward slashes `/` even on Windows
- Paths are relative to `/Volumes/Big Fatty/Sync/DSALYSS-LIVE-SYNC/`
- Example: `CircuitsReduxLive/CircuitsStemmed.RPP`
- Paths with spaces are fully supported

## Behavior Details

### Playback Flow

1. Script initializes and loads first song from setlist
2. First song project opens in Reaper  
3. Playback starts automatically
4. Script monitors playback position against the "End" marker
5. When playback reaches/exceeds the "End" marker:
   - Current playback stops
   - Next song loads and opens  
   - Next song playback starts automatically
   - Loop repeats
6. After final song ends, playback stops

### Error Handling

| Scenario | Behavior |
|----------|----------|
| Missing setlist.json | Script alerts and stops |
| Invalid JSON format | Script alerts with parse error |
| Song file not found | Script pauses playback and alerts |
| No "End" marker found | Script logs warning, continues without automatic switching |
| File access error | Script pauses and displays error message |

### Settings Impact

- **Base Path**: Your configured songs folder (set in setlist.json)
- **Update Interval**: ~100ms (checks per frame)
- **UI Window Name**: "Song Switcher"
- **Path Resolution**: Relative paths from base path

## Notes for Live Performance

- **Test beforehand**: Test your entire setlist before going live
- **Verify markers**: Confirm each song has an accurate "End" marker
- **Allow startup time**: Leave 1-2 seconds before your first song starts
- **Monitor console**: Keep the console visible to catch any alerts
- **Backup plan**: Have a manual song-switching method ready
- **MIDI independent**: Your MIDI signal system operates independently

## Advanced: Custom Configuration

Edit `setlist.json` to:
- Update the `base_path` to your songs folder
- Add or remove songs from the `songs` array
- Change song names for UI display
- Reorder songs by reordering the array

The update frequency is controlled by the defer loop (currently ~100ms per check in the `update()` method).

## Version History

- **v1.0** - Initial release with auto-switching, relative paths, ImGui UI, skip controls, and setlist reordering

## License

Created for live performance backing track automation.

## Support

For issues or questions:
1. Check the console output for detailed error messages
2. Verify marker names and file paths
3. Test song loading manually before live performance
4. Ensure MIDI setup is independent and working

