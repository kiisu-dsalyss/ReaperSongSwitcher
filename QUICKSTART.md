# Reaper Song Switcher - Quick Start Guide

## 🚀 Installation (5 minutes)

### Automatic Installation (Easiest)

**macOS & Linux:**
```bash
cd ReaperSongSwitcher
bash install.sh
```

**Windows:**
```
Double-click: install.bat
```

The installer will automatically:
- Detect your operating system
- Find your Reaper Scripts directory
- Copy all files to the correct location
- Verify everything is in place

### If Automatic Installation Fails

See README.md for manual installation instructions.

---

## ⚙️ Configuration (5 minutes)

### Step 1: Configure setlist.json

1. Open `setlist.json` in a text editor
2. Change `"base_path"` to your songs folder:
   ```json
   {
     "base_path": "/path/to/your/songs/folder",
     ...
   }
   ```
3. **Important**: Use forward slashes `/` even on Windows
4. **Example (macOS/Linux)**:
   ```json
   "base_path": "/Volumes/Music/MySongs"
   ```
5. **Example (Windows)**:
   ```json
   "base_path": "D:/Music/MySongs"
   ```
6. Verify the song paths are correct (relative to base_path)
7. Save the file

### Step 2: Verify End Markers

Your songs already have "Start" and "End" markers. Just verify:

1. Open each song project in Reaper
2. Check that the "End" marker is placed where the song should switch
3. "End" marker should be before the loop repeats
4. Save the projects

---

## ✅ Testing (5 minutes)

### Test 1: Load the Script

1. Open Reaper
2. Go to: `Actions > Show action list`
3. Search for: "switcher"
4. Double-click: `ReaperSongSwitcher/switcher.py`
5. You should see messages in the console

### Test 2: Check Console Output

Look for these messages (in Reaper's console):
```
[SongSwitcher] Reaper Song Switcher Initialized
[SongSwitcher] Setlist loaded: 5 songs
[SongSwitcher] Loading song 1/5: Song Name
[SongSwitcher] End marker found at: 03:45
[SongSwitcher] Starting playback
```

If you see errors:
- Verify base_path in setlist.json is set correctly
- Verify song file paths exist
- Check that .rpp files are readable

### Test 3: Test Playback

1. Press Play in Reaper
2. First song should start playing
3. When it reaches the "End" marker, next song should load
4. Next song should start playing automatically
5. Repeat until the end of the setlist
6. After final song, playback should stop

---

## 🎮 Using the UI

### Song Switcher Window

The dockable ImGui window shows:

- **Current Song**: Green text showing what's playing
- **Status**: Playing or Stopped
- **Position**: Song number and time
- **Controls**: 
  - `◀ Skip Back` - Previous song
  - `▶ Play` - Start playback
  - `Skip Next ▶` - Next song
- **Song List**: All songs with current highlighted

### Drag to Reorder

- Click and drag songs in the list
- Changes save automatically
- Great for adapting your performance on the fly!

---

## 🎤 Going Live

### Before Performance

1. Test the complete setlist start-to-finish
2. Verify all "End" markers are accurate
3. Make sure all song files load without errors
4. Check that MIDI signal system is working independently

### During Performance

1. Load the script manually, or...
2. Set it to auto-start (see Optional Setup below)
3. Monitor the console for any errors
4. Use skip buttons if needed
5. Reorder songs if performance changes

### Optional: Auto-Start

To make the script load automatically when you open Reaper:

1. Create a Reaper action set with the switcher
2. Go to: `Options > Startup actions`
3. Select your action set
4. Close and restart Reaper - it will auto-load!

---

## ⚠️ Troubleshooting

### "base_path" Error
- Check that base_path in setlist.json is correct
- Verify the folder exists
- Use full paths, not relative ones

### "Song file not found"
- Verify the file path in setlist.json
- Make sure path is relative from base_path
- Check that .rpp files exist

### "End marker not found" Warning
- The marker exists, but may need verification
- Check marker is named exactly "End"
- Make sure marker is at correct song end point

### Song doesn't switch automatically
- Check that End marker is placed correctly
- Verify marker name is exactly "End"
- Ensure song reaches the marker during playback

### Window doesn't appear
- The window should dock in Reaper's layout
- Try: `Window > Dockable windows` and look for "Song Switcher"
- Dock it alongside other panels

---

## 📋 After Installation

Your folder structure will look like:

```
~/Reaper Scripts/ReaperSongSwitcher/
├── switcher.py          ← Main script
├── setlist.json         ← Your configuration (EDIT THIS!)
├── install.py           ← Installer (can delete)
├── install.sh           ← macOS/Linux installer (can delete)
├── install.bat          ← Windows installer (can delete)
├── README.md            ← Full documentation
└── [other docs]
```

---

## 🎵 You're Ready!

That's it! You now have a fully functional live performance backing track switcher.

**Next time you use Reaper:**
1. Load the script (manually or via auto-start)
2. Press Play
3. Enjoy seamless song transitions! 🎤

---

## 💡 Pro Tips

- Test with just one or two songs first
- Keep Reaper's console visible during performance
- Drag-and-drop reordering is perfect for adapting mid-performance
- Your MIDI signal system works independently
- Have a backup way to manually switch songs

---

**Questions?** See README.md for detailed documentation.
