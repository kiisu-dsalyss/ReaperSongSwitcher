-- REAPER SONG SWITCHER - TRANSPORT CONTROL UI
-- Auto-switches songs with visual transport controls

_G.SS = _G.SS or {}
local ss = _G.SS

ss.script_dir = reaper.GetResourcePath() .. "/Scripts/ReaperSongSwitcher"
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
ss.ui = ss.ui or {}
ss.ui.selected = ss.ui.selected or 1
ss.ui.last_mouse_cap = ss.ui.last_mouse_cap or 0
ss.ui.loop_enabled = ss.ui.loop_enabled or true  -- Auto-loop is on by default
ss.ui.pulse_phase = ss.ui.pulse_phase or 0  -- For pulsing animation

function ss.log(msg)
    reaper.ShowConsoleMsg("[SS] " .. msg .. "\n")
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
        if ss.load_json() then
            ss.init_done = true
            ss.log("Ready!")
            ss.load_song(1)  -- Auto-load first song
        else
            reaper.defer(ss.init)
            return
        end
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
    gfx.setfont(1, "Arial", 24, 'b')
    gfx.x, gfx.y = 15, 12
    gfx.drawstr("SETLIST")
    
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
        gfx.setfont(1, "Arial", 18, 'b')
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
    
    -- Calculate pulse effect based on tempo
    local tempo = reaper.Master_GetTempo()
    local beat_time = 60 / tempo  -- seconds per beat
    local pulse_cycle = beat_time * 2  -- full pulse cycle = 2 beats
    local phase = (reaper.time_precise() % pulse_cycle) / pulse_cycle  -- 0 to 1
    
    -- When disabled, pulse the opacity; when enabled, solid
    local brightness = 1.0
    if not ss.ui.loop_enabled then
        -- Sine wave pulse from 0.5 to 1.0
        brightness = 0.5 + 0.5 * math.sin(phase * math.pi)
    end
    
    -- Set background color based on state with pulse effect
    if ss.ui.loop_enabled then
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
    
    if ss.ui.was_clicked(10, loop_btn_y, w - 20, loop_btn_h) then
        ss.ui.loop_enabled = not ss.ui.loop_enabled
        
        -- Toggle Reaper's loop state via action 1068 (Toggle loop)
        reaper.Main_OnCommand(1068, 0)
        
        ss.log_file("Loop " .. (ss.ui.loop_enabled and "ENABLED" or "DISABLED"))
    end
    
    -- Draw "LOOP ON" or "LOOP OFF" text centered
    gfx.set(0, 0, 0)  -- black text
    gfx.setfont(1, "Arial", 56, 'b')
    local loop_text = ss.ui.loop_enabled and "LOOP ON" or "LOOP OFF"
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
    gfx.setfont(1, "Arial", 48, 'b')
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
    gfx.setfont(1, "Arial", 48, 'b')
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
    
    -- Loop detection for auto-switch (only if loop is enabled)
    if ss.ui.loop_enabled and #ss.songs > 0 and ss.switch_cooldown <= 0 then
        local is_playing = reaper.GetPlayStateEx(0) == 1
        if is_playing then
            local pos = reaper.GetPlayPosition2Ex(0)
            
            -- Log position every 30 frames (roughly every 0.3s at 100fps) for debugging
            ss.loop_check_counter = ss.loop_check_counter + 1
            if ss.loop_check_counter % 30 == 0 then
                ss.log_file("MONITOR: index=" .. ss.current_index .. " pos=" .. string.format("%.2f", pos) .. " last_pos=" .. string.format("%.2f", ss.last_pos) .. " cooldown=" .. ss.switch_cooldown)
            end
            
            -- Detect loop: position jumped from >50s back to <5s (song restarted)
            if ss.last_pos > 50 and pos < 5 then
                ss.log("Loop detected at " .. math.floor(pos) .. "s (was " .. math.floor(ss.last_pos) .. "s)")
                ss.log_file("LOOP_DETECTED: index=" .. ss.current_index .. " pos=" .. string.format("%.2f", pos) .. " last_pos=" .. string.format("%.2f", ss.last_pos))
                
                -- If this is the LAST song, just stop - don't auto-switch
                if ss.current_index >= #ss.songs then
                    ss.log("Last song finished - stopping playback")
                    ss.log_file("LAST_SONG: stopping playback at index " .. ss.current_index)
                    reaper.OnStopButtonEx(0)
                else
                    -- Auto-switch to next song
                    ss.log("Switching to next song")
                    ss.log_file("AUTO_SWITCH: detected loop at index " .. ss.current_index .. ", switching to next")
                    reaper.OnStopButtonEx(0)
                    ss.log("Stopped playback")
                    ss.log_file("AUTO_SWITCH: stopped playback")
                    
                    local next_idx = ss.current_index + 1
                    ss.load_song_no_play(next_idx)
                    ss.switch_cooldown = 10  -- Prevent rapid re-triggering
                    ss.log_file("AUTO_SWITCH: scheduled load_song_no_play for index " .. next_idx .. ", cooldown set to 10")
                end
            elseif ss.last_pos > 50 and pos >= 5 then
                -- Position is still high, no loop yet
                ss.log_file("NO_LOOP: pos=" .. string.format("%.2f", pos) .. " < threshold, last_pos=" .. string.format("%.2f", ss.last_pos))
            end
            ss.last_pos = pos
        else
            ss.switch_cooldown = 0
            ss.last_pos = 0
            ss.log_file("NOT_PLAYING: playstate=" .. reaper.GetPlayStateEx(0))
        end
    else
        if ss.switch_cooldown > 0 then
            ss.switch_cooldown = ss.switch_cooldown - 1
            if ss.switch_cooldown % 5 == 0 then
                ss.log_file("COOLDOWN: remaining=" .. ss.switch_cooldown)
            end
        end
    end
    
    -- Draw UI
    ss.ui.draw()
    
    -- Update mouse state
    ss.ui.last_mouse_cap = gfx.mouse_cap
    gfx.update()
    
    reaper.defer(ss.main)
end

-- Initialize gfx window
gfx.init("REAPER Song Switcher - Transport", 700, 750, 0)
gfx.dock(-1)

ss.main()
