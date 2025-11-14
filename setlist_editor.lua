-- REAPER SETLIST EDITOR
-- Interactive gfx-based UI for editing setlist.json

-- Set to false to disable console output
local ENABLE_CONSOLE_OUTPUT = false

-- Check if gfx is available
if not gfx then
    reaper.ShowConsoleMsg("ERROR: gfx library not available. This script requires a graphical environment.\n")
    return
end

_G.SETLIST_EDITOR = _G.SETLIST_EDITOR or {}
local ed = _G.SETLIST_EDITOR

ed.script_dir = reaper.GetResourcePath() .. "/Scripts/ReaperSongSwitcher"
ed.config_file = ed.script_dir .. "/config.json"

-- Default font and size multiplier (will be loaded from shared config)
local PREFERRED_FONT = "Menlo"
ed.current_font = PREFERRED_FONT
ed.font_size_multiplier = 1.0

-- Load config from shared config.json (same as switcher_transport uses)
function ed.load_config()
    local f = io.open(ed.config_file, "r")
    if not f then
        ed.log("Config not found, using defaults")
        return false
    end
    local content = f:read("*a")
    f:close()
    
    -- Simple JSON parsing for ui_font and font_size_multiplier
    local font_match = string.match(content, '"ui_font"%s*:%s*"([^"]+)"')
    if font_match then
        ed.current_font = font_match
        ed.log("Loaded font from config: " .. ed.current_font)
    end
    
    local mult_match = string.match(content, '"font_size_multiplier"%s*:%s*([%d.]+)')
    if mult_match then
        ed.font_size_multiplier = tonumber(mult_match)
        ed.log("Loaded font size multiplier from config: " .. ed.font_size_multiplier)
    end
    
    return true
end

function ed.set_font(size, bold)
    local font_flags = bold and 'b' or ''
    -- Use shared font from config with multiplier
    local scaled_size = math.floor(size * ed.font_size_multiplier)
    gfx.setfont(1, ed.current_font, scaled_size, font_flags)
end

ed.setlist_file = ed.script_dir .. "/setlist.json"

ed.songs = ed.songs or {}
ed.base_path = ed.base_path or ""
ed.selected_idx = ed.selected_idx or 0
ed.edit_mode = ed.edit_mode or false  -- true when editing a song
ed.edit_name = ed.edit_name or ""
ed.edit_path = ed.edit_path or ""
ed.edit_idx = ed.edit_idx or 0
ed.edit_focus = ed.edit_focus or "name"  -- "name" or "path" - which field has focus
ed.last_char_time = ed.last_char_time or 0
ed.last_char_code = ed.last_char_code or 0
ed.edit_path = ed.edit_path or ""
ed.edit_idx = ed.edit_idx or 0
ed.drag_idx = ed.drag_idx or 0  -- which song is being dragged
ed.drag_active = ed.drag_active or false
ed.drag_y_start = ed.drag_y_start or 0  -- starting Y position of drag
ed.dirty = ed.dirty or false  -- true if unsaved changes
ed.last_mouse_cap = ed.last_mouse_cap or 0  -- track previous mouse state for click detection
ed.last_click_idx = ed.last_click_idx or 0  -- last clicked song index
ed.last_click_time = ed.last_click_time or 0  -- time of last click for double-click detection
ed.load_dialog_open = ed.load_dialog_open or false
ed.create_dialog_open = ed.create_dialog_open or false
ed.new_setlist_name = ed.new_setlist_name or ""
ed.new_setlist_path = ed.new_setlist_path or ""

function ed.log(msg)
    if ENABLE_CONSOLE_OUTPUT then
        reaper.ShowConsoleMsg("[SE] " .. msg .. "\n")
    end
end

-- Check if a click happened (mouse went from not pressed to pressed)
function ed.was_clicked(x, y, w, h)
    local is_in = ed.mouse_in(x, y, w, h)
    local was_pressed = (ed.last_mouse_cap & 1) > 0
    local is_pressed = (gfx.mouse_cap & 1) > 0
    local clicked = is_in and is_pressed and not was_pressed
    return clicked
end

function ed.truncate_text(text, max_width)
    -- Approximate: each character is about 9 pixels wide at size 14
    local char_width = 9
    local max_chars = math.floor(max_width / char_width)
    
    if #text <= max_chars then
        return text
    end
    
    -- Truncate from the start, show end of path
    local start_chars = math.floor(max_chars / 3)
    local end_chars = max_chars - start_chars - 3
    return "..." .. text:sub(-end_chars)
end

