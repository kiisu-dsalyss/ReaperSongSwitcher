-- State Management Module
-- Centralized state initialization and management

local state = {}

-- Initialize all global state variables with defaults
function state.init_all(ss, script_dir)
    -- File paths
    ss.config_file = ss.config_file or (script_dir .. "/config.json")
    ss.setlist_file = ss.setlist_file or (script_dir .. "/setlist.json")
    ss.current_setlist_path = ss.current_setlist_path or ss.setlist_file
    
    -- Configuration
    ss.current_font = ss.current_font or "Menlo"
    ss.font_size_multiplier = ss.font_size_multiplier or 1.0
    
    -- Window state
    ss.window_x = ss.window_x or 100
    ss.window_y = ss.window_y or 100
    ss.window_w = ss.window_w or 700
    ss.window_h = ss.window_h or 750
    ss.window_save_counter = ss.window_save_counter or 0
    
    -- Setlist and song data
    ss.songs = ss.songs or {}
    ss.base_path = ss.base_path or ""
    ss.current_index = ss.current_index or 1
    ss.last_pos = ss.last_pos or 0
    ss.init_done = ss.init_done or false
    
    -- Playback and auto-switch state
    ss.switch_cooldown = ss.switch_cooldown or 0
    ss.auto_switch_state = ss.auto_switch_state or 0  -- 0=idle, 1=loaded_waiting_to_play
    ss.auto_switch_next_idx = ss.auto_switch_next_idx or 0
    ss.loop_check_counter = ss.loop_check_counter or 0
    
    -- Dialog visibility
    ss.show_load_setlist_dialog = ss.show_load_setlist_dialog or false
    ss.show_font_picker = ss.show_font_picker or false
    
    -- UI state
    ss.ui = ss.ui or {}
    ss.ui.selected = ss.ui.selected or 1
    ss.ui.last_mouse_cap = ss.ui.last_mouse_cap or 0
    
    -- Font picker state
    ss.font_search = ss.font_search or ""
    ss.font_picker_scroll = ss.font_picker_scroll or 0
    ss.font_picker_dragging = ss.font_picker_dragging or false
    ss.font_picker_drag_offset = ss.font_picker_drag_offset or 0
    ss.available_fonts = ss.available_fonts or {}
    
    -- Dialog input
    ss.setlist_load_input = ss.setlist_load_input or ""
    
    -- Logging
    ss.font_logged = ss.font_logged or false
    
    return ss
end

return state
