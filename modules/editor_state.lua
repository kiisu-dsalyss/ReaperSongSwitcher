-- Setlist Editor State Management
-- Centralized state initialization and management

local state = {}

function state.init_all(ed)
    -- Songs and base path
    ed.songs = ed.songs or {}
    ed.base_path = ed.base_path or ""
    ed.selected_idx = ed.selected_idx or 0
    
    -- Edit mode state
    ed.edit_mode = ed.edit_mode or false
    ed.edit_name = ed.edit_name or ""
    ed.edit_path = ed.edit_path or ""
    ed.edit_idx = ed.edit_idx or 0
    ed.edit_focus = ed.edit_focus or "name"
    
    -- Create dialog state
    ed.create_dialog_open = ed.create_dialog_open or false
    ed.new_setlist_name = ed.new_setlist_name or ""
    ed.new_setlist_path = ed.new_setlist_path or ""
    ed.create_focus = ed.create_focus or "name"
    
    -- Load dialog state
    ed.load_dialog_open = ed.load_dialog_open or false
    
    -- JSON editor state
    ed.json_editor_open = ed.json_editor_open or false
    ed.json_content = ed.json_content or ""
    ed.json_scroll_offset = ed.json_scroll_offset or 0
    ed.json_edit_focus = ed.json_edit_focus or false
    
    -- Drag and drop state
    ed.drag_idx = ed.drag_idx or 0
    ed.drag_active = ed.drag_active or false
    ed.drag_y_start = ed.drag_y_start or 0
    
    -- UI state
    ed.dirty = ed.dirty or false
    ed.last_mouse_cap = ed.last_mouse_cap or 0
    ed.last_click_idx = ed.last_click_idx or 0
    ed.last_click_time = ed.last_click_time or 0
    
    -- File paths
    ed.script_dir = ed.script_dir or reaper.GetResourcePath() .. "/Scripts/ReaperSongSwitcher"
    ed.setlist_file = ed.setlist_file or ed.script_dir .. "/setlist.json"
    ed.config_file = ed.config_file or ed.script_dir .. "/config.json"
    
    -- Font settings
    ed.current_font = ed.current_font or "Menlo"
    ed.font_size_multiplier = ed.font_size_multiplier or 1.0
end

return state