function ed.pick_file()
    -- Open file browser to select a .rpp file
    -- Reaper's GetUserFileNameForRead returns (success, filename)
    local success, filepath = reaper.GetUserFileNameForRead(ed.base_path, "Open REAPER Project", ".rpp")
    if success and filepath and filepath ~= "" then
        ed.log("Selected file (full): " .. filepath)
        
        -- Trim base path to make it relative
        if ed.base_path and ed.base_path ~= "" then
            -- Ensure base_path ends with /
            local base = ed.base_path
            if base:sub(-1) ~= "/" then
                base = base .. "/"
            end
            
            -- Check if filepath starts with base path
            if filepath:sub(1, #base) == base then
                filepath = filepath:sub(#base + 1)
                ed.log("Trimmed to relative: " .. filepath)
            end
        end
        
        ed.edit_path = filepath
    else
        ed.log("File picker cancelled or failed")
    end
end

function ed.load_json()
    local f = io.open(ed.setlist_file, "r")
    if not f then
        ed.log("ERROR: No setlist.json")
        return false
    end
    local content = f:read("*a")
    f:close()
    
    ed.base_path = string.match(content, '"base_path"%s*:%s*"([^"]+)"')
    if not ed.base_path then
        ed.log("ERROR: No base_path in JSON")
        return false
    end
    
    ed.songs = {}
    for name, path in string.gmatch(content, '"name"%s*:%s*"([^"]+)".-"path"%s*:%s*"([^"]+)"') do
        table.insert(ed.songs, {name = name, path = path})
    end
    
    ed.log("Loaded " .. #ed.songs .. " songs from setlist.json")
    ed.dirty = false
    return true
end

function ed.save_json()
    local json = '{\n  "base_path": "' .. ed.base_path .. '",\n  "songs": [\n'
    
    for i, song in ipairs(ed.songs) do
        json = json .. '    {\n'
        json = json .. '      "name": "' .. song.name .. '",\n'
        json = json .. '      "path": "' .. song.path .. '"\n'
        json = json .. '    }'
        if i < #ed.songs then json = json .. ',' end
        json = json .. '\n'
    end
    
    json = json .. '  ]\n}\n'
    
    -- Create backup of existing setlist.json before overwriting
    local backup_file = ed.setlist_file .. ".bak"
    local existing = io.open(ed.setlist_file, "r")
    if existing then
        local content = existing:read("*a")
        existing:close()
        local bak = io.open(backup_file, "w")
        if bak then
            bak:write(content)
            bak:close()
            ed.log("Created backup: " .. backup_file)
        end
    end
    
    local f = io.open(ed.setlist_file, "w")
    if not f then
        ed.log("ERROR: Cannot write setlist.json")
        return false
    end
    f:write(json)
    f:close()
    
    ed.log("Saved setlist.json")
    ed.dirty = false
    return true
end

function ed.add_song()
    table.insert(ed.songs, {name = "New Song", path = "path/to/song.rpp"})
    ed.dirty = true
    ed.log("Added new song")
end

function ed.delete_song(idx)
    if idx >= 1 and idx <= #ed.songs then
        table.remove(ed.songs, idx)
        ed.dirty = true
        ed.selected_idx = 0
        ed.log("Deleted song " .. idx)
    end
end

function ed.start_edit(idx)
    if idx >= 1 and idx <= #ed.songs then
        ed.edit_mode = true
        ed.edit_idx = idx
        ed.edit_name = ed.songs[idx].name
        ed.edit_path = ed.songs[idx].path
        ed.edit_focus = "name"
        ed.log("Started editing song " .. idx .. ": " .. ed.edit_name)
    end
end

function ed.finish_edit()
    if ed.edit_mode and ed.edit_idx >= 1 and ed.edit_idx <= #ed.songs then
        ed.songs[ed.edit_idx].name = ed.edit_name
        ed.songs[ed.edit_idx].path = ed.edit_path
        ed.dirty = true
        ed.log("Updated song " .. ed.edit_idx)
    end
    ed.edit_mode = false
    ed.edit_name = ""
    ed.edit_path = ""
    ed.edit_idx = 0
end

function ed.cancel_edit()
    ed.edit_mode = false
    ed.edit_name = ""
    ed.edit_path = ""
    ed.edit_idx = 0
end

function ed.open_load_dialog()
    -- Open file browser to select a setlist.json file
    local success, filepath = reaper.GetUserFileNameForRead(ed.script_dir, "Load Setlist", "setlist.json")
    if success and filepath and filepath ~= "" then
        ed.log("Selected setlist: " .. filepath)
        ed.setlist_file = filepath
        ed.songs = {}
        ed.load_json()
        ed.log("Loaded setlist from: " .. filepath)
    else
        ed.log("Load cancelled")
    end
end

function ed.open_create_dialog()
    ed.create_dialog_open = true
    ed.new_setlist_name = ""
    ed.new_setlist_path = ""
    ed.log("Opened create new setlist dialog")
end

function ed.close_create_dialog()
    ed.create_dialog_open = false
    ed.new_setlist_name = ""
    ed.new_setlist_path = ""
end

function ed.finish_create()
    if ed.new_setlist_name == "" or ed.new_setlist_path == "" then
        ed.log("ERROR: Name and path required")
        return
    end
    
    -- Create new setlist with empty songs array
    ed.songs = {}
    ed.base_path = ed.new_setlist_path
    ed.dirty = false
    
    -- Set the new file path
    -- Construct path: script_dir/setlists/[name].json if name doesn't look like a path
    local new_file_path
    if ed.new_setlist_name:match("/") or ed.new_setlist_name:match("%.json$") then
        -- Looks like a full path
        new_file_path = ed.new_setlist_name
    else
        -- Just a name, put it in script_dir with .json extension
        if not ed.new_setlist_name:match("%.json$") then
            new_file_path = ed.script_dir .. "/" .. ed.new_setlist_name .. ".json"
        else
            new_file_path = ed.script_dir .. "/" .. ed.new_setlist_name
        end
    end
    
    ed.setlist_file = new_file_path
    ed.save_json()
    ed.log("Created new setlist: " .. new_file_path)
    ed.close_create_dialog()
end

function ed.swap_songs(i, j)
    if i >= 1 and i <= #ed.songs and j >= 1 and j <= #ed.songs then
        ed.songs[i], ed.songs[j] = ed.songs[j], ed.songs[i]
        ed.dirty = true
        ed.log("Reordered songs")
    end
end

function ed.mouse_in(x, y, w, h)
    return gfx.mouse_x >= x and gfx.mouse_x < x + w and
           gfx.mouse_y >= y and gfx.mouse_y < y + h
end

function ed.draw_rounded_rect(x, y, w, h, r, fill)
    -- Draw a rounded rectangle approximation using small circles at corners
    -- and rectangles for sides
    local radius = r or 4
    
    -- Main rectangle body
    gfx.rect(x + radius, y, w - 2*radius, h, fill)
    gfx.rect(x, y + radius, w, h - 2*radius, fill)
    
    -- Corner circles (approximate)
    if fill == 1 then
        -- Top-left
        gfx.circle(x + radius, y + radius, radius/2, fill)
        -- Top-right
        gfx.circle(x + w - radius, y + radius, radius/2, fill)
        -- Bottom-left
        gfx.circle(x + radius, y + h - radius, radius/2, fill)
        -- Bottom-right
        gfx.circle(x + w - radius, y + h - radius, radius/2, fill)
    end
end

function ed.mouse_in(x, y, w, h)
    return gfx.mouse_x >= x and gfx.mouse_x < x + w and
           gfx.mouse_y >= y and gfx.mouse_y < y + h
end

function ed.draw_ui()
    -- Initialize gfx window if needed
    if not gfx.w or gfx.w == 0 then
        gfx.init("Setlist Editor", 500, 600)
        ed.log("Initialized gfx window")
    end
    
    -- Dock the window
    if gfx.dock(-1) == 0 then
        -- Not docked yet, try to dock
        gfx.dock(257)  -- DOCKFLAG_RIGHT
    end
    
    -- Background - cyberpunk dark with slight blue tint
    gfx.set(0.08, 0.12, 0.15)  -- dark blue-black
    gfx.rect(0, 0, gfx.w, gfx.h, 1)
    
    -- Add subtle scanline effect
    gfx.set(0, 0, 0)
    gfx.set(0, 0, 0, 0.02)  -- very subtle lines
    for line_y = 0, gfx.h, 2 do
        gfx.line(0, line_y, gfx.w, line_y)
    end
    
    local x, y = 10, 10
    local w = gfx.w - 20
    
    -- Title - neon cyan
    gfx.set(0, 1, 1)  -- cyan neon
    ed.set_font(32, true)
    gfx.x, gfx.y = x, y
    gfx.drawstr("SETLIST EDITOR")
    
    -- Top right buttons: Load, Create, Save
    local top_button_h = 35
    local top_button_w = 85
    local top_button_y = y + 2
    local save_x = gfx.w - top_button_w - 10
    local create_x = save_x - top_button_w - 5
    local load_x = create_x - top_button_w - 5
    
    -- Load button - neon green
    gfx.set(0, 1, 0.5)
    gfx.rect(load_x, top_button_y, top_button_w, top_button_h, 1)
    if ed.mouse_in(load_x, top_button_y, top_button_w, top_button_h) then
        gfx.set(0.5, 1, 0.8)  -- lighter green on hover
        gfx.rect(load_x, top_button_y, top_button_w, top_button_h, 1)
    end
    if ed.was_clicked(load_x, top_button_y, top_button_w, top_button_h) then
        ed.open_load_dialog()
    end
    gfx.set(0, 0, 0)  -- black text
    ed.set_font(14, true)
    gfx.x, gfx.y = load_x + top_button_w/2 - 24, top_button_y + top_button_h/2 - 8
    gfx.drawstr("LOAD")
    
    -- Create button - neon orange
    gfx.set(1, 0.6, 0)
    gfx.rect(create_x, top_button_y, top_button_w, top_button_h, 1)
    if ed.mouse_in(create_x, top_button_y, top_button_w, top_button_h) then
        gfx.set(1, 0.8, 0.3)  -- lighter orange on hover
        gfx.rect(create_x, top_button_y, top_button_w, top_button_h, 1)
    end
    if ed.was_clicked(create_x, top_button_y, top_button_w, top_button_h) then
        ed.open_create_dialog()
    end
    gfx.set(0, 0, 0)  -- black text
    ed.set_font(14, true)
    gfx.x, gfx.y = create_x + top_button_w/2 - 30, top_button_y + top_button_h/2 - 8
    gfx.drawstr("CREATE")
    
    -- Save button - neon magenta
    gfx.set(1, 0, 1)  -- bright magenta
    gfx.rect(save_x, top_button_y, top_button_w, top_button_h, 1)
    if ed.mouse_in(save_x, top_button_y, top_button_w, top_button_h) then
        gfx.set(1, 0.5, 1)  -- lighter magenta on hover
        gfx.rect(save_x, top_button_y, top_button_h, top_button_h, 1)
    end
    if ed.was_clicked(save_x, top_button_y, top_button_w, top_button_h) then
        ed.save_json()
    end
    gfx.set(0, 0, 0)  -- black text
    ed.set_font(14, true)
    gfx.x, gfx.y = save_x + top_button_w/2 - 16, top_button_y + top_button_h/2 - 8
    gfx.drawstr("SAVE")
    
    -- Dirty indicator
    -- Dirty indicator - neon yellow
    if ed.dirty then
        gfx.set(1, 1, 0)  -- neon yellow
        ed.set_font(12, true)
        gfx.x, gfx.y = save_x - 100, save_y + 8
        gfx.drawstr("● UNSAVED")
    end
    
    y = y + 45
    
    -- Base path editor - neon cyan labels
    ed.set_font(14, false)
    gfx.set(0, 1, 1)  -- cyan
    gfx.x, gfx.y = x, y
    gfx.drawstr("BASE PATH:")
    y = y + 22
    
    gfx.set(0.1, 0.2, 0.25)  -- dark blue
    gfx.rect(x, y, w, 32, 1)
    gfx.set(1, 1, 1)
    ed.set_font(13, false)
    gfx.x, gfx.y = x + 5, y + 6
    gfx.drawstr(ed.base_path)
    y = y + 40
    
    -- Songs list header - neon cyan
    gfx.set(0, 1, 1)  -- cyan
    ed.set_font(14, false)
    gfx.x, gfx.y = x, y
    gfx.drawstr("SONGS (" .. #ed.songs .. "):")
    y = y + 28
    
    -- Song list
    local song_y = y
    local song_h = 50
    local max_visible = math.floor((gfx.h - song_y - 70) / song_h)
    
    for i = 1, #ed.songs do
        if i <= max_visible then
            local is_selected = (i == ed.selected_idx)
            local is_hovered = ed.mouse_in(x, song_y, w, song_h)
            local is_dragged = (i == ed.drag_idx and ed.drag_active)
            
            -- Background with alternating stripes and cyberpunk colors
            if is_dragged then
                gfx.set(1, 1, 0)  -- neon yellow when dragging
            elseif is_selected then
                gfx.set(0, 1, 1)  -- cyan when selected
            elseif is_hovered then
                gfx.set(1, 0, 1)  -- magenta when hovered
            else
                -- Alternating row colors: even rows darker blue, odd rows slightly lighter
                if i % 2 == 0 then
                    gfx.set(0.08, 0.15, 0.2)  -- dark blue
                else
                    gfx.set(0.1, 0.18, 0.25)  -- slightly lighter blue
                end
            end
            gfx.rect(x, song_y, w, song_h, 1)
            
            -- Song info - bright white text on dark background
            gfx.set(1, 1, 1)
            ed.set_font(18, true)
            gfx.x, gfx.y = x + 5, song_y + 2
            gfx.drawstr(i .. ". " .. ed.songs[i].name)
            gfx.x, gfx.y = x + 5, song_y + 25
            gfx.set(0.7, 0.7, 0.7)
            ed.set_font(14, false)
            gfx.drawstr(ed.songs[i].path)
            
            -- Click to select
            if ed.was_clicked(x, song_y, w, song_h) then
                -- Check for double-click (same song clicked twice within 300ms)
                local current_time = reaper.time_precise()
                if ed.last_click_idx == i and (current_time - ed.last_click_time) < 0.3 then
                    -- Double-click! Open edit dialog
                    ed.start_edit(i)
                    ed.log("Double-clicked song " .. i .. ", opening edit dialog")
                else
                    -- Single click - just select
                    ed.selected_idx = i
                    ed.last_click_idx = i
                    ed.last_click_time = current_time
                    ed.log("Selected song " .. i)
                end
            end
            
            -- Handle drag start (detect press edge, not hold)
            local is_pressed = (gfx.mouse_cap & 1) > 0
            local was_pressed = (ed.last_mouse_cap & 1) > 0
            if is_hovered and is_pressed and not was_pressed then
                ed.drag_idx = i
                ed.drag_active = true
                ed.drag_y_start = gfx.mouse_y
            end
            
            song_y = song_y + song_h
        end
    end
    
    -- Handle drag end and reordering
    local is_pressed = (gfx.mouse_cap & 1) > 0
    if ed.drag_active and not is_pressed then
        -- Dropped! Figure out where it was dropped
        local drop_y = gfx.mouse_y
        local song_y_base = y
        local song_h = 50
        
        -- Which song is under the mouse?
        local drop_idx = math.floor((drop_y - song_y_base) / song_h) + 1
        
        if drop_idx >= 1 and drop_idx <= #ed.songs and drop_idx ~= ed.drag_idx then
            -- Swap the songs
            ed.songs[ed.drag_idx], ed.songs[drop_idx] = ed.songs[drop_idx], ed.songs[ed.drag_idx]
            ed.dirty = true
            ed.log("Reordered songs: " .. ed.drag_idx .. " -> " .. drop_idx)
        end
        
        ed.drag_active = false
        ed.drag_idx = 0
    end
    
    -- Buttons at bottom
    local button_y = gfx.h - 55
    local button_w = (w - 20) / 3
    local bh = 40
    
    -- Edit mode dialog (modal overlay)
    if ed.edit_mode then
        -- Dim background
        gfx.set(0, 0, 0)
        gfx.rect(0, 0, gfx.w, gfx.h, 1)
        gfx.set(0, 0, 0)
        gfx.rect(0, 0, gfx.w, gfx.h, 1)  -- double draw for more opacity
        
        -- Dialog box - cyberpunk dark blue with neon cyan border
        local dialog_w = 500
        local dialog_h = 280
        local dialog_x = (gfx.w - dialog_w) / 2
        local dialog_y = (gfx.h - dialog_h) / 2
        
        gfx.set(0.08, 0.12, 0.15)  -- dark blue background
        gfx.rect(dialog_x, dialog_y, dialog_w, dialog_h, 1)
        
        gfx.set(0, 1, 1)  -- neon cyan border
        gfx.rect(dialog_x, dialog_y, dialog_w, dialog_h, 0)
        
        -- Title - neon cyan
        gfx.set(0, 1, 1)
        ed.set_font(18, true)
        gfx.x, gfx.y = dialog_x + 20, dialog_y + 10
        gfx.drawstr("EDIT SONG #" .. ed.edit_idx)
        
        -- Name field - neon cyan label
        local field_y = dialog_y + 50
        gfx.set(0, 1, 1)  -- cyan
        ed.set_font(14, false)
        gfx.x, gfx.y = dialog_x + 20, field_y
        gfx.drawstr("NAME:")
        
        -- Name input - clickable to focus
        local name_field_h = 40
        local name_field_y = field_y + 25
        if ed.mouse_in(dialog_x + 20, name_field_y, dialog_w - 40, name_field_h) then
            if ed.was_clicked(dialog_x + 20, name_field_y, dialog_w - 40, name_field_h) then
                ed.edit_focus = "name"
            end
        end
        
        -- Highlight the focused field - cyan for focused, dark for unfocused
        if ed.edit_focus == "name" then
            gfx.set(0, 1, 1)  -- cyan border for focused
        else
            gfx.set(0.1, 0.2, 0.25)  -- dark blue for unfocused
        end
        gfx.rect(dialog_x + 20, name_field_y, dialog_w - 40, name_field_h, 1)
        
        -- Clear text area with darker background to avoid stale text
        gfx.set(0.25, 0.25, 0.25)
        gfx.rect(dialog_x + 22, name_field_y + 2, dialog_w - 44, name_field_h - 4, 1)
        
        gfx.set(1, 1, 1)
        ed.set_font(16, false)
        gfx.x, gfx.y = dialog_x + 25, name_field_y + 8
        gfx.drawstr(ed.edit_name)
        
        -- Blinking cursor for focused field
        if ed.edit_focus == "name" then
            ed.set_font(16, false)
            local text_w, text_h = gfx.measurestr(ed.edit_name)
            local cursor_x = dialog_x + 25 + text_w
            gfx.set(1, 1, 1)
            if (reaper.time_precise() * 2) % 1 < 0.5 then
                gfx.rect(cursor_x, name_field_y + 8, 2, 24, 1)
            end
        end
        
        -- Path field - neon cyan label
        local path_y = field_y + 80
        gfx.set(0, 1, 1)  -- cyan
        ed.set_font(14, false)
        gfx.x, gfx.y = dialog_x + 20, path_y
        gfx.drawstr("PATH: (CLICK TO BROWSE)")
        
        -- Path input - clickable to focus or open file picker
        local path_field_h = 40
        local path_field_y = path_y + 25
        local browse_btn_w = 40
        local path_input_w = dialog_w - 40 - browse_btn_w - 10
        
        -- Path text input field
        if ed.mouse_in(dialog_x + 20, path_field_y, path_input_w, path_field_h) then
            if ed.was_clicked(dialog_x + 20, path_field_y, path_input_w, path_field_h) then
                ed.edit_focus = "path"
            end
        end
        
        -- Highlight the focused field - cyan for focused, dark for unfocused
        if ed.edit_focus == "path" then
            gfx.set(0, 1, 1)  -- cyan border for focused
        else
            gfx.set(0.1, 0.2, 0.25)  -- dark blue for unfocused
        end
        gfx.rect(dialog_x + 20, path_field_y, path_input_w, path_field_h, 1)
        
        -- Clear text area with darker background to avoid stale text
        gfx.set(0.25, 0.25, 0.25)
        gfx.rect(dialog_x + 22, path_field_y + 2, path_input_w - 4, path_field_h - 4, 1)
        
        gfx.set(1, 1, 1)
        ed.set_font(14, false)
        gfx.x, gfx.y = dialog_x + 25, path_field_y + 8
        
        -- Show truncated path for display
        local display_path = ed.truncate_text(ed.edit_path, path_input_w - 10)
        gfx.drawstr(display_path)
        
        -- Blinking cursor for focused field (show cursor at actual position)
        if ed.edit_focus == "path" then
            ed.set_font(14, false)
            local text_w, text_h = gfx.measurestr(ed.edit_path)
            local cursor_x = dialog_x + 25 + text_w
            -- Clamp cursor to field width
            if cursor_x > dialog_x + 25 + path_input_w - 20 then
                cursor_x = dialog_x + 25 + path_input_w - 20
            end
            gfx.set(1, 1, 1)
            if (reaper.time_precise() * 2) % 1 < 0.5 then
                gfx.rect(cursor_x, path_field_y + 8, 2, 24, 1)
            end
        end
        
        -- Browse button (cyan like Add button)
        local browse_x = dialog_x + 20 + path_input_w + 10
        if ed.mouse_in(browse_x, path_field_y, browse_btn_w, path_field_h) then
            gfx.set(0.2, 1, 1)  -- lighter cyan hover
        else
            gfx.set(0, 1, 1)  -- neon cyan
        end
        gfx.rect(browse_x, path_field_y, browse_btn_w, path_field_h, 1)
        if ed.was_clicked(browse_x, path_field_y, browse_btn_w, path_field_h) then
            ed.pick_file()
        end
        gfx.set(0, 0, 0)  -- black text on bright button
        ed.set_font(12, true)
        gfx.x, gfx.y = browse_x + 4, path_field_y + 12
        gfx.drawstr("...")
        
        -- Buttons for Save/Cancel at bottom of dialog
        local ok_x = dialog_x + 20
        local ok_y = dialog_y + dialog_h - 45
        local ok_w = (dialog_w - 60) / 2
        
        -- Save button (magenta like main UI Save button)
        if ed.mouse_in(ok_x, ok_y, ok_w, 35) then
            gfx.set(1, 0.2, 1)  -- lighter magenta hover
        else
            gfx.set(1, 0, 1)  -- neon magenta
        end
        gfx.rect(ok_x, ok_y, ok_w, 35, 1)
        if ed.was_clicked(ok_x, ok_y, ok_w, 35) then
            ed.finish_edit()
        end
        gfx.set(0, 0, 0)  -- black text on bright button
        ed.set_font(16, true)
        gfx.x, gfx.y = ok_x + ok_w/2 - 18, ok_y + 35/2 - 8
        gfx.drawstr("SAVE")
        
        -- Cancel button (neon red like main UI Delete button)
        local cancel_x = ok_x + ok_w + 20
        if ed.mouse_in(cancel_x, ok_y, ok_w, 35) then
            gfx.set(1, 0.4, 0.4)  -- lighter red hover
        else
            gfx.set(1, 0.2, 0.2)  -- neon red
        end
        gfx.rect(cancel_x, ok_y, ok_w, 35, 1)
        if ed.was_clicked(cancel_x, ok_y, ok_w, 35) then
            ed.cancel_edit()
        end
        gfx.set(0, 0, 0)  -- black text on bright button
        ed.set_font(16, true)
        gfx.x, gfx.y = cancel_x + ok_w/2 - 26, ok_y + 35/2 - 8
        gfx.drawstr("CANCEL")
        
        -- Return early so we don't draw the normal UI on top
        ed.last_mouse_cap = gfx.mouse_cap
        gfx.update()
        return
    end
    
    -- Create new setlist dialog (modal overlay)
    if ed.create_dialog_open then
        -- Dim background
        gfx.set(0, 0, 0)
        gfx.rect(0, 0, gfx.w, gfx.h, 1)
        gfx.set(0, 0, 0)
        gfx.rect(0, 0, gfx.w, gfx.h, 1)  -- double draw for more opacity
        
        -- Dialog box - cyberpunk dark blue with neon orange border
        local dialog_w = 500
        local dialog_h = 250
        local dialog_x = (gfx.w - dialog_w) / 2
        local dialog_y = (gfx.h - dialog_h) / 2
        
        gfx.set(0.08, 0.12, 0.15)  -- dark blue background
        gfx.rect(dialog_x, dialog_y, dialog_w, dialog_h, 1)
        
        gfx.set(1, 0.6, 0)  -- neon orange border
        gfx.rect(dialog_x, dialog_y, dialog_w, dialog_h, 0)
        
        -- Title - neon orange
        gfx.set(1, 0.6, 0)
        ed.set_font(18, true)
        gfx.x, gfx.y = dialog_x + 20, dialog_y + 10
        gfx.drawstr("CREATE NEW SETLIST")
        
        -- Name field - neon orange label
        local field_y = dialog_y + 50
        gfx.set(1, 0.6, 0)  -- orange
        ed.set_font(14, false)
        gfx.x, gfx.y = dialog_x + 20, field_y
        gfx.drawstr("SETLIST NAME:")
        
        -- Name input field
        local name_field_h = 35
        local name_field_y = field_y + 22
        gfx.set(0.1, 0.2, 0.25)  -- dark blue field
        gfx.rect(dialog_x + 20, name_field_y, dialog_w - 40, name_field_h, 1)
        
        -- Clear text area
        gfx.set(0.25, 0.25, 0.25)
        gfx.rect(dialog_x + 22, name_field_y + 2, dialog_w - 44, name_field_h - 4, 1)
        
        gfx.set(1, 1, 1)
        ed.set_font(14, false)
        gfx.x, gfx.y = dialog_x + 25, name_field_y + 8
        gfx.drawstr(ed.new_setlist_name)
        
        -- Base path field - neon orange label
        local path_y = field_y + 70
        gfx.set(1, 0.6, 0)  -- orange
        ed.set_font(14, false)
        gfx.x, gfx.y = dialog_x + 20, path_y
        gfx.drawstr("BASE PATH:")
        
        -- Path input field (clickable to browse)
        local path_field_h = 35
        local path_field_y = path_y + 22
        
        if ed.mouse_in(dialog_x + 20, path_field_y, dialog_w - 60, path_field_h) then
            gfx.set(1, 0.6, 0)  -- orange border on hover
        else
            gfx.set(0.1, 0.2, 0.25)  -- dark blue field
        end
        gfx.rect(dialog_x + 20, path_field_y, dialog_w - 60, path_field_h, 1)
        
        -- Click to browse for path
        if ed.was_clicked(dialog_x + 20, path_field_y, dialog_w - 60, path_field_h) then
            local success, dirpath = reaper.GetUserFileNameForRead("", "Select Base Path", "")
            if success and dirpath and dirpath ~= "" then
                -- Get directory from file path if file was selected
                dirpath = dirpath:match("(.*/)")  or dirpath
                ed.new_setlist_path = dirpath
                ed.log("Selected base path: " .. dirpath)
            end
        end
        
        -- Clear text area
        gfx.set(0.25, 0.25, 0.25)
        gfx.rect(dialog_x + 22, path_field_y + 2, dialog_w - 64, path_field_h - 4, 1)
        
        gfx.set(0.7, 0.7, 0.7)
        ed.set_font(12, false)
        gfx.x, gfx.y = dialog_x + 25, path_field_y + 8
        gfx.drawstr(ed.new_setlist_path ~= "" and ed.truncate_text(ed.new_setlist_path, dialog_w - 90) or "(click to select)")
        
        -- Browse button
        local browse_btn_w = 30
        local browse_x = dialog_x + dialog_w - browse_btn_w - 20
        gfx.set(1, 0.6, 0)  -- orange
        gfx.rect(browse_x, path_field_y, browse_btn_w, path_field_h, 1)
        if ed.mouse_in(browse_x, path_field_y, browse_btn_w, path_field_h) then
            gfx.set(1, 0.8, 0.3)  -- lighter orange on hover
            gfx.rect(browse_x, path_field_y, browse_btn_w, path_field_h, 1)
        end
        if ed.was_clicked(browse_x, path_field_y, browse_btn_w, path_field_h) then
            local success, dirpath = reaper.GetUserFileNameForRead("", "Select Base Path", "")
            if success and dirpath and dirpath ~= "" then
                dirpath = dirpath:match("(.*/)")  or dirpath
                ed.new_setlist_path = dirpath
            end
        end
        gfx.set(0, 0, 0)  -- black text
        ed.set_font(11, true)
        gfx.x, gfx.y = browse_x + 4, path_field_y + 9
        gfx.drawstr("...")
        
        -- Buttons at bottom
        local btn_x = dialog_x + 20
        local btn_y = dialog_y + dialog_h - 45
        local btn_w = (dialog_w - 60) / 2
        
        -- Create button (orange)
        if ed.mouse_in(btn_x, btn_y, btn_w, 35) then
            gfx.set(1, 0.8, 0.3)  -- lighter orange hover
        else
            gfx.set(1, 0.6, 0)  -- neon orange
        end
        gfx.rect(btn_x, btn_y, btn_w, 35, 1)
        if ed.was_clicked(btn_x, btn_y, btn_w, 35) then
            ed.finish_create()
        end
        gfx.set(0, 0, 0)  -- black text
        ed.set_font(16, true)
        gfx.x, gfx.y = btn_x + btn_w/2 - 28, btn_y + 35/2 - 8
        gfx.drawstr("CREATE")
        
        -- Cancel button (neon red)
        local cancel_x = btn_x + btn_w + 20
        if ed.mouse_in(cancel_x, btn_y, btn_w, 35) then
            gfx.set(1, 0.4, 0.4)  -- lighter red hover
        else
            gfx.set(1, 0.2, 0.2)  -- neon red
        end
        gfx.rect(cancel_x, btn_y, btn_w, 35, 1)
        if ed.was_clicked(cancel_x, btn_y, btn_w, 35) then
            ed.close_create_dialog()
        end
        gfx.set(0, 0, 0)  -- black text
        ed.set_font(16, true)
        gfx.x, gfx.y = cancel_x + btn_w/2 - 26, btn_y + 35/2 - 8
        gfx.drawstr("CANCEL")
        
        -- Return early so we don't draw the normal UI on top
        ed.last_mouse_cap = gfx.mouse_cap
        gfx.update()
        return
    end
    
    -- Buttons at top of action area
    local button_y = gfx.h - 115
    local button_w = (w - 20) / 3
    local bh = 40
    
    -- Add button - neon cyan
    gfx.set(0, 1, 1)
    gfx.rect(x, button_y, button_w, bh, 1)
    if ed.mouse_in(x, button_y, button_w, bh) then
        gfx.set(0.5, 1, 1)  -- lighter cyan on hover
        gfx.rect(x, button_y, button_w, bh, 1)
    end
    if ed.was_clicked(x, button_y, button_w, bh) then
        ed.add_song()
    end
    gfx.set(0, 0, 0)  -- black text
    ed.set_font(16, true)
    gfx.x, gfx.y = x + button_w/2 - 20, button_y + bh/2 - 8
    gfx.drawstr("+ ADD")
    
    -- Edit button - neon magenta
    local edit_x = x + button_w + 10
    gfx.set(1, 0, 1)
    gfx.rect(edit_x, button_y, button_w, bh, 1)
    if ed.mouse_in(edit_x, button_y, button_w, bh) then
        gfx.set(0.4, 0.5, 0.6)
        gfx.rect(edit_x, button_y, button_w, bh, 1)
    end
    if ed.was_clicked(edit_x, button_y, button_w, bh) then
        if ed.selected_idx > 0 then
            ed.start_edit(ed.selected_idx)
        end
    end
    gfx.set(0, 0, 0)  -- black text
    ed.set_font(16, true)
    gfx.x, gfx.y = edit_x + button_w/2 - 18, button_y + bh/2 - 8
    gfx.drawstr("EDIT")
    
    -- Delete button - neon red/orange
    local del_x = edit_x + button_w + 10
    gfx.set(1, 0.2, 0.2)  -- neon red
    gfx.rect(del_x, button_y, button_w, bh, 1)
    if ed.mouse_in(del_x, button_y, button_w, bh) then
        gfx.set(1, 0.5, 0.5)  -- lighter red on hover
        gfx.rect(del_x, button_y, button_w, bh, 1)
    end
    if ed.was_clicked(del_x, button_y, button_w, bh) then
        if ed.selected_idx > 0 then
            ed.delete_song(ed.selected_idx)
        end
    end
    gfx.set(0, 0, 0)  -- black text
    gfx.x, gfx.y = del_x + button_w/2 - 26, button_y + bh/2 - 8
    gfx.drawstr("DELETE")
    
    -- CRITICAL: Track mouse state for next frame's click detection
    ed.last_mouse_cap = gfx.mouse_cap
    
    gfx.update()
end

function ed.main()
    -- Load shared config on first run
    if not ed.config_loaded then
        ed.load_config()
        ed.config_loaded = true
    end
    
    if not ed.songs or #ed.songs == 0 then
        local loaded = ed.load_json()
        if not loaded then
            ed.log("Failed to load setlist.json - check path")
        end
    end
    
    if not gfx.w or gfx.w == 0 then
        ed.log("gfx window not initialized, trying to create...")
        gfx.init("Setlist Editor", 700, 800)
    end
    
    -- Handle keyboard input when in edit mode
    if ed.edit_mode then
        local char = gfx.getchar()
        if char ~= -1 then
            if char == 8 then
                -- Backspace: delete last character
                if ed.edit_focus == "name" and #ed.edit_name > 0 then
                    ed.edit_name = ed.edit_name:sub(1, -2)
                elseif ed.edit_focus == "path" and #ed.edit_path > 0 then
                    ed.edit_path = ed.edit_path:sub(1, -2)
                end
            elseif char == 9 then
                -- Tab: switch focus between name and path fields
                ed.edit_focus = (ed.edit_focus == "name") and "path" or "name"
            elseif char == 13 then
                -- Enter: save the edit
                ed.finish_edit()
            elseif char == 27 then
                -- Escape: cancel the edit
                ed.cancel_edit()
            elseif char >= 32 and char < 127 then
                -- Regular printable character
                local c = string.char(char)
                if ed.edit_focus == "name" then
                    ed.edit_name = ed.edit_name .. c
                else
                    ed.edit_path = ed.edit_path .. c
                end
            end
        end
    end
    
    ed.draw_ui()
    reaper.defer(ed.main)
end

ed.log("Starting Setlist Editor...")
ed.main()
