-- REAPER SONG SWITCHER
-- One script. Auto-switches songs. Clickable UI.

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
    reaper.ShowConsoleMsg("[SS] " .. msg .. "\n")
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
    
    -- Loop detection for auto-switch
    if #ss.songs > 0 and ss.switch_cooldown <= 0 then
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
                    ss.open_no_play(next_idx)
                    ss.switch_cooldown = 10  -- Prevent rapid re-triggering
                    ss.log_file("AUTO_SWITCH: scheduled open_no_play for index " .. next_idx .. ", cooldown set to 10")
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
        end
    else
        if ss.switch_cooldown > 0 then
            ss.switch_cooldown = ss.switch_cooldown - 1
        end
    end
    
    reaper.defer(ss.main)
end

ss.main()
