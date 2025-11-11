#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Reaper Song Switcher - Live Performance Backing Track Manager
Automatically switches between songs in a setlist based on end markers.

Features:
- Automatic song switching at end markers
- Skip forward/backward controls
- Relative path support for portability
- Console logging and status display

Requirements:
- Each song project file must have an "End" marker at the point where the song ends
- setlist.json must exist in the same directory as this script
"""

import json
import os
import sys
from pathlib import Path
from ctypes import c_double, c_int, c_char_p

# Try to import gfx for persistent window loop
try:
    import gfx
    HAS_GFX = True
except:
    HAS_GFX = False


class SongSwitcher:
    """Manages automatic song switching for live performance setlists"""
    
    def __init__(self):
        # In Reaper, __file__ may not be defined, so use a fixed path
        script_dir = os.path.expanduser("~/Library/Application Support/REAPER/Scripts/ReaperSongSwitcher")
        self.script_dir = Path(script_dir)
        self.setlist_path = self.script_dir / "setlist.json"
        self.base_path = None  # Will be loaded from JSON
        self.setlist = None
        self.current_song_index = 0
        self.is_playing = False
        self.song_loaded = False
        self.end_marker_position = None
        self.switched = False  # Flag to prevent multiple switches
        self.error_state = False
        self.error_message = ""
        self.last_pos = 0  # Track last position to detect looping
        
        self.log("=" * 60)
        self.log("Reaper Song Switcher Initialized")
        self.log(f"Script directory: {self.script_dir}")
        self.log("=" * 60)
    
    def log(self, message):
        """Log message to Reaper console"""
        RPR_ShowConsoleMsg(f"[SongSwitcher] {message}\n")
    
    def resolve_path(self, relative_path):
        """Resolve relative path to absolute path"""
        if os.path.isabs(relative_path):
            return relative_path
        return os.path.join(str(self.base_path), relative_path)
    
    def load_setlist(self):
        """Load the setlist from JSON file"""
        try:
            if not self.setlist_path.exists():
                self.error_state = True
                self.error_message = f"Setlist not found: {self.setlist_path}"
                self.log(f"ERROR: {self.error_message}")
                return False
            
            with open(self.setlist_path, 'r') as f:
                data = json.load(f)
            
            # Load base_path from config
            if "base_path" not in data:
                self.error_state = True
                self.error_message = "setlist.json missing 'base_path' key"
                self.log(f"ERROR: {self.error_message}")
                return False
            
            self.base_path = Path(data["base_path"])
            self.log(f"Base path from config: {self.base_path}")
            
            if "songs" not in data or not isinstance(data["songs"], list):
                self.error_state = True
                self.error_message = "Invalid setlist format: missing 'songs' array"
                self.log(f"ERROR: {self.error_message}")
                return False
            
            if len(data["songs"]) == 0:
                self.error_state = True
                self.error_message = "Setlist contains no songs"
                self.log(f"ERROR: {self.error_message}")
                return False
            
            self.setlist = data["songs"]
            self.log(f"Setlist loaded: {len(self.setlist)} songs")
            for i, song in enumerate(self.setlist, 1):
                self.log(f"  {i}. {song.get('name', 'Unknown')}")
            
            return True
        
        except json.JSONDecodeError as e:
            self.error_state = True
            self.error_message = f"JSON parse error: {str(e)}"
            self.log(f"ERROR: {self.error_message}")
            return False
        
        except Exception as e:
            self.error_state = True
            self.error_message = f"Failed to load setlist: {str(e)}"
            self.log(f"ERROR: {self.error_message}")
            return False
    
    def load_song(self, index):
        """Load a song project file by index"""
        try:
            if index < 0 or index >= len(self.setlist):
                self.error_state = True
                self.error_message = f"Invalid song index: {index}"
                self.log(f"ERROR: {self.error_message}")
                return False
            
            song = self.setlist[index]
            relative_path = song.get("path", "")
            song_name = song.get("name", "Unknown")
            
            # Resolve the path
            song_path = self.resolve_path(relative_path)
            
            if not song_path:
                self.error_state = True
                self.error_message = f"Song {index + 1} has no path specified"
                self.log(f"ERROR: {self.error_message}")
                return False
            
            if not os.path.exists(song_path):
                self.error_state = True
                self.error_message = f"Song file not found: {song_path}"
                self.log(f"ERROR: {self.error_message}")
                return False
            
            self.log(f"Loading song {index + 1}/{len(self.setlist)}: {song_name}")
            self.log(f"  Path: {song_path}")
            
            # Open the project file - use Main_openProject with correct calling convention
            # RPR_Main_openProject takes the file path and returns the project
            try:
                RPR_Main_openProject(0, song_path)
            except TypeError:
                # Try alternate signature
                RPR_Main_openProject(song_path)
            
            self.current_song_index = index
            self.song_loaded = True
            self.switched = False
            self.last_pos = 0  # Reset position tracker
            self.end_marker_position = self.find_end_marker()
            
            if self.end_marker_position is None:
                self.log(f"WARNING: No 'End' marker found in {song_name}")
                self.log("  This song may not switch properly!")
            else:
                self.log(f"  End marker found at: {self.format_time(self.end_marker_position)}")
            
            return True
        
        except Exception as e:
            self.error_state = True
            self.error_message = f"Failed to load song: {str(e)}"
            self.log(f"ERROR: {self.error_message}")
            return False
    
    def find_end_marker(self):
        """Find the 'End' region in the current project by parsing the .RPP file directly"""
        try:
            result = RPR_CountProjectMarkers(None, 0, 0)
            if isinstance(result, tuple):
                region_count = result[0]
            else:
                region_count = result
            
            self.log(f"DEBUG: Found {region_count} regions in project")
            
            # Get project path using an output parameter
            try:
                proj_path_out = [""]
                RPR_GetProjectPath(None, proj_path_out)
                proj_fn = proj_path_out[0] if proj_path_out else None
            except:
                # Fallback: try to get from the currently loaded file
                # The song path should be in self.setlist
                song = self.setlist[self.current_song_index]
                proj_fn = self.resolve_path(song.get("path", ""))
            
            self.log(f"DEBUG: Current project path: {proj_fn}")
            
            # Parse the .RPP file directly to find region names
            if proj_fn and os.path.exists(proj_fn):
                try:
                    import re
                    with open(proj_fn, 'r', encoding='utf-8', errors='ignore') as f:
                        lines = f.readlines()
                    
                    # Reaper stores regions as MARKER entries in the .RPP file
                    # Format: MARKER 2 <position> <name> [other fields...]
                    # Type 1 = marker, Type 2 = region
                    # Example: MARKER 2 270 End 8 0 1 B {...} 0
                    
                    region_positions = {}
                    
                    for line in lines:
                        line = line.strip()
                        if line.startswith('MARKER'):
                            parts = line.split()
                            if len(parts) >= 4:
                                marker_type = parts[1]
                                try:
                                    position = float(parts[2])
                                    # Name can be quoted or unquoted
                                    name = parts[3]
                                    # Remove quotes if present
                                    if name.startswith('"') and '"' in name[1:]:
                                        name = name.split('"')[1]
                                    
                                    # Type 2 is region
                                    if marker_type == '2':
                                        region_positions[name] = position
                                        self.log(f"DEBUG: Found region '{name}' at position {position}")
                                except (ValueError, IndexError):
                                    pass
                    
                    # Look for "End" region (case-insensitive)
                    for name, pos in region_positions.items():
                        if name.lower() == "end":
                            self.log(f"DEBUG: Found 'End' region at position {pos}")
                            return pos
                    
                    self.log(f"DEBUG: Found {len(region_positions)} regions total, but no 'End' region")
                    
                except Exception as parse_e:
                    self.log(f"DEBUG: Error parsing file: {type(parse_e).__name__}: {str(parse_e)}")
            else:
                self.log(f"DEBUG: Project file not found or invalid: {proj_fn}")
            
            self.log(f"DEBUG: No 'End' region found")
            return None
        
        except Exception as e:
            self.log(f"ERROR finding end region: {str(e)}")
            return None
    
    def format_time(self, position):
        """Format a time position as HH:MM:SS"""
        hours = int(position // 3600)
        minutes = int((position % 3600) // 60)
        seconds = int(position % 60)
        return f"{hours:02d}:{minutes:02d}:{seconds:02d}"
    
    def start_playback(self):
        """Start playback of the current song"""
        try:
            # Use action command to play (40044 is the standard play action)
            RPR_Main_OnCommand(40044, 0)
            self.is_playing = True
            self.log(f"Starting playback of song {self.current_song_index + 1}")
        except Exception as e:
            self.error_state = True
            self.error_message = f"Failed to start playback: {str(e)}"
            self.log(f"ERROR: {self.error_message}")
    
    def stop_playback(self):
        """Stop playback"""
        try:
            # Use action command to stop (40046 is the standard stop action)
            RPR_Main_OnCommand(40046, 0)
            self.is_playing = False
            self.log("Playback stopped")
        except Exception as e:
            self.log(f"ERROR stopping playback: {str(e)}")
    
    def switch_to_next_song(self):
        """Switch to the next song in the setlist"""
        try:
            next_index = self.current_song_index + 1
            
            if next_index >= len(self.setlist):
                self.log("End of setlist reached!")
                self.stop_playback()
                self.song_loaded = False
                return False
            
            self.log(f"Switching to next song ({next_index + 1}/{len(self.setlist)})")
            
            if not self.load_song(next_index):
                # Error already logged in load_song
                return False
            
            self.start_playback()
            return True
        
        except Exception as e:
            self.error_state = True
            self.error_message = f"Failed to switch song: {str(e)}"
            self.log(f"ERROR: {self.error_message}")
            return False
    
    def skip_forward(self):
        """Skip to the next song immediately"""
        self.log("User skip forward triggered")
        self.stop_playback()
        self.switched = True  # Prevent auto-switch
        self.switch_to_next_song()
    
    def skip_backward(self):
        """Skip to the previous song"""
        try:
            prev_index = self.current_song_index - 1
            
            if prev_index < 0:
                self.log("Already at first song")
                return False
            
            self.log(f"User skip backward triggered - loading song {prev_index + 1}")
            self.stop_playback()
            self.switched = True
            
            if not self.load_song(prev_index):
                return False
            
            self.start_playback()
            return True
        
        except Exception as e:
            self.error_state = True
            self.error_message = f"Failed to skip backward: {str(e)}"
            self.log(f"ERROR: {self.error_message}")
            return False
    
    def get_status(self):
        """Get current status as a formatted string"""
        if self.error_state:
            return f"ERROR: {self.error_message}"
        
        if not self.song_loaded:
            return "No song loaded"
        
        song_name = self.setlist[self.current_song_index].get("name", "Unknown")
        playing_status = "Playing" if self.is_playing else "Paused"
        
        try:
            play_pos = RPR_GetPlayPosition2Ex(0)
            if self.end_marker_position:
                time_str = f"{self.format_time(play_pos)} / {self.format_time(self.end_marker_position)}"
            else:
                time_str = self.format_time(play_pos)
            
            return f"Song {self.current_song_index + 1}/{len(self.setlist)}: {song_name} - {playing_status} - {time_str}"
        except Exception as e:
            return f"Song {self.current_song_index + 1}/{len(self.setlist)}: {song_name} - {playing_status}"
    
    def update(self):
        """Main update loop - called periodically by Reaper defer"""
        try:
            # Check if playback is still running
            is_currently_playing = RPR_GetPlayStateEx(0) == 1
            self.is_playing = is_currently_playing
            
            # If we have a song loaded and an end marker
            if self.song_loaded and self.end_marker_position is not None and self.is_playing:
                current_pos = RPR_GetPlayPosition2Ex(0)
                
                # Debug: show position periodically (every 5 seconds or so)
                if int(current_pos) % 5 == 0 and current_pos != self.last_pos:
                    self.log(f"DEBUG: pos={current_pos:.2f}, end={self.end_marker_position:.2f}, switched={self.switched}")
                
                # Detect if we've looped (position went backwards, or jumped from high to low)
                # When a song loops in Reaper, the position can either:
                # 1. Jump backwards (last_pos > 200, current_pos < 10)
                # 2. Go to exactly 0
                # 3. Reset to a small value when reaching project end
                
                backwards_jump = (self.last_pos > 50 and current_pos < 10)  # Significant backwards jump
                loop_from_end = (self.last_pos > self.end_marker_position - 5 and current_pos < 5)  # Near end, now at start
                
                if (backwards_jump or loop_from_end) and not self.switched:
                    self.log(f"DEBUG: Loop detected!")
                    self.log(f"  last_pos={self.last_pos:.2f}, current_pos={current_pos:.2f}")
                    self.log(f"  backwards_jump={backwards_jump}, loop_from_end={loop_from_end}")
                    self.switched = True
                    self.switch_to_next_song()
                
                # Also check if we've reached the end marker
                elif current_pos >= self.end_marker_position and not self.switched:
                    self.log(f"DEBUG: End marker reached! current_pos={current_pos}, end_marker={self.end_marker_position}")
                    self.switched = True
                    self.switch_to_next_song()
                
                self.last_pos = current_pos
        
        except Exception as e:
            self.error_state = True
            self.error_message = f"Update error: {str(e)}"
            self.log(f"ERROR in update loop: {self.error_message}")


# Global switcher instance
switcher = None


def initialize():
    """Initialize the song switcher"""
    global switcher
    
    switcher = SongSwitcher()
    
    # Load setlist
    if not switcher.load_setlist():
        switcher.error_state = True
        return
    
    # Load first song
    if not switcher.load_song(0):
        switcher.error_state = True
        return
    
    # Start playback
    switcher.start_playback()
    
    switcher.log("Initialization complete - waiting for song to end")


def update_loop():
    """Called periodically by Reaper to update switcher state"""
    global switcher
    
    if switcher is None:
        initialize()
    else:
        switcher.update()


def main():
    """Entry point for the script"""
    global switcher
    
    # Initialize switcher on first call
    if switcher is None:
        switcher = SongSwitcher()
        
        # Load setlist
        if not switcher.load_setlist():
            switcher.error_state = True
            return
        
        # Load first song
        if not switcher.load_song(0):
            switcher.error_state = True
            return
        
        # Start playback
        switcher.start_playback()
        
        switcher.log("Initialization complete")
        switcher.log("")
        switcher.log("=" * 70)
        switcher.log("NEXT STEP - Set up continuous monitoring:")
        switcher.log("")
        switcher.log("1. Open Reaper's Actions list: ? > Show action list")
        switcher.log("2. At the bottom, click 'New' button")
        switcher.log("3. Set to type: ReaScript (Python)")
        switcher.log("4. Paste this script path into the action")
        switcher.log("5. Name it: 'SongSwitcher - Update'")
        switcher.log("6. Click OK to save")
        switcher.log("")
        switcher.log("7. Right-click the new action > Set to repeat every X ms")
        switcher.log("8. Set to 100 ms (or use the timer approach below)")
        switcher.log("")
        switcher.log("OR set up a timer action:")
        switcher.log("- Assign this action to a toolbar button")
        switcher.log("- Hold down the button to keep it updating")
        switcher.log("- Or create a timed keystroke that repeats")
        switcher.log("=" * 70)
        return
    
    # This code runs if the script is called again after initialization
    # Each call to the script performs one update
    if switcher is not None:
        switcher.update()


# Auto-start if script is run
if __name__ == "__main__":
    main()
