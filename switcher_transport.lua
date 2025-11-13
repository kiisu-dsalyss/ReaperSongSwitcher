-- REAPER SONG SWITCHER - TRANSPORT CONTROL UI
-- Auto-switches songs with visual transport controls

-- Set to false to disable console output
local ENABLE_CONSOLE_OUTPUT = false

_G.SS = _G.SS or {}
local ss = _G.SS

-- Initialize script directory first
ss.script_dir = reaper.GetResourcePath() .. "/Scripts/ReaperSongSwitcher"
ss.transport_log = ss.script_dir .. "/switcher_transport.log"

function ss.log_transport(msg)
    local f = io.open(ss.transport_log, "a")
    if f then
        f:write("[" .. os.date("%Y-%m-%d %H:%M:%S") .. "] " .. msg .. "\n")
        f:close()
    end
end

-- Set to a system font that Reaper can use
-- Available: "Arial", "Menlo", "Courier New", "Courier", "Monaco"
-- Menlo is closest to Hacked-KerX (monospace tech aesthetic)
local PREFERRED_FONT = "Menlo"

ss.config_file = ss.script_dir .. "/config.json"
ss.current_font = PREFERRED_FONT  -- Will be loaded from config
ss.font_size_multiplier = 1.0  -- Will be loaded from config (1.0 = 100%, 1.2 = 120%, etc)

function ss.load_config()
    local f = io.open(ss.config_file, "r")
    if not f then
        -- Create default config
        ss.log_transport("Creating default config.json")
        return false
    end
    local content = f:read("*a")
    f:close()
    
    -- Simple JSON parsing for ui_font and font_size_multiplier
    local font_match = string.match(content, '"ui_font"%s*:%s*"([^"]+)"')
    if font_match then
        ss.current_font = font_match
        ss.log_transport("Loaded font from config: " .. ss.current_font)
    end
    
    local mult_match = string.match(content, '"font_size_multiplier"%s*:%s*([%d.]+)')
    if mult_match then
        ss.font_size_multiplier = tonumber(mult_match)
        ss.log_transport("Loaded font size multiplier from config: " .. ss.font_size_multiplier)
    else
        ss.font_size_multiplier = 1.0  -- Default
    end
    
    return true
end

function ss.save_config(font_name, multiplier)
    multiplier = multiplier or ss.font_size_multiplier or 1.0
    local content = '{\n  "ui_font": "' .. font_name .. '",\n  "font_size_multiplier": ' .. string.format("%.2f", multiplier) .. ',\n  "available_fonts": [\n    "Arial",\n    "Menlo",\n    "Courier New",\n    "Courier",\n    "Monaco",\n    "Helvetica"\n  ]\n}\n'
    local f = io.open(ss.config_file, "w")
    if f then
        f:write(content)
        f:close()
        ss.current_font = font_name
        ss.font_size_multiplier = multiplier
        ss.log_transport("Saved font config: " .. font_name .. " (multiplier: " .. string.format("%.2f", multiplier) .. ")")
    end
end

function ss.set_font(size, bold)
    local font_flags = bold and 'b' or ''
    -- Use font from config, fall back to hardcoded PREFERRED_FONT
    local font_to_use = ss.current_font or PREFERRED_FONT
    gfx.setfont(1, font_to_use, size, font_flags)
    -- Debug: log first time only
    if not ss.font_logged then
        ss.log_file("set_font() called with: font=" .. font_to_use .. ", size=" .. size .. ", bold=" .. tostring(bold))
        ss.font_logged = true
    end
end

ss.setlist_file = ss.script_dir .. "/setlist.json"
ss.songs = ss.songs or {}
ss.base_path = ss.base_path or ""
ss.current_index = ss.current_index or 1
ss.last_pos = ss.last_pos or 0
ss.switched = ss.switched or false
ss.init_done = ss.init_done or false
ss.switch_cooldown = ss.switch_cooldown or 0
ss.auto_switch_state = ss.auto_switch_state or 0  -- 0=idle, 1=loaded_waiting_to_play
ss.auto_switch_next_idx = ss.auto_switch_next_idx or 0
ss.loop_check_counter = ss.loop_check_counter or 0
ss.was_playing = ss.was_playing or false  -- Track if we were playing to detect stop
ss.ui = ss.ui or {}
ss.ui.selected = ss.ui.selected or 1
ss.ui.last_mouse_cap = ss.ui.last_mouse_cap or 0
ss.ui.loop_enabled = ss.ui.loop_enabled or false  -- Track loop state
ss.ui.loop_initialized = ss.ui.loop_initialized or false  -- Track if we've synced with Reaper
ss.ui.pulse_phase = ss.ui.pulse_phase or 0  -- For pulsing animation
ss.font_logged = ss.font_logged or false  -- Debug flag for font logging
ss.show_font_picker = ss.show_font_picker or false  -- Show font picker dialog
ss.available_fonts = ss.available_fonts or {}  -- Will be populated by get_system_fonts()
ss.font_picker_scroll = ss.font_picker_scroll or 0
ss.font_picker_dragging = ss.font_picker_dragging or false
ss.font_picker_drag_offset = ss.font_picker_drag_offset or 0

