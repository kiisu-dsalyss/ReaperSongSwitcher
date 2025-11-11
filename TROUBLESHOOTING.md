# Troubleshooting: Song Switcher Not Showing Up in Reaper

## The Problem

Reaper doesn't automatically recognize `.py` Python scripts in the Scripts folder without the Python extension installed.

## Solution: Install Python Extension

### Step 1: Check if Python Extension is Installed

1. Open Reaper
2. Go to **Options > Show REAPER resource path in explorer/finder**
3. Look for a folder called `UserPlugins` - if it exists and has Python stuff, you're good
4. If not, proceed to Step 2

### Step 2: Install Reaper Python Extension

**Option A: From ReaPack (Easiest)**
1. Open Reaper
2. Go to **Extensions > ReaPack > Browse packages**
3. Search for **"Python"**
4. Look for **"JSFX: Python for ReaScript"** or **"cfillion/reaper-python"**
5. Install it
6. Restart Reaper

**Option B: Manual Install**
1. Visit: https://github.com/cfillion/reaper-python/releases
2. Download the latest macOS release (`.dmg` file)
3. Open it and follow the installation instructions
4. Restart Reaper

### Step 3: Try Again

Once Python is installed:

1. Open Reaper
2. Go to **Actions > Show action list**
3. Search for: `switcher`
4. Double-click the action to run

You should now see the Song Switcher UI window!

---

## Alternative: Use the Lua Wrapper

If you don't want to install Python extension yet:

1. Open Reaper
2. Go to **Actions > Show action list**
3. Search for: `switcher.lua`
4. If you see it, try running it (it will tell you if Python is missing)

---

## Still Not Showing?

### Check the Console
1. Go to **View > Show ReaScript console**
2. Look for error messages
3. Common errors:
   - `Python extension not found` → Install Python extension
   - `setlist.json not found` → Run the installer again
   - `No module named reaper_python` → Python extension not loaded

### Reinstall
```bash
cd /Users/kiisu/repos/ReaperSongSwitcher
bash install.sh
```

---

## Quick Verification Checklist

✅ Python 3 installed on your system  
✅ Reaper Python extension installed  
✅ Song Switcher installed to Scripts folder  
✅ setlist.json exists in Scripts/ReaperSongSwitcher/  
✅ Reaper restarted after installation  

---

## Need Help?

Check the installed documentation:
- **README.md** - Full documentation
- **TECHNICAL.md** - Technical details
- **QUICKSTART.md** - Quick start guide

All located in: `~/Library/Application Support/REAPER/Scripts/ReaperSongSwitcher/`
