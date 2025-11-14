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

REM Create the directories if they don't exist
if not exist "%REAPER_SCRIPTS%" mkdir "%REAPER_SCRIPTS%"
if not exist "%REAPER_SCRIPTS%\modules" mkdir "%REAPER_SCRIPTS%\modules"

REM Copy all scripts
copy "%~dp0switcher.lua" "%REAPER_SCRIPTS%\switcher.lua" >nul
echo ✅ Installed switcher.lua

copy "%~dp0switcher_transport.lua" "%REAPER_SCRIPTS%\switcher_transport.lua" >nul
echo ✅ Installed switcher_transport.lua

copy "%~dp0setlist_editor.lua" "%REAPER_SCRIPTS%\setlist_editor.lua" >nul
echo ✅ Installed setlist_editor.lua

REM Copy all modules
echo.
echo 📦 Installing modules...
for %%f in ("%~dp0modules\*.lua") do (
    copy "%%f" "%REAPER_SCRIPTS%\modules\%%~nf" >nul
    echo ✅ Installed %%~nf
)

REM Copy font if it exists
if exist "%~dp0Hacked-KerX.ttf" (
    copy "%~dp0Hacked-KerX.ttf" "%REAPER_SCRIPTS%\Hacked-KerX.ttf" >nul
    echo ✅ Installed Hacked-KerX.ttf font
)

REM Try to generate fonts list
echo.
echo 📝 Generating font list...
if exist "%~dp0get_fonts.sh" (
    REM On Windows with WSL or Git Bash available
    where bash >nul 2>&1
    if !ERRORLEVEL! equ 0 (
        bash "%~dp0get_fonts.sh" > "%REAPER_SCRIPTS%\fonts_list.txt" 2>nul
        if !ERRORLEVEL! equ 0 (
            for /f %%A in ('type "%REAPER_SCRIPTS%\fonts_list.txt" ^| find /c /v ""') do set FONT_COUNT=%%A
            echo ✅ Generated fonts_list.txt (!FONT_COUNT! fonts^)
        ) else (
            echo ℹ️  Could not generate fonts_list.txt, will use fallback
        )
    ) else (
        REM Bash not available, use pre-generated if it exists
        if exist "%~dp0fonts_list.txt" (
            copy "%~dp0fonts_list.txt" "%REAPER_SCRIPTS%\fonts_list.txt" >nul
            echo ✅ Installed fonts_list.txt
        ) else (
            echo ⚠️  No font list available - system fonts will be auto-detected
        )
    )
) else (
    REM No get_fonts.sh, try pre-generated
    if exist "%~dp0fonts_list.txt" (
        copy "%~dp0fonts_list.txt" "%REAPER_SCRIPTS%\fonts_list.txt" >nul
        echo ✅ Installed fonts_list.txt
    )
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
echo ✅ Installation complete
echo ==================================================
echo.
echo 📝 Next: Edit setlist.json to add your songs
echo    Base path should point to your .rpp project files
echo.
echo 🎵 To use:
echo    - Run switcher_transport.lua from Scripts menu (main UI)
echo    - Or run switcher.lua for headless auto-switch
echo.
pause