-- Get all available system fonts
function ss.get_system_fonts()
    if #ss.available_fonts > 0 then
        ss.log_transport("Fonts already loaded: " .. #ss.available_fonts)
        return  -- Already loaded
    end
    
    local fonts = {}
    local font_set = {}  -- Track unique fonts
    
    ss.log_transport("Starting font detection...")
    
    -- Read from pre-generated fonts list file
    local fonts_list_file = ss.script_dir .. "/fonts_list.txt"
    ss.log_transport("Fonts list file: " .. fonts_list_file)
    
    local f = io.open(fonts_list_file, "r")
    if f then
        ss.log_transport("Fonts file opened")
        local count = 0
        for line in f:lines() do
            -- Clean up the font name (trim whitespace)
            line = line:gsub("^%s+", ""):gsub("%s+$", "")
            
            -- Only filter: empty strings and absurdly long names
            if line ~= "" and #line < 200 then
                if not font_set[line] then
                    table.insert(fonts, line)
                    font_set[line] = true
                    count = count + 1
                    if count <= 10 then
                        ss.log_transport("  Font " .. count .. ": " .. line)
                    end
                end
            end
        end
        f:close()
        ss.log_transport("Fonts file closed. Total fonts found: " .. count)
    else
        ss.log_transport("ERROR: Could not open fonts_list.txt!")
    end
    
    -- Fallback list if file didn't work
    if #fonts == 0 then
        ss.log_transport("No fonts found, using fallback list")
        fonts = {"Arial", "Menlo", "Courier New", "Courier", "Monaco", "Helvetica", "Times New Roman", "Verdana"}
    end
    
    ss.available_fonts = fonts
    ss.log_transport("Font loading complete: " .. #fonts .. " fonts available")
end

function ss.log(msg)
    if ENABLE_CONSOLE_OUTPUT then
        reaper.ShowConsoleMsg("[SS] " .. msg .. "\n")
    end
end

function ss.log_file(msg)
    local ok, err
    local logfile = ss.script_dir .. "/switcher.log"
    local f, ferr = io.open(logfile, "a")
    if not f then
        os.execute('mkdir -p "' .. ss.script_dir .. '"')
        f, ferr = io.open(logfile, "a")
        if not f then
            ss.log("ERROR: cannot open log file: " .. tostring(ferr))
            return
        end
    end
    local ts = os.date("%Y-%m-%d %H:%M:%S")
    f:write("[" .. ts .. "] " .. msg .. "\n")
    f:close()
end

function ss.load_json()
    local f = io.open(ss.setlist_file, "r")
    if not f then
        ss.log("ERROR: No setlist.json")
        ss.log_file("ERROR: No setlist.json at " .. ss.setlist_file)
        return false
    end
    local content = f:read("*a")
    f:close()
    
    ss.base_path = string.match(content, '"base_path"%s*:%s*"([^"]+)"')
    if not ss.base_path then
        ss.log("ERROR: No base_path in JSON")
        ss.log_file("ERROR: No base_path in JSON in " .. ss.setlist_file)
        return false
    end
    
    ss.songs = {}
    for name, path in string.gmatch(content, '"name"%s*:%s*"([^"]+)".-"path"%s*:%s*"([^"]+)"') do
        table.insert(ss.songs, {name = name, path = path})
    end
    
    if #ss.songs == 0 then
        ss.log("ERROR: No songs in JSON")
        ss.log_file("ERROR: No songs parsed from " .. ss.setlist_file)
        return false
    end
    ss.log("✓ Loaded " .. #ss.songs .. " songs")
    ss.log_file("Loaded " .. #ss.songs .. " songs from " .. ss.setlist_file)
    return true
end

function ss.load_song(idx)
    if idx < 1 or idx > #ss.songs then return end
    local song = ss.songs[idx]
    local path = ss.base_path .. "/" .. song.path
    
    if io.open(path, "r") then
        io.close()
        ss.log("► " .. idx .. ". " .. song.name)
        ss.log_file("load_song(): Loading project: " .. path)
        reaper.Main_openProject(path)
        ss.current_index = idx
        ss.ui.selected = idx
        ss.last_pos = 0
        
        -- Sync loop state with new project
        local loop_state = reaper.GetSetRepeat(-1)
        ss.ui.loop_enabled = (loop_state == 1)
        ss.log_file("load_song(): Synced loop state: " .. (ss.ui.loop_enabled and "ON" or "OFF"))
        
        -- Set play position to 0 first
        reaper.SetEditCurPos(0, false, false)
        
        -- Use action ID 1007 - PLAY (from Reaper API docs)
        reaper.Main_OnCommand(1007, 0)
        
        ss.log("   Playing")
        ss.log_file("load_song(): Started playing index " .. idx .. " - " .. song.name)
    else
        ss.log("ERROR: File not found: " .. path)
        ss.log_file("ERROR: File not found in load_song(): " .. path)
    end
end

-- Load song without playing (for auto-switch sequence: stop, load, wait, play)
function ss.load_song_no_play(idx)
    if idx < 1 or idx > #ss.songs then return end
    local song = ss.songs[idx]
    local path = ss.base_path .. "/" .. song.path
    
    if io.open(path, "r") then
        io.close()
        ss.log("► " .. idx .. ". " .. song.name .. " (loaded, will play next frame)")
        ss.log_file("load_song_no_play(): Loaded project: " .. path)
        reaper.Main_openProject(path)
        ss.current_index = idx
        ss.ui.selected = idx
        ss.last_pos = 0
        
        -- Sync loop state with new project
        local loop_state = reaper.GetSetRepeat(-1)
        ss.ui.loop_enabled = (loop_state == 1)
        ss.log_file("load_song_no_play(): Synced loop state: " .. (ss.ui.loop_enabled and "ON" or "OFF"))
        
        -- Set play position to 0 first
        reaper.SetEditCurPos(0, false, false)
        
        -- DO NOT PLAY YET - just set state flag, play will happen next frame
        ss.auto_switch_state = 1
        ss.log_file("load_song_no_play(): set auto_switch_state=1 for index " .. idx)
    else
        ss.log("ERROR: File not found: " .. path)
        ss.log_file("ERROR: File not found in load_song_no_play(): " .. path)
    end
end

function ss.init()
    if not ss.init_done then
        ss.load_config()  -- Load font preference from config
        ss.get_system_fonts()  -- Populate available fonts list
        if ss.load_json() then
            ss.init_done = true
            ss.log("Ready!")
            ss.log_file("=== INIT: Font attempting to use: " .. ss.current_font .. " ===")
            
            -- Sync loop button with Reaper's actual transport loop state on first run only
            if not ss.ui.loop_initialized then
                -- Read Reaper's repeat/loop state: GetSetRepeat(-1) returns 0 if off, 1 if on
                local loop_state = reaper.GetSetRepeat(-1)
                ss.ui.loop_enabled = (loop_state == 1)
                ss.ui.loop_initialized = true
                ss.log("Loop initialized: " .. (ss.ui.loop_enabled and "ON" or "OFF"))
                ss.log_file("Loop initialized: " .. (ss.ui.loop_enabled and "ON" or "OFF"))
            end
            
            ss.load_song(1)  -- Auto-load first song
        else
            reaper.defer(ss.init)
            return
        end
    end
end

-- Font picker UI with search
function ss.draw_font_picker()
    local w = gfx.w
    local h = gfx.h
    local dialog_w = 480
    local dialog_h = 680
    local dialog_x = (w - dialog_w) / 2
    local dialog_y = (h - dialog_h) / 2
    
    -- Dark overlay
    gfx.set(0, 0, 0, 0.7)
    gfx.rect(0, 0, w, h, true)
    
    -- Dialog box
    gfx.set(0.08, 0.15, 0.2)
    gfx.rect(dialog_x, dialog_y, dialog_w, dialog_h, true)
    gfx.set(0, 1, 1)
    gfx.rect(dialog_x, dialog_y, dialog_w, dialog_h, false)
    
    -- Title
    gfx.set(0, 1, 1)
    ss.set_font(16, true)
    gfx.x, gfx.y = dialog_x + 20, dialog_y + 15
    gfx.drawstr("SELECT FONT (" .. #ss.available_fonts .. " available)")
    
    -- Search box
    ss.font_search = ss.font_search or ""
    local search_y = dialog_y + 45
    gfx.set(0.1, 0.2, 0.3)
    gfx.rect(dialog_x + 10, search_y, dialog_w - 20, 28, true)
    gfx.set(0, 1, 1)
    gfx.rect(dialog_x + 10, search_y, dialog_w - 20, 28, false)
    
    gfx.set(0.7, 0.7, 0.7)
    ss.set_font(12, false)
    gfx.x, gfx.y = dialog_x + 20, search_y + 6
    gfx.drawstr("Search: " .. ss.font_search .. (math.floor(reaper.time_precise() * 2) % 2 == 0 and "_" or ""))
    
    -- Build filtered font list
    local filtered_fonts = {}
    local search_lower = ss.font_search:lower()
    for i, font_name in ipairs(ss.available_fonts) do
        if search_lower == "" or font_name:lower():find(search_lower, 1, true) then
            table.insert(filtered_fonts, font_name)
        end
    end
    
    -- Font list with scrolling
    local list_y = search_y + 40
    -- Make the list container smaller so the controls + close button fit inside the dialog
    local list_h = dialog_h - 220
    local item_h = 24  -- Bigger rows for better readability
    local max_visible = math.floor(list_h / item_h)
    local scrollbar_w = 12
    local list_w = dialog_w - 20 - scrollbar_w - 5
    
    -- Handle scroll wheel (normalized steps)
    local scroll_delta = gfx.mouse_wheel
    if scroll_delta ~= 0 then
        local step = 3  -- scroll N rows per wheel tick
        ss.font_picker_scroll = math.max(0, math.min(ss.font_picker_scroll - scroll_delta * step, math.max(0, #filtered_fonts - max_visible)))
        gfx.mouse_wheel = 0
    end
    
    -- Draw font list
    for i = 1, #filtered_fonts do
        local visible_idx = i - ss.font_picker_scroll
        if visible_idx < 1 or visible_idx > max_visible then
            goto continue_fonts
        end
        
        local font_name = filtered_fonts[i]
        local y = list_y + (visible_idx - 1) * item_h
        local is_current = (font_name == ss.current_font)
        
        -- Item background with alternating colors
        if is_current then
            gfx.set(0, 0.8, 0.8)  -- Cyan highlight for current
        elseif ss.ui.mouse_in(dialog_x + 10, y, list_w, item_h) then
            gfx.set(0.2, 0.4, 0.5)  -- Hover
        else
            -- Alternate between two shades for readability
            if i % 2 == 0 then
                gfx.set(0.08, 0.15, 0.2)  -- Slightly darker
            else
                gfx.set(0.12, 0.19, 0.26)  -- Slightly lighter
            end
        end
        gfx.rect(dialog_x + 10, y, list_w, item_h, true)
        
        -- Font name text
        gfx.set(1, 1, 1)
        ss.set_font(13, false)
        gfx.x, gfx.y = dialog_x + 20, y + 3
        local display_name = font_name
        if #font_name > 50 then
            display_name = font_name:sub(1, 47) .. "..."
        end
        gfx.drawstr(display_name)
        
        -- Click handler
        if ss.ui.was_clicked(dialog_x + 10, y, list_w, item_h) then
            ss.save_config(font_name)
            ss.show_font_picker = false
            ss.font_search = ""  -- Clear search
        end
        
        ::continue_fonts::
    end
    
    -- Draw scrollbar and handle interactions
    if #filtered_fonts > max_visible then
        local scrollbar_x = dialog_x + dialog_w - scrollbar_w - 10
        local scrollbar_h = list_h
        local max_scroll = math.max(1, #filtered_fonts - max_visible)
        local scroll_ratio = ss.font_picker_scroll / max_scroll
        local thumb_h = math.max(20, scrollbar_h * (max_visible / #filtered_fonts))
        local thumb_y = list_y + scroll_ratio * (scrollbar_h - thumb_h)

        -- Scrollbar track
        gfx.set(0.05, 0.1, 0.15)
        gfx.rect(scrollbar_x, list_y, scrollbar_w, scrollbar_h, true)

        -- Scrollbar thumb
        gfx.set(0, 0.6, 0.6)
        gfx.rect(scrollbar_x, thumb_y, scrollbar_w, thumb_h, true)

        -- Click on track jumps
        if ss.ui.was_clicked(scrollbar_x, list_y, scrollbar_w, scrollbar_h) then
            local mx, my = gfx.mouse_x, gfx.mouse_y
            -- position click relative to track
            local rel = (my - list_y) / (scrollbar_h - thumb_h)
            rel = math.max(0, math.min(1, rel))
            ss.font_picker_scroll = math.floor(rel * max_scroll + 0.5)
        end

        -- Drag thumb
        if (gfx.mouse_cap & 1) == 1 and ss.ui.mouse_in(scrollbar_x, thumb_y, scrollbar_w, thumb_h) and not ss.font_picker_dragging then
            -- start drag
            ss.font_picker_dragging = true
            ss.font_picker_drag_offset = gfx.mouse_y - thumb_y
        end
        if ss.font_picker_dragging then
            if (gfx.mouse_cap & 1) == 0 then
                ss.font_picker_dragging = false
            else
                local my = gfx.mouse_y
                local new_thumb_y = my - ss.font_picker_drag_offset
                new_thumb_y = math.max(list_y, math.min(list_y + scrollbar_h - thumb_h, new_thumb_y))
                local rel = (new_thumb_y - list_y) / (scrollbar_h - thumb_h)
                ss.font_picker_scroll = math.floor(rel * max_scroll + 0.5)
            end
        end
    end
    
    -- Font size multiplier controls (below the font list)
    local controls_y = list_y + list_h + 8
    local btn_w = 50
    local btn_h = 28
    local minus_x = dialog_x + 20
    local plus_x = dialog_x + dialog_w - btn_w - 20
    local label_x = dialog_x + dialog_w / 2 - 30
    
    -- Minus button (decrease font size)
    gfx.set(0.08, 0.15, 0.2)
    gfx.rect(minus_x, controls_y, btn_w, btn_h, true)
    
    if ss.ui.mouse_in(minus_x, controls_y, btn_w, btn_h) then
        gfx.set(1, 0.5, 1)  -- magenta hover
    else
        gfx.set(0.3, 0.8, 0.8)  -- cyan
    end
    gfx.rect(minus_x, controls_y, btn_w, btn_h, false)
    
    gfx.set(0.3, 0.8, 0.8)
    ss.set_font(16, true)
    gfx.x, gfx.y = minus_x + 14, controls_y + 4
    gfx.drawstr("-")
    
    if ss.ui.was_clicked(minus_x, controls_y, btn_w, btn_h) then
        ss.font_size_multiplier = math.max(0.7, ss.font_size_multiplier - 0.1)
        ss.save_config(ss.current_font, ss.font_size_multiplier)
    end
    
    -- Plus button (increase font size)
    gfx.set(0.08, 0.15, 0.2)
    gfx.rect(plus_x, controls_y, btn_w, btn_h, true)
    
    if ss.ui.mouse_in(plus_x, controls_y, btn_w, btn_h) then
        gfx.set(1, 0.5, 1)  -- magenta hover
    else
        gfx.set(0.3, 0.8, 0.8)  -- cyan
    end
    gfx.rect(plus_x, controls_y, btn_w, btn_h, false)
    
    gfx.set(0.3, 0.8, 0.8)
    ss.set_font(16, true)
    gfx.x, gfx.y = plus_x + 12, controls_y + 2
    gfx.drawstr("+")
    
    if ss.ui.was_clicked(plus_x, controls_y, btn_w, btn_h) then
        ss.font_size_multiplier = math.min(1.5, ss.font_size_multiplier + 0.1)
        ss.save_config(ss.current_font, ss.font_size_multiplier)
    end
    
    -- Font size label
    gfx.set(0.7, 0.7, 0.7)
    ss.set_font(12, false)
    gfx.x, gfx.y = label_x, controls_y + 7
    gfx.drawstr(string.format("%.0f%%", ss.font_size_multiplier * 100))
    
    -- Close button (below the size controls)
    local close_y = controls_y + btn_h + 10
    gfx.set(1, 0.2, 0.2)
    gfx.rect(dialog_x + 20, close_y, dialog_w - 40, 30, true)
    gfx.set(1, 1, 1)
    ss.set_font(12, true)
    gfx.x, gfx.y = dialog_x + dialog_w/2 - 20, close_y + 8
    gfx.drawstr("CLOSE")
    
    if ss.ui.was_clicked(dialog_x + 20, close_y, dialog_w - 40, 30) then
        ss.show_font_picker = false
        ss.font_search = ""  -- Clear search
    end
end

-- UI Helper functions
function ss.ui.mouse_in(x, y, w, h)
    return gfx.mouse_x >= x and gfx.mouse_x < x + w and
           gfx.mouse_y >= y and gfx.mouse_y < y + h
end

function ss.ui.was_clicked(x, y, w, h)
    local clicking = (gfx.mouse_cap & 1 == 1) and ss.ui.mouse_in(x, y, w, h)
    local was_down = (ss.ui.last_mouse_cap & 1 == 1)
    return clicking and not was_down
end

function ss.ui.draw()
    local w, h = gfx.w, gfx.h
    
    -- Background
    gfx.set(0.08, 0.12, 0.15)
    gfx.rect(0, 0, w, h, true)
    
    -- Header
    gfx.set(0.1, 0.18, 0.25)
    gfx.rect(0, 0, w, 50, true)
    gfx.set(0, 1, 1)
    gfx.rect(0, 0, w, 50, false)
    
    gfx.set(0, 1, 1)
    ss.set_font(24, true)
    gfx.x, gfx.y = 15, 12
    gfx.drawstr("SETLIST")
    
    -- Config gear button (top right)
    local gear_size = 24
    local gear_btn_x = w - gear_size - 15
    local gear_btn_y = 13
    
    if ss.ui.mouse_in(gear_btn_x - 5, gear_btn_y - 5, gear_size + 10, gear_size + 10) then
        gfx.set(1, 0.5, 1)  -- magenta hover
    else
        gfx.set(0.3, 0.8, 0.8)  -- cyan
    end
    
    -- Draw proper gear icon
    local cx = gear_btn_x + gear_size / 2
    local cy = gear_btn_y + gear_size / 2
    local outer_r = gear_size / 2 - 2
    local inner_r = outer_r * 0.6
    local tooth_depth = outer_r * 0.3
    
    -- Draw gear using filled polygon (teeth and body)
    local points = {}
    local num_teeth = 12
    
    for i = 0, num_teeth - 1 do
        -- Outer tooth point
        local angle_tooth = (i * math.pi * 2 / num_teeth)
        table.insert(points, {cx + math.cos(angle_tooth) * outer_r, cy + math.sin(angle_tooth) * outer_r})
        
        -- Inner valley point
        local angle_valley = ((i + 0.5) * math.pi * 2 / num_teeth)
        table.insert(points, {cx + math.cos(angle_valley) * inner_r, cy + math.sin(angle_valley) * inner_r})
    end
    
    -- Draw filled gear
    gfx.mode = 2  -- antialiasing
    for i = 1, #points do
        if i == 1 then
            gfx.line(points[i][1], points[i][2], points[#points][1], points[#points][2])
        else
            gfx.line(points[i][1], points[i][2], points[i-1][1], points[i-1][2])
        end
    end
    
    -- Draw center hole
    gfx.circle(cx, cy, inner_r * 0.35, true)
    
    if ss.ui.was_clicked(gear_btn_x - 5, gear_btn_y - 5, gear_size + 10, gear_size + 10) then
        ss.show_font_picker = true
    end
    
    -- Song list area
    local list_y = 60
    local list_h = h - 150
    local row_h = 40
    local max_rows = math.floor(list_h / row_h)
    
    -- Draw songs
    for i = 1, math.min(#ss.songs, max_rows) do
        local y = list_y + (i - 1) * row_h
        local is_current = (ss.current_index == i)
        local is_selected = (ss.ui.selected == i)
        local is_playing = reaper.GetPlayStateEx(0) == 1
        
        -- Row background - alternating stripes
        if i % 2 == 0 then
            gfx.set(0.08, 0.15, 0.2)
        else
            gfx.set(0.1, 0.18, 0.25)
        end
        gfx.rect(0, y, w, row_h, true)
        
        -- Current/selected highlight
        if is_current and is_playing then
            gfx.set(0, 1, 1)  -- cyan for currently playing
            gfx.rect(0, y, w, row_h, false)
        elseif is_selected then
            gfx.set(1, 0, 1)  -- magenta for selected
            gfx.rect(0, y, w, row_h, false)
        end
        
        -- Song text
        if is_current and is_playing then
            gfx.set(0, 1, 1)  -- cyan text
        elseif is_selected then
            gfx.set(1, 0, 1)  -- magenta text
        else
            gfx.set(0.7, 0.7, 0.7)  -- normal text
        end
        -- Scale text size based on configured multiplier (maintains relative sizing)
        local text_size = math.floor(18 * ss.font_size_multiplier)
        ss.set_font(text_size, true)
        gfx.x, gfx.y = 20, y + 11
        gfx.drawstr(i .. ". " .. ss.songs[i].name)
        
        -- Click to select
        if ss.ui.was_clicked(0, y, w, row_h) then
            ss.ui.selected = i
            ss.log_file("Selected song " .. i)
        end
    end
    
    -- Loop toggle button (full width)
    local loop_btn_y = h - 280
    local loop_btn_h = 140
    
    -- Check if user toggled loop (sync UI state with Reaper state changes)
    if ss.ui.was_clicked(10, loop_btn_y, w - 20, loop_btn_h) then
        -- Toggle Reaper's loop state via action 1068 (Toggle loop)
        reaper.Main_OnCommand(1068, 0)
        -- Update our tracking
        ss.ui.loop_enabled = not ss.ui.loop_enabled
        
        ss.log_file("Loop " .. (ss.ui.loop_enabled and "ENABLED" or "DISABLED"))
    end
    
    local loop_is_enabled = ss.ui.loop_enabled
    
    -- Calculate pulse effect based on tempo
    local tempo = reaper.Master_GetTempo()
    local beat_time = 60 / tempo  -- seconds per beat
    local pulse_cycle = beat_time * 2  -- full pulse cycle = 2 beats
    local phase = (reaper.time_precise() % pulse_cycle) / pulse_cycle  -- 0 to 1
    
    -- When disabled, pulse the opacity; when enabled, solid
    local brightness = 1.0
    if not loop_is_enabled then
        -- Sine wave pulse from 0.5 to 1.0
        brightness = 0.5 + 0.5 * math.sin(phase * math.pi)
    end
    
    -- Set background color based on state with pulse effect
    if loop_is_enabled then
        gfx.set(1, 1, 0)  -- yellow when enabled
    else
        gfx.set(0 * brightness, 1 * brightness, 0 * brightness)  -- pulsing green when disabled
    end
    gfx.rect(10, loop_btn_y, w - 20, loop_btn_h, true)
    
    -- Border
    if ss.ui.mouse_in(10, loop_btn_y, w - 20, loop_btn_h) then
        gfx.set(1, 1, 1)  -- white hover
    else
        gfx.set(0.2, 0.2, 0.2)  -- dark border
    end
    gfx.rect(10, loop_btn_y, w - 20, loop_btn_h, false)
    
    -- Draw "LOOP ON" or "LOOP OFF" text centered, based on actual Reaper state
    gfx.set(0, 0, 0)  -- black text
    ss.set_font(56, true)
    local loop_text = loop_is_enabled and "LOOP ON" or "LOOP OFF"
    local text_width = gfx.measurestr(loop_text)
    gfx.x, gfx.y = (w - 20) / 2 + 10 - text_width / 2, loop_btn_y + loop_btn_h / 2 - 28
    gfx.drawstr(loop_text)
    
    -- Transport controls at bottom
    local transport_y = h - 120
    local btn_h = 100
    local btn_w = 100
    local spacing = 80
    local center_x = (w - (btn_w * 3 + spacing * 2)) / 2
    local is_playing = reaper.GetPlayStateEx(0) == 1
    
    -- << Back button
    local back_x = center_x
    gfx.set(0.08, 0.15, 0.2)
    gfx.rect(back_x, transport_y, btn_w, btn_h, true)
    
    if ss.ui.mouse_in(back_x, transport_y, btn_w, btn_h) then
        gfx.set(0, 1, 1)
        gfx.rect(back_x, transport_y, btn_w, btn_h, false)
    else
        gfx.set(0.3, 0.3, 0.3)
        gfx.rect(back_x, transport_y, btn_w, btn_h, false)
    end
    
    if ss.ui.was_clicked(back_x, transport_y, btn_w, btn_h) then
        local new_idx = ss.ui.selected - 1
        if new_idx < 1 then new_idx = #ss.songs end
        ss.ui.selected = new_idx
        ss.load_song(new_idx)
        ss.log_file("Back: loaded song " .. new_idx)
    end
    
    -- Draw << icon
    gfx.set(0, 1, 1)
    ss.set_font(48, true)
    gfx.x, gfx.y = back_x + 20, transport_y + 25
    gfx.drawstr("<<")
    
    -- Play/Stop toggle button (combined)
    local play_stop_x = back_x + btn_w + spacing
    gfx.set(0.08, 0.15, 0.2)
    gfx.rect(play_stop_x, transport_y, btn_w, btn_h, true)
    
    if ss.ui.mouse_in(play_stop_x, transport_y, btn_w, btn_h) then
        if is_playing then
            gfx.set(1, 0.4, 0.4)  -- lighter red for stop hover
        else
            gfx.set(0, 1, 0.4)  -- lighter green for play hover
        end
        gfx.rect(play_stop_x, transport_y, btn_w, btn_h, false)
    else
        if is_playing then
            gfx.set(1, 0.2, 0.2)  -- red for stop
        else
            gfx.set(0, 1, 0)  -- green for play
        end
        gfx.rect(play_stop_x, transport_y, btn_w, btn_h, false)
    end
    
    if ss.ui.was_clicked(play_stop_x, transport_y, btn_w, btn_h) then
        if is_playing then
            reaper.OnStopButtonEx(0)
            ss.log_file("Stop pressed")
        else
            ss.load_song(ss.ui.selected)
            ss.log_file("Play pressed for song " .. ss.ui.selected)
        end
    end
    
    -- Draw play triangle or stop square icon
    if is_playing then
        -- Draw stop square icon (red)
        gfx.set(1, 0.2, 0.2)
        gfx.rect(play_stop_x + 30, transport_y + 30, 40, 40, true)
    else
        -- Draw play triangle icon (green) - pointing right
        gfx.set(0, 1, 0)
        local cx = play_stop_x + 50
        local cy = transport_y + 50
        for x_offset = 0, 30 do
            local top = cy - (x_offset * 30 / 30)
            local bottom = cy + (x_offset * 30 / 30)
            gfx.line(cx - 15 + 30 - x_offset, top, cx - 15 + 30 - x_offset, bottom)
        end
    end
    
    -- >> Skip button
    local skip_x = play_stop_x + btn_w + spacing
    gfx.set(0.08, 0.15, 0.2)
    gfx.rect(skip_x, transport_y, btn_w, btn_h, true)
    
    if ss.ui.mouse_in(skip_x, transport_y, btn_w, btn_h) then
        gfx.set(0, 1, 1)
        gfx.rect(skip_x, transport_y, btn_w, btn_h, false)
    else
        gfx.set(0.3, 0.3, 0.3)
        gfx.rect(skip_x, transport_y, btn_w, btn_h, false)
    end
    
    if ss.ui.was_clicked(skip_x, transport_y, btn_w, btn_h) then
        local new_idx = ss.ui.selected + 1
        if new_idx > #ss.songs then new_idx = 1 end
        ss.ui.selected = new_idx
        ss.load_song(new_idx)
        ss.log_file("Skip: loaded song " .. new_idx)
    end
    
    -- Draw >> icon
    gfx.set(0, 1, 1)
    ss.set_font(48, true)
    gfx.x, gfx.y = skip_x + 20, transport_y + 25
    gfx.drawstr(">>")
end

function ss.main()
    ss.init()
    
    -- Auto-switch state machine
    -- State 0: idle
    -- State 1: loaded, waiting to play (give Reaper one frame to settle)
    if ss.auto_switch_state == 1 then
        -- Project is loaded, now play it
        ss.log("   Playing (after wait)")
        ss.log_file("auto_switch: playing after wait for index " .. ss.current_index)
        reaper.Main_OnCommand(1007, 0)
        ss.auto_switch_state = 0  -- Back to idle
    end
    
    -- Loop detection for auto-switch (independent of loop_enabled - that's just for Reaper's intro loop)
    if #ss.songs > 0 and ss.switch_cooldown <= 0 then
        local is_playing = reaper.GetPlayStateEx(0) == 1
        local pos = reaper.GetPlayPosition2Ex(0)
        
        -- Get the End marker position if it exists
        local end_marker_pos = nil
        for i = 0, reaper.CountProjectMarkers(0) - 1 do
            local retval, isrgn, pos_marker, rgnend, name, markidx = reaper.EnumProjectMarkers(i)
            if name == "End" and not isrgn then
                end_marker_pos = pos_marker
                break
            end
        end
        
        -- Log position every 30 frames
        ss.loop_check_counter = ss.loop_check_counter + 1
        if ss.loop_check_counter % 30 == 0 then
            local end_info = end_marker_pos and string.format("%.2f", end_marker_pos) or "none"
            ss.log_file("MONITOR: index=" .. ss.current_index .. " pos=" .. string.format("%.2f", pos) .. " end_marker=" .. end_info .. " playing=" .. (is_playing and "yes" or "no") .. " cooldown=" .. ss.switch_cooldown)
        end
        
        if is_playing then
            -- Detect when playback passes the End marker
            if end_marker_pos and ss.last_pos < end_marker_pos and pos >= end_marker_pos then
                ss.log("End marker reached at " .. math.floor(pos) .. "s (marker at " .. math.floor(end_marker_pos) .. "s)")
                ss.log_file("END_MARKER_REACHED: index=" .. ss.current_index .. " pos=" .. string.format("%.2f", pos) .. " marker_pos=" .. string.format("%.2f", end_marker_pos))
                
                -- If this is the LAST song, just stop - don't auto-switch
                if ss.current_index >= #ss.songs then
                    ss.log("Last song finished - stopping playback")
                    ss.log_file("LAST_SONG: stopping playback at index " .. ss.current_index)
                    reaper.OnStopButtonEx(0)
                else
                    -- Auto-switch to next song
                    ss.log("Switching to next song")
                    ss.log_file("AUTO_SWITCH: End marker reached at index " .. ss.current_index .. ", switching to next")
                    reaper.OnStopButtonEx(0)
                    ss.log("Stopped playback")
                    ss.log_file("AUTO_SWITCH: stopped playback")
                    
                    local next_idx = ss.current_index + 1
                    ss.load_song_no_play(next_idx)
                    ss.switch_cooldown = 10  -- Prevent rapid re-triggering
                    ss.log_file("AUTO_SWITCH: scheduled load_song_no_play for index " .. next_idx .. ", cooldown set to 10")
                end
            end
        else
            -- Playback stopped - check if we were near the end marker (song finished)
            if end_marker_pos and ss.last_pos >= end_marker_pos - 2 and ss.last_pos > 0 then
                ss.log("Song finished (playback stopped near end marker)")
                ss.log_file("SONG_FINISHED: index=" .. ss.current_index .. " last_pos=" .. string.format("%.2f", ss.last_pos) .. " marker_pos=" .. string.format("%.2f", end_marker_pos))
                
                -- If this is the LAST song, just stop
                if ss.current_index >= #ss.songs then
                    ss.log("Last song finished - stopping")
                    ss.log_file("LAST_SONG: finished at index " .. ss.current_index)
                else
                    -- Auto-switch to next song
                    ss.log("Song finished, switching to next")
                    ss.log_file("AUTO_SWITCH: song finished at index " .. ss.current_index .. ", switching to next")
                    
                    local next_idx = ss.current_index + 1
                    ss.load_song_no_play(next_idx)
                    ss.switch_cooldown = 10
                    ss.log_file("AUTO_SWITCH: scheduled load_song_no_play for index " .. next_idx .. ", cooldown set to 10")
                end
                ss.last_pos = 0
            elseif not is_playing then
                ss.switch_cooldown = 0
                if ss.last_pos > 0 then
                    ss.log_file("NOT_PLAYING: playstate=" .. reaper.GetPlayStateEx(0) .. " pos=" .. string.format("%.2f", pos) .. " last_pos=" .. string.format("%.2f", ss.last_pos))
                end
            end
        end
        
        ss.last_pos = pos
    else
        if ss.switch_cooldown > 0 then
            ss.switch_cooldown = ss.switch_cooldown - 1
        end
    end
    
    -- Handle keyboard input for font search
    if ss.show_font_picker then
        local char = gfx.getchar()
        if char > 0 then
            if char == 8 then  -- Backspace
                if #ss.font_search > 0 then
                    ss.font_search = ss.font_search:sub(1, -2)
                end
            elseif char == 27 then  -- Escape - close picker
                ss.show_font_picker = false
                ss.font_search = ""
            elseif char >= 32 and char <= 126 then  -- Printable ASCII
                ss.font_search = ss.font_search .. string.char(char)
            end
            ss.font_picker_scroll = 0  -- Reset scroll on search change
        end
    end
    
    -- Draw UI
    ss.ui.draw()
    
    -- Draw font picker if shown
    if ss.show_font_picker then
        ss.draw_font_picker()
    end
    
    -- Update mouse state
    ss.ui.last_mouse_cap = gfx.mouse_cap
    gfx.update()
    
    reaper.defer(ss.main)
end

-- Initialize gfx window
gfx.init("REAPER Song Switcher - Transport", 700, 750, 0)
gfx.dock(-1)

-- Load system fonts on startup
ss.load_config()
ss.get_system_fonts()

ss.main()
