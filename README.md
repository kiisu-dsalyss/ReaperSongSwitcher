# Reaper Song Switcher

A Python-based script for automatically switching between songs in a Reaper setlist during live performances. Perfect for backing track-based live sets where you need seamless transitions between pre-arranged songs.

## Features

- **🔄 Automatic Song Switching**: Monitors playback and automatically switches to the next song when the current one reaches its end marker
- **🎵 ImGui Dockable UI**: Professional dockable window with real-time status and intuitive controls
- **⏩⏪ Skip Controls**: Skip forward/backward through your setlist during performance
- **🎶 Setlist Reordering**: Reorder songs during the performance via drag-and-drop (changes are saved)
- **📁 Relative Path Support**: Portable setlist configuration that works across different systems
- **🎯 End Marker Detection**: Uses Reaper markers to determine exact song end points
- **❌ Error Handling**: Automatically pauses and alerts when file loading issues occur
- **📝 Console Logging**: Detailed real-time logging for debugging and monitoring
- **🎤 Live Performance Ready**: Designed for backing track scenarios with external MIDI signal handling

## Setup

### 1. Automatic Installation (Recommended)

**macOS & Linux:**
```bash
cd ReaperSongSwitcher
bash install.sh
```

**Windows:**
```
Double-click: install.bat
```

The installer will:
- Automatically detect your OS
- Find or create your Reaper Scripts directory
- Copy the Song Switcher folder
- Verify all files are in place
- Provide next steps

### 2. Manual Installation

If the automatic installer doesn't work:

1. Copy the entire `ReaperSongSwitcher` folder to your Reaper Scripts directory:
   - **macOS**: `~/Library/Application Support/REAPER/Scripts/`
   - **Windows**: `%AppData%\REAPER\Scripts\`
   - **Linux**: `~/.config/REAPER/Scripts/`

### 3. Setlist Configuration

1. Edit the `setlist.json` file:
   ```json
   {
     "base_path": "/path/to/your/songs/folder",
     "songs": [
       {
         "name": "Display Name",
         "path": "Relative/Path/To/song.rpp"
       }
     ]
   }
   ```
   - **base_path**: Full path to your songs root folder (use forward slashes even on Windows)
   - **name**: Display name shown in the UI and logs
   - **path**: Relative path from base_path

2. Example configuration:
   ```json
   {
     "base_path": "/path/to/your/songs",
     "songs": [
       {
         "name": "Song Name",
         "path": "Song Folder/song_file.RPP"
       }
     ]
   }
   ```

### 3. Song Project Setup

For each song project file (`.rpp`):

1. Open the project in Reaper
2. Add a marker at the exact point where the song ends (before any loop)
3. **Name the marker `End`** (case-insensitive)
4. Save the project

**Example**: If your song is 3:45 long with a loop at the start, place the "End" marker at position 3:45.

### 4. Auto-Start Configuration

To have the script automatically run when you open Reaper:

1. In Reaper: `Actions > Show action list...`
2. Create a new action set that loads the switcher script
3. In `Options > Startup actions`, add your script action

Or manually each session:
1. `Script > Load ReaperSongSwitcher/switcher.py`
2. The script will auto-load the first song and begin waiting for playback

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

