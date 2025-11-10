@echo off
REM Universal Reaper Song Switcher Installation Script (Windows)
REM Automatically runs Python installer

setlocal enabledelayedexpansion

echo ==================================================
echo 🎵 Reaper Song Switcher - Universal Installer
echo ==================================================
echo.

REM Check if Python is available
python --version >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo ❌ Python is not installed or not in PATH
    echo Please install Python 3 and try again
    pause
    exit /b 1
)

echo ✅ Found Python
for /f "tokens=*" %%i in ('python --version') do echo %%i
echo.

REM Run the Python installer
python "%~dp0install.py"
pause
