# Installation Guide - Reaper Song Switcher

## 🚀 Quick Install (All Platforms)

### macOS & Linux
```bash
cd ReaperSongSwitcher
bash install.sh
```

### Windows
```
Double-click: install.bat
```

The installer will automatically handle everything!

---

## 📋 Installation Steps

### Step 1: Automatic Installation

Choose the right method for your OS:

**macOS:**
```bash
bash install.sh
```

**Linux:**
```bash
bash install.sh
```

**Windows:**
- Double-click `install.bat`
- Or run from Command Prompt: `install.bat`

### Step 2: Configure setlist.json

1. Navigate to your installed Song Switcher directory:
   - **macOS**: `~/Library/Application Support/REAPER/Scripts/ReaperSongSwitcher/`
   - **Windows**: `%AppData%\REAPER\Scripts\ReaperSongSwitcher\`
   - **Linux**: `~/.config/REAPER/Scripts/ReaperSongSwitcher/`

2. Open `setlist.json` in a text editor

3. Update the `base_path`:
   ```json
   {
     "base_path": "/YOUR/SONGS/PATH/HERE",
     "songs": [...]
   }
   ```

4. **Important Paths:**
   - **macOS/Linux**: Use forward slashes `/` and full paths (e.g., `/Volumes/Drive/Music/Songs`)
   - **Windows**: Use forward slashes `/` or backslashes `\` (e.g., `D:/Music/Songs` or `D:\Music\Songs`)

5. Verify your song paths are correct (relative to base_path)

6. Save the file

### Step 3: Test the Installation

1. Open Reaper
2. Go to: `Actions > Show action list`
3. Search for: "ReaperSongSwitcher"
4. Double-click: `ReaperSongSwitcher/switcher.py`
5. Check Reaper's console for success messages

### Step 4: Verify "End" Markers

Your songs already have "End" markers. Just verify they're placed correctly:

1. Open each song project in Reaper
2. Check the "End" marker position (should be where the song ends)
3. Make sure "End" marker is BEFORE the loop repeats
4. Save projects if needed

---

## 🔧 What the Installer Does

The automatic installer will:

1. **Detect Your OS** - Determines if you're on macOS, Windows, or Linux
2. **Find Reaper Scripts Directory** - Locates where Reaper stores scripts for your OS
3. **Create Directory if Needed** - Creates the Scripts directory if it doesn't exist
4. **Copy Files** - Copies the Song Switcher folder to the Scripts directory
5. **Back Up Old Version** - If upgrading, backs up your previous installation
6. **Verify Installation** - Checks that all files are in place correctly
7. **Print Instructions** - Shows you what to do next

---

## 📍 Installation Locations

### macOS
```
~/Library/Application Support/REAPER/Scripts/ReaperSongSwitcher/
```

### Windows  
```
%AppData%\REAPER\Scripts\ReaperSongSwitcher\
```

### Linux
```
~/.config/REAPER/Scripts/ReaperSongSwitcher/
```

---

## ✅ Post-Installation

After installation, the script will tell you to:

1. ✅ Edit `setlist.json` with your base path
2. ✅ Verify "End" markers in your songs
3. ✅ Test the script in Reaper
4. ✅ (Optional) Configure auto-start in Reaper

---

## 🚨 Troubleshooting Installation

### "Python 3 not found" Error

**macOS/Linux:**
```bash
# Install Python 3
# Option 1: Using Homebrew
brew install python3

# Option 2: Download from python.org
```

**Windows:**
- Download Python from [python.org](https://www.python.org)
- **Important**: Check "Add Python to PATH" during installation
- Run installer again

### "Permission Denied" Error (Linux/macOS)

```bash
# Make the installer executable
chmod +x install.sh

# Then run it
bash install.sh
```

### "Scripts Directory Not Found"

The installer will create it automatically. If it doesn't:

**macOS:**
```bash
mkdir -p ~/Library/Application\ Support/REAPER/Scripts
```

**Windows:**
Create manually: `%AppData%\REAPER\Scripts`

**Linux:**
```bash
mkdir -p ~/.config/REAPER/Scripts
```

Then run the installer again.

### "setlist.json Missing" Error

Make sure you're running the installer from the `ReaperSongSwitcher` folder that contains `setlist.json`.

---

## 🔄 Updating Installation

If you already have Song Switcher installed and want to update:

1. Run the installer again
2. When prompted, select "yes" to update
3. Your old installation will be backed up automatically
4. New files will be installed

---

## ♻️ Manual Installation (If Automatic Fails)

If the automatic installer doesn't work:

1. Find your Reaper Scripts directory (see locations above)
2. Copy the entire `ReaperSongSwitcher` folder there
3. Open Reaper
4. Go to: `Actions > Refresh action list`
5. The script should now appear

---

## 🎮 Using After Installation

### Loading the Script

**Manually each time:**
1. Open Reaper
2. `Actions > Show action list`
3. Search for "ReaperSongSwitcher"
4. Double-click the script

**Auto-start on Reaper launch:**
1. Create/configure an action set with the script
2. `Options > Startup actions`
3. Select your action set
4. Restart Reaper

### Configuring

Edit `setlist.json`:
- Set `base_path` to your songs folder
- Verify song paths
- Save

### Testing

Press Play in Reaper - it should auto-play and switch songs at markers!

---

## 📞 Getting Help

1. Check `QUICKSTART.md` for quick start (5 min setup)
2. Read `README.md` for full documentation
3. Check console for error messages
4. Verify `setlist.json` is correct
5. Verify "End" markers exist and are placed correctly

---

## ✨ That's It!

You should now have Reaper Song Switcher fully installed and ready to use!

**Next Step:** Read `QUICKSTART.md` to get started!
