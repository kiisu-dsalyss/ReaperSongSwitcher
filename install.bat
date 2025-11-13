@echo off
REM Reaper Song Switcher Installation Script (Windows)

setlocal enabledelayedexpansion

echo ==================================================
echo 🎵 Reaper Song Switcher - Installer
echo ==================================================
echo.

REM Get Reaper Scripts directory
set "REAPER_SCRIPTS=%APPDATA%\REAPER\Scripts\ReaperSongSwitcher"

echo Installing to: %REAPER_SCRIPTS%
echo.

REM Create the directory if it doesn't exist
if not exist "%REAPER_SCRIPTS%" mkdir "%REAPER_SCRIPTS%"

REM Copy all scripts
copy "%~dp0switcher.lua" "%REAPER_SCRIPTS%\switcher.lua" >nul
echo ✅ Installed switcher.lua

copy "%~dp0switcher_transport.lua" "%REAPER_SCRIPTS%\switcher_transport.lua" >nul
echo ✅ Installed switcher_transport.lua

copy "%~dp0setlist_editor.lua" "%REAPER_SCRIPTS%\setlist_editor.lua" >nul
echo ✅ Installed setlist_editor.lua

REM Copy font if it exists
if exist "%~dp0Hacked-KerX.ttf" (
    copy "%~dp0Hacked-KerX.ttf" "%REAPER_SCRIPTS%\Hacked-KerX.ttf" >nul
    echo ✅ Installed Hacked-KerX.ttf font
)

REM Copy example setlist if not present
if not exist "%REAPER_SCRIPTS%\setlist.json" (
    copy "%~dp0example_setlist.json" "%REAPER_SCRIPTS%\setlist.json" >nul
    echo ✅ Created setlist.json from example
) else (
    echo ℹ️  setlist.json already exists, not overwriting
)

echo.
echo ==================================================
echo ✅ Installation complete!
echo ==================================================
echo.
echo 📝 Edit setlist.json to add your songs
echo 🎵 Run switcher_transport.lua from REAPER Scripts menu (recommended)
echo 🎵 Or run switcher.lua for headless auto-switching
echo.
pause
