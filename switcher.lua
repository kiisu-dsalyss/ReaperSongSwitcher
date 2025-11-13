-- REAPER SONG SWITCHER
-- One script. Auto-switches songs. Clickable UI.

-- Set to false to disable console output
local ENABLE_CONSOLE_OUTPUT = false

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
ss.loop_check_counter = ss.loop_check_counter or 0  -- Rate-limit position logging

function ss.log(msg)
    if ENABLE_CONSOLE_OUTPUT then
        reaper.ShowConsoleMsg("[SS] " .. msg .. "\n")
    end
end

-- Append a timestamped message to a log file next to the script
function ss.log_file(msg)
    local ok, err
    local logfile = ss.script_dir .. "/switcher.log"
    local f, ferr = io.open(logfile, "a")
    if not f then
        -- Try to create directory
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

function ss.open(idx)
    if idx < 1 or idx > #ss.songs then return end
    local song = ss.songs[idx]
    local path = ss.base_path .. "/" .. song.path
    
    if io.open(path, "r") then
        io.close()
        ss.log("► " .. idx .. ". " .. song.name)
        ss.log_file("open(): Loading project: " .. path)
        reaper.Main_openProject(path)
        ss.current_index = idx
        ss.last_pos = 0
        
        -- Set play position to 0 first
        reaper.SetEditCurPos(0, false, false)
        
        -- Use action ID 1007 - PLAY (from Reaper API docs)
        reaper.Main_OnCommand(1007, 0)
        
        ss.log("   Playing")
        ss.log_file("open(): Started playing index " .. idx .. " - " .. song.name)
    else
        ss.log("ERROR: File not found: " .. path)
        ss.log_file("ERROR: File not found in open(): " .. path)
    end
end

-- Load song without playing (for auto-switch sequence: stop, load, wait, play)
function ss.open_no_play(idx)
    if idx < 1 or idx > #ss.songs then return end
    local song = ss.songs[idx]
    local path = ss.base_path .. "/" .. song.path
    
    if io.open(path, "r") then
        io.close()
        ss.log("► " .. idx .. ". " .. song.name .. " (loaded, will play next frame)")
        ss.log_file("open_no_play(): Loaded project: " .. path)
        reaper.Main_openProject(path)
        ss.current_index = idx
        ss.last_pos = 0
        
        -- Set play position to 0 first
        reaper.SetEditCurPos(0, false, false)
        
        -- DO NOT PLAY YET - just set state flag, play will happen next frame
        ss.auto_switch_state = 1
        ss.log_file("open_no_play(): set auto_switch_state=1 for index " .. idx)
    else
        ss.log("ERROR: File not found: " .. path)
        ss.log_file("ERROR: File not found in open_no_play(): " .. path)
    end
end

function ss.init()
    if not ss.init_done then
        if ss.load_json() then
            ss.init_done = true
            ss.log("Ready!")
            ss.open(1)  -- Auto-load first song
        else
            reaper.defer(ss.init)
            return
        end
    end
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
    
    -- Loop detection for auto-switch (ALWAYS runs, independent of any loop toggle)
    if #ss.songs > 0 and ss.switch_cooldown <= 0 then
        local is_playing = reaper.GetPlayStateEx(0) == 1
        if is_playing then
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
                ss.log_file("MONITOR: index=" .. ss.current_index .. " pos=" .. string.format("%.2f", pos) .. " end_marker=" .. end_info .. " cooldown=" .. ss.switch_cooldown)
            end
            
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
                    ss.open_no_play(next_idx)
                    ss.switch_cooldown = 10  -- Prevent rapid re-triggering
                    ss.log_file("AUTO_SWITCH: scheduled open_no_play for index " .. next_idx .. ", cooldown set to 10")
                end
            end
            ss.last_pos = pos
        else
            -- Playback stopped - check if we were near the end marker
            if end_marker_pos and ss.last_pos >= end_marker_pos - 2 and ss.last_pos > 0 then
                ss.log("Song finished (playback stopped near end marker)")
                ss.log_file("SONG_FINISHED: index=" .. ss.current_index .. " last_pos=" .. string.format("%.2f", ss.last_pos))
                
                if ss.current_index >= #ss.songs then
                    ss.log("Last song finished")
                else
                    -- Auto-switch to next song
                    ss.log("Song finished, switching to next")
                    local next_idx = ss.current_index + 1
                    ss.open_no_play(next_idx)
                    ss.switch_cooldown = 10
                end
                ss.last_pos = 0
            elseif not is_playing then
                ss.switch_cooldown = 0
            end
        end
        ss.last_pos = pos
    else
        if ss.switch_cooldown > 0 then
            ss.switch_cooldown = ss.switch_cooldown - 1
        end
    end
    
    reaper.defer(ss.main)
end

ss.main()
