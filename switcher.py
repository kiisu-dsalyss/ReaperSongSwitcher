#!/usr/bin/env python3
"""
Reaper Song Switcher - Live Performance Backing Track Manager
Automatically switches between songs in a setlist based on end markers.

Features:
- Automatic song switching at end markers
- ImGui dockable window UI with skip/reorder controls
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

# Reaper API
try:
    from reaper_python import *
except ImportError:
    pass

# ImGui support
try:
    import imgui
    from imgui.integrations.glfw import GlfwRenderer
    IMGUI_AVAILABLE = True
except ImportError:
    IMGUI_AVAILABLE = False


class SongSwitcher:
    """Manages automatic song switching for live performance setlists"""
    
    def __init__(self):
        self.script_dir = Path(__file__).parent.resolve()
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
        
        # UI state
        self.show_ui = True
        self.selected_song = 0
        self.dragging_song = -1
        self.ui_window_visible = True
        
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
            
            # Open the project file
            RPR_OpenProject(song_path)
            
            self.current_song_index = index
            self.song_loaded = True
            self.switched = False
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
        """Find the 'End' marker in the current project"""
        try:
            marker_count = RPR_CountMarkers()
            
            for i in range(marker_count):
                retval = RPR_EnumMarkers(i)
                if retval:
                    marker_index, marker_pos, marker_rgnidx, marker_name, marker_color = retval
                    if marker_name.lower() == "end":
                        return marker_pos
            
            return None
        
        except Exception as e:
            self.log(f"ERROR finding end marker: {str(e)}")
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
            RPR_GoToStartOfFile()
            RPR_Play()
            self.is_playing = True
            self.log(f"Starting playback of song {self.current_song_index + 1}")
        except Exception as e:
            self.error_state = True
            self.error_message = f"Failed to start playback: {str(e)}"
            self.log(f"ERROR: {self.error_message}")
    
    def stop_playback(self):
        """Stop playback"""
        try:
            RPR_Stop()
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
    
    def reorder_songs(self, from_index, to_index):
        """Reorder songs in the setlist"""
        try:
            if from_index < 0 or from_index >= len(self.setlist):
                return False
            if to_index < 0 or to_index >= len(self.setlist):
                return False
            
            song = self.setlist.pop(from_index)
            self.setlist.insert(to_index, song)
            
            # Update current song index if needed
            if self.current_song_index == from_index:
                self.current_song_index = to_index
            elif from_index < self.current_song_index <= to_index:
                self.current_song_index -= 1
            elif to_index <= self.current_song_index < from_index:
                self.current_song_index += 1
            
            # Save updated setlist
            self.save_setlist()
            self.log(f"Reordered: moved song from position {from_index + 1} to {to_index + 1}")
            return True
        
        except Exception as e:
            self.log(f"ERROR reordering songs: {str(e)}")
            return False
    
    def save_setlist(self):
        """Save the current setlist to JSON file"""
        try:
            data = {"songs": self.setlist}
            with open(self.setlist_path, 'w') as f:
                json.dump(data, f, indent=2)
            self.log("Setlist saved")
        except Exception as e:
            self.log(f"ERROR saving setlist: {str(e)}")
    
    def draw_ui(self):
        """Draw the ImGui dockable window"""
        if not IMGUI_AVAILABLE:
            return
        
        try:
            ctx = reaper.imgui_get_context()
            if not ctx:
                return
            
            reaper.imgui_set_next_window_size(450, 550, 1)  # ImGuiCond_FirstUseEver = 1
            visible, opened = reaper.ImGui_Begin(ctx, "Song Switcher##switcher", True)
            
            if not visible:
                reaper.ImGui_End(ctx)
                return
            
            # Current song info section
            if self.error_state:
                reaper.ImGui_PushStyleColor(ctx, 0, (1.0, 0.0, 0.0, 1.0))  # ImGuiCol_Text
                reaper.ImGui_Text(ctx, f"ERROR: {self.error_message}")
                reaper.ImGui_PopStyleColor(ctx)
            else:
                if self.song_loaded:
                    song_name = self.setlist[self.current_song_index].get("name", "Unknown")
                    status = "▶ Playing" if self.is_playing else "⏸ Stopped"
                    
                    reaper.ImGui_PushStyleColor(ctx, 0, (0.0, 1.0, 0.0, 1.0))
                    reaper.ImGui_Text(ctx, f"Now: {song_name}")
                    reaper.ImGui_PopStyleColor(ctx)
                    
                    reaper.ImGui_Text(ctx, f"Status: {status}")
                    reaper.ImGui_Text(ctx, f"Position: {self.current_song_index + 1}/{len(self.setlist)}")
                    
                    if self.end_marker_position is not None and self.is_playing:
                        try:
                            current_pos = RPR_GetPlayPosition()
                            reaper.ImGui_Text(ctx, f"Time: {self.format_time(current_pos)} / {self.format_time(self.end_marker_position)}")
                        except:
                            pass
                else:
                    reaper.ImGui_Text(ctx, "No song loaded")
            
            reaper.ImGui_Separator(ctx)
            
            # Control buttons
            reaper.ImGui_Text(ctx, "Controls:")
            
            # Button row
            if reaper.ImGui_Button(ctx, "◀ Skip Back"):
                self.skip_backward()
            reaper.ImGui_SameLine(ctx)
            
            if self.is_playing:
                if reaper.ImGui_Button(ctx, "⏸ Pause"):
                    self.stop_playback()
            else:
                if reaper.ImGui_Button(ctx, "▶ Play"):
                    self.start_playback()
            reaper.ImGui_SameLine(ctx)
            
            if reaper.ImGui_Button(ctx, "Skip Next ▶"):
                self.skip_forward()
            
            reaper.ImGui_Separator(ctx)
            
            # Setlist section
            reaper.ImGui_Text(ctx, "Setlist (Drag to reorder):")
            
            # Setlist child window
            reaper.ImGui_BeginChild(ctx, "setlist_child", 0, 300)
            
            for i, song in enumerate(self.setlist):
                song_name = song.get("name", "Unknown")
                
                # Highlight current song
                if i == self.current_song_index:
                    reaper.ImGui_PushStyleColor(ctx, 0, (0.0, 1.0, 0.0, 1.0))
                    reaper.ImGui_Text(ctx, f"▶ {i + 1}. {song_name}")
                    reaper.ImGui_PopStyleColor(ctx)
                else:
                    reaper.ImGui_Text(ctx, f"  {i + 1}. {song_name}")
            
            reaper.ImGui_EndChild(ctx)
            
            reaper.ImGui_End(ctx)
        
        except Exception as e:
            self.log(f"ERROR in draw_ui: {str(e)}")
    
    def get_status(self):
        """Get current status as a formatted string"""
        if self.error_state:
            return f"ERROR: {self.error_message}"
        
        if not self.song_loaded:
            return "No song loaded"
        
        song_name = self.setlist[self.current_song_index].get("name", "Unknown")
        playing_status = "Playing" if self.is_playing else "Paused"
        
        try:
            play_pos = RPR_GetPlayPosition()
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
            is_currently_playing = RPR_GetPlayState() == 1
            self.is_playing = is_currently_playing
            
            # If not playing and a song should be loaded, something stopped it
            if not is_currently_playing and self.song_loaded and not self.switched:
                self.switched = True
                return
            
            # If we have a song loaded and an end marker
            if self.song_loaded and self.end_marker_position is not None and self.is_playing:
                current_pos = RPR_GetPlayPosition()
                
                # Check if we've passed the end marker (and not already switched)
                if current_pos >= self.end_marker_position and not self.switched:
                    self.switched = True
                    self.switch_to_next_song()
            
            # Draw UI if available
            if IMGUI_AVAILABLE:
                self.draw_ui()
        
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
    
    switcher.update()


def main():
    """Entry point for the script"""
    global switcher
    
    initialize()
    
    # Setup defer loop for continuous updates (check every 100ms)
    def defer_callback():
        update_loop()
        RPR_Defer(defer_callback)
    
    RPR_Defer(defer_callback)


# Auto-start if script is run
if __name__ == "__main__":
    main()
