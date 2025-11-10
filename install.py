#!/usr/bin/env python3
"""
Universal Reaper Song Switcher Installation Script

Detects OS and Reaper installation, then installs the switcher script.
Supports: macOS, Windows, Linux
"""

import os
import sys
import shutil
import platform
import subprocess
import json
from pathlib import Path


class ReaperInstaller:
    """Handles installation of Song Switcher to Reaper Scripts directory"""
    
    def __init__(self):
        self.os_type = platform.system()
        self.reaper_scripts_dir = None
        self.script_source = Path(__file__).parent.resolve()
        
    def log(self, message):
        """Print message with formatting"""
        print(f"[Installer] {message}")
    
    def log_success(self, message):
        """Print success message"""
        print(f"✅ {message}")
    
    def log_error(self, message):
        """Print error message"""
        print(f"❌ {message}")
    
    def log_info(self, message):
        """Print info message"""
        print(f"ℹ️  {message}")
    
    def detect_os(self):
        """Detect operating system"""
        self.log(f"Detected OS: {self.os_type}")
        return self.os_type
    
    def find_reaper_scripts_directory(self):
        """Find or create Reaper Scripts directory based on OS"""
        
        if self.os_type == "Darwin":  # macOS
            return self._find_macos_scripts_dir()
        elif self.os_type == "Windows":
            return self._find_windows_scripts_dir()
        elif self.os_type == "Linux":
            return self._find_linux_scripts_dir()
        else:
            self.log_error(f"Unsupported OS: {self.os_type}")
            return None
    
    def _find_macos_scripts_dir(self):
        """Find Reaper Scripts directory on macOS"""
        self.log("Looking for Reaper Scripts directory (macOS)...")
        
        home = Path.home()
        scripts_dir = home / "Library" / "Application Support" / "REAPER" / "Scripts"
        
        if scripts_dir.exists():
            self.log_success(f"Found Reaper Scripts directory: {scripts_dir}")
            return scripts_dir
        else:
            self.log_info(f"Scripts directory doesn't exist, will create: {scripts_dir}")
            return scripts_dir
    
    def _find_windows_scripts_dir(self):
        """Find Reaper Scripts directory on Windows"""
        self.log("Looking for Reaper Scripts directory (Windows)...")
        
        appdata = os.getenv("APPDATA")
        if not appdata:
            self.log_error("Could not find APPDATA environment variable")
            return None
        
        scripts_dir = Path(appdata) / "REAPER" / "Scripts"
        
        if scripts_dir.exists():
            self.log_success(f"Found Reaper Scripts directory: {scripts_dir}")
            return scripts_dir
        else:
            self.log_info(f"Scripts directory doesn't exist, will create: {scripts_dir}")
            return scripts_dir
    
    def _find_linux_scripts_dir(self):
        """Find Reaper Scripts directory on Linux"""
        self.log("Looking for Reaper Scripts directory (Linux)...")
        
        home = Path.home()
        scripts_dir = home / ".config" / "REAPER" / "Scripts"
        
        if scripts_dir.exists():
            self.log_success(f"Found Reaper Scripts directory: {scripts_dir}")
            return scripts_dir
        else:
            self.log_info(f"Scripts directory doesn't exist, will create: {scripts_dir}")
            return scripts_dir
    
    def install_script(self):
        """Install the Song Switcher to Reaper Scripts directory"""
        
        # Find Reaper Scripts directory
        self.reaper_scripts_dir = self.find_reaper_scripts_directory()
        if not self.reaper_scripts_dir:
            return False
        
        # Create Scripts directory if it doesn't exist
        try:
            self.reaper_scripts_dir.mkdir(parents=True, exist_ok=True)
            self.log_success(f"Scripts directory ready: {self.reaper_scripts_dir}")
        except Exception as e:
            self.log_error(f"Failed to create Scripts directory: {e}")
            return False
        
        # Define destination directory
        dest_dir = self.reaper_scripts_dir / "ReaperSongSwitcher"
        
        # Check if already installed
        if dest_dir.exists():
            self.log_info(f"ReaperSongSwitcher already installed at {dest_dir}")
            response = input("Do you want to update it? (yes/no): ").strip().lower()
            if response != "yes" and response != "y":
                self.log("Installation cancelled.")
                return False
            
            # Backup existing installation
            backup_dir = dest_dir.parent / "ReaperSongSwitcher.backup"
            if backup_dir.exists():
                shutil.rmtree(backup_dir)
            shutil.copytree(dest_dir, backup_dir)
            self.log_success(f"Backed up existing installation to {backup_dir}")
            
            # Remove old installation
            shutil.rmtree(dest_dir)
        
        # Copy the entire ReaperSongSwitcher folder
        try:
            shutil.copytree(self.script_source, dest_dir)
            self.log_success(f"Installed ReaperSongSwitcher to {dest_dir}")
        except Exception as e:
            self.log_error(f"Failed to copy files: {e}")
            return False
        
        return True
    
    def verify_installation(self):
        """Verify that all required files are in place"""
        
        dest_dir = self.reaper_scripts_dir / "ReaperSongSwitcher"
        
        required_files = [
            "switcher.py",
            "setlist.json",
            "README.md",
        ]
        
        self.log("Verifying installation...")
        all_present = True
        
        for file in required_files:
            file_path = dest_dir / file
            if file_path.exists():
                self.log_success(f"Found: {file}")
            else:
                self.log_error(f"Missing: {file}")
                all_present = False
        
        if not (dest_dir / "setlist.json").exists():
            self.log_error("setlist.json is missing - installation incomplete!")
            return False
        
        # Verify setlist.json has base_path
        try:
            with open(dest_dir / "setlist.json", 'r') as f:
                data = json.load(f)
                if "base_path" not in data:
                    self.log_error("setlist.json missing 'base_path' key!")
                    return False
                self.log_success(f"setlist.json configured with base_path: {data['base_path']}")
        except Exception as e:
            self.log_error(f"Failed to read setlist.json: {e}")
            return False
        
        return all_present
    
    def print_post_install_instructions(self):
        """Print instructions for using the installed script"""
        
        dest_dir = self.reaper_scripts_dir / "ReaperSongSwitcher"
        
        print("\n" + "="*60)
        print("✅ INSTALLATION COMPLETE!")
        print("="*60)
        
        print(f"\n📁 Installation Directory:")
        print(f"   {dest_dir}")
        
        print(f"\n⚙️  IMPORTANT: Configure setlist.json")
        print(f"   Edit: {dest_dir / 'setlist.json'}")
        print(f"   1. Set 'base_path' to your songs folder")
        print(f"   2. Verify song paths are correct")
        print(f"   3. Ensure each song has 'Start' and 'End' markers")
        
        print(f"\n📝 Next Steps:")
        print(f"   1. Open Reaper")
        print(f"   2. Go to: Actions > Show action list")
        print(f"   3. Search for 'ReaperSongSwitcher/switcher.py'")
        print(f"   4. Test by running the script")
        
        print(f"\n🎤 Auto-Start (Optional):")
        print(f"   1. After testing, go to: Options > Startup actions")
        print(f"   2. Select your action set with the switcher script")
        
        print(f"\n📚 Documentation:")
        print(f"   Read: {dest_dir / 'QUICKSTART.md'}")
        print(f"   Full: {dest_dir / 'README.md'}")
        
        print("\n" + "="*60)
    
    def run(self):
        """Run the installation"""
        
        print("="*60)
        print("🎵 Reaper Song Switcher - Universal Installer")
        print("="*60)
        print()
        
        # Detect OS
        self.detect_os()
        
        # Install
        if not self.install_script():
            self.log_error("Installation failed!")
            return False
        
        # Verify
        if not self.verify_installation():
            self.log_error("Verification failed!")
            return False
        
        # Print instructions
        self.print_post_install_instructions()
        
        self.log_success("Installation successful!")
        return True


def main():
    """Main entry point"""
    
    try:
        installer = ReaperInstaller()
        success = installer.run()
        sys.exit(0 if success else 1)
    except KeyboardInterrupt:
        print("\n\nInstallation cancelled by user.")
        sys.exit(1)
    except Exception as e:
        print(f"\n\n❌ Unexpected error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    main()
