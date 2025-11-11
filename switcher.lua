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

function ss.log(msg)
    reaper.ShowConsoleMsg("[SS] " .. msg .. "\n")
end

function ss.load_json()
    local f = io.open(ss.setlist_file, "r")
    if not f then
        ss.log("ERROR: No setlist.json")
        return false
    end
    local content = f:read("*a")
    f:close()
    
    ss.base_path = string.match(content, '"base_path"%s*:%s*"([^"]+)"')
    if not ss.base_path then
        ss.log("ERROR: No base_path in JSON")
        return false
    end
    
    ss.songs = {}
    for name, path in string.gmatch(content, '"name"%s*:%s*"([^"]+)".-"path"%s*:%s*"([^"]+)"') do
        table.insert(ss.songs, {name = name, path = path})
    end
    
    if #ss.songs == 0 then
        ss.log("ERROR: No songs in JSON")
        return false
    end
    
    ss.log("✓ Loaded " .. #ss.songs .. " songs")
    return true
end

function ss.open(idx)
    if idx < 1 or idx > #ss.songs then return end
    local song = ss.songs[idx]
    local path = ss.base_path .. "/" .. song.path
    
    if io.open(path, "r") then
        io.close()
        ss.log("► " .. idx .. ". " .. song.name)
        reaper.Main_openProject(path)
        ss.current_index = idx
        ss.last_pos = 0
        
        -- Set play position to 0 first
        reaper.SetEditCurPos(0, false, false)
        
        -- Use action ID 1007 - PLAY (from Reaper API docs)
        reaper.Main_OnCommand(1007, 0)
        
        ss.log("   Playing")
    else
        ss.log("ERROR: File not found: " .. path)
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
        reaper.Main_openProject(path)
        ss.current_index = idx
        ss.last_pos = 0
        
        -- Set play position to 0 first
        reaper.SetEditCurPos(0, false, false)
        
        -- DO NOT PLAY YET - just set state flag, play will happen next frame
        ss.auto_switch_state = 1
    else
        ss.log("ERROR: File not found: " .. path)
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
        reaper.Main_OnCommand(1007, 0)
        ss.auto_switch_state = 0  -- Back to idle
    end
    
    -- Loop detection for auto-switch
    if #ss.songs > 0 and ss.switch_cooldown <= 0 then
        local is_playing = reaper.GetPlayStateEx(0) == 1
        if is_playing then
            local pos = reaper.GetPlayPosition2Ex(0)
            -- Detect loop: position jumped from >50s back to <5s (song restarted)
            if ss.last_pos > 50 and pos < 5 then
                ss.log("Loop detected at " .. math.floor(pos) .. "s (was " .. math.floor(ss.last_pos) .. "s)")
                
                -- If this is the LAST song, just stop - don't auto-switch
                if ss.current_index >= #ss.songs then
                    ss.log("Last song finished - stopping playback")
                    reaper.OnStopButtonEx(0)
                else
                    -- Auto-switch to next song
                    ss.log("Switching to next song")
                    reaper.OnStopButtonEx(0)
                    ss.log("Stopped playback")
                    
                    local next_idx = ss.current_index + 1
                    ss.open_no_play(next_idx)
                    ss.switch_cooldown = 10  -- Prevent rapid re-triggering
                end
            end
            ss.last_pos = pos
        else
            ss.switch_cooldown = 0
            ss.last_pos = 0
        end
    else
        if ss.switch_cooldown > 0 then
            ss.switch_cooldown = ss.switch_cooldown - 1
        end
    end
    
    reaper.defer(ss.main)
end

ss.main()
