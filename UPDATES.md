# ✅ Reaper Song Switcher - Updated & Universal

## 🎉 What's New (v1.1)

Your Reaper Song Switcher has been updated to be **truly portable across machines**!

### Major Updates

✅ **Universal Base Path** - Now reads from `setlist.json` instead of being hardcoded  
✅ **Automatic Installer** - Universal installation script for macOS, Windows, and Linux  
✅ **Portable Configuration** - Works on any machine with any file structure  
✅ **Start/End Markers** - Your songs already have both markers in place  
✅ **Better Documentation** - New INSTALLATION.md guide  

---

## 🚀 Quick Install

### macOS & Linux
```bash
cd ReaperSongSwitcher
bash install.sh
```

### Windows
```
Double-click: install.bat
```

**That's it!** The installer handles everything automatically.

---

## ⚙️ Configuration (Portable!)

### The Key Change: base_path in setlist.json

**Before** (hardcoded):
```python
self.base_path = Path("/path/to/songs")  # Hardcoded - not portable
```

**Now** (configurable):
```json
{
  "base_path": "/your/songs/folder/here",
  "songs": [...]
}
```

### Setup Steps

1. **Run the installer** (above)
2. **Edit setlist.json**:
   - Set `base_path` to YOUR songs folder
   - Use forward slashes `/` on all platforms
   - Examples:
     - **macOS**: `/Volumes/MyDrive/Music/Songs`
     - **Windows**: `D:/Music/MySongs` or `D:\Music\MySongs`
     - **Linux**: `/home/user/music/songs` or `/mnt/MyDrive/songs`

3. **Verify song paths** (relative to base_path)

4. **Done!** The script will work on any machine

## 📋 Files Included

### Core
- **`switcher.py`** (518 lines) - Main script with updated path handling
- **`setlist.json`** - Configuration with base_path (UPDATE THIS!)
- **`example_setlist.json`** - Template

### Installation
- **`install.py`** (273 lines) - Universal Python installer
- **`install.sh`** - macOS/Linux installer (executable)
- **`install.bat`** - Windows installer

### Documentation
- **`INSTALLATION.md`** - Complete installation guide
- **`QUICKSTART.md`** - 5-minute quick start
- **`README.md`** - Full reference
- **`TECHNICAL.md`** - Architecture details
- **`DELIVERY.md`** - Delivery checklist
- **`SUMMARY.md`** - Project overview
- **`PROJECT_OVERVIEW.md`** - Visual overview

---

## 🔧 Key Technical Changes

### 1. base_path Now Dynamic

**Old code:**
```python
self.base_path = Path("/Volumes/Big Fatty/Sync/DSALYSS-LIVE-SYNC")
```

**New code:**
```python
self.base_path = None  # Loaded from JSON
# In load_setlist():
self.base_path = Path(data["base_path"])
```

### 2. setlist.json Format Updated

**Old format:**
```json
{
  "songs": [...]
}
```

**New format:**
```json
{
  "base_path": "/your/path/here",
  "description": "Optional notes",
  "songs": [...]
}
```

### 3. Portable Path Handling

```python
def resolve_path(self, relative_path):
    """Works on any OS with any base_path"""
    if os.path.isabs(relative_path):
        return relative_path
    return os.path.join(str(self.base_path), relative_path)
```

---

### Portable Example

Users can now share the same setlist structure across different machines by just changing the `base_path`:

```json
{
  "base_path": "/path/to/your/songs",
  "songs": [...]
}
```

Each user sets their own `base_path` - the song list stays the same!

---

## 📝 Installation Process

### Automatic (Recommended)

1. Run the installer for your OS
2. It automatically:
   - Detects your operating system
   - Finds/creates your Reaper Scripts directory
   - Copies all files
   - Verifies everything
   - Backs up old versions
   - Prints next steps

### Manual (If Needed)

1. Copy `ReaperSongSwitcher` folder to Reaper Scripts directory
2. See INSTALLATION.md for directory locations
3. Edit `setlist.json` with your base_path
4. Done!

---

## ✨ Features Maintained

All existing features still work perfectly:

✅ Automatic song switching at "End" markers  
✅ Auto-play first song  
✅ No-gap switching  
✅ ImGui dockable UI  
✅ Skip forward/backward buttons  
✅ Drag-and-drop reordering  
✅ Auto-save setlist changes  
✅ Console logging  
✅ Error alerts  
✅ MIDI independence  

---

## 🎵 Your Songs

Your songs already have **"Start" and "End" markers** in place!

Just verify:
1. "End" marker is at the right song end point
2. "End" marker is BEFORE the loop repeats
3. Marker name is exactly "End"

---

## 🚨 Migration from Old Version

If you were using the old hardcoded version:

1. **Install the new version** (see Quick Install above)
2. **Update setlist.json**:
   - Old format had absolute paths
   - New format uses `base_path` + relative paths
   - Edit the file with your base_path
3. **All your songs will still work!**

---

## 💡 Platform Compatibility

### macOS
- ✅ Automatic installer: `bash install.sh`
- ✅ Paths: `/Volumes/...` or `/Users/...`
- ✅ Tested and working

### Windows
- ✅ Automatic installer: Double-click `install.bat`
- ✅ Paths: `D:/Music/...` or `D:\Music\...`
- ✅ Requires Python 3 (installer checks for it)
- ✅ Requires admin privileges (may need to run as admin)

### Linux
- ✅ Automatic installer: `bash install.sh`
- ✅ Paths: `/home/...` or `/mnt/...`
- ✅ Requires Python 3
- ✅ Works with all distributions

---

## 📊 What Changed

| Aspect | Before | After |
|--------|--------|-------|
| Base path | Hardcoded | In JSON |
| Portability | Single machine | Any machine |
| Installation | Manual copy | Automatic script |
| Configuration | Edit Python code | Edit JSON |
| Multi-machine | ❌ No | ✅ Yes |
| Installer | ❌ None | ✅ 3 platforms |

---

## ✅ Next Steps

1. **Run the installer** for your OS (see Quick Install)
2. **Edit setlist.json** - Set your base_path
3. **Test in Reaper** - Load script and press play
4. **Go live!** - All songs will auto-switch perfectly

---

## 🎤 Ready to Share

Your system is now ready to:
- Share with band members
- Use on different machines
- Store songs in different locations
- Work without any manual configuration

**Just update base_path and go!**

---

## 📞 Support

- **Quick Start**: See `QUICKSTART.md`
- **Installation**: See `INSTALLATION.md`
- **Full Docs**: See `README.md`
- **Technical**: See `TECHNICAL.md`

---

## 🎵 Version Info

- **Version**: 1.1 (Universal & Portable)
- **Update Date**: November 10, 2025
- **Status**: ✅ Production Ready
- **Platforms**: macOS, Windows, Linux

---

**Your Song Switcher is now truly universal!** 🚀
