-- Playback Module - Song loading and playback state management

local playback = {}

-- Load a song and start playing
function playback.load_song(idx, ss)
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
        
        local loop_state = reaper.GetSetRepeat(-1)
        ss.ui.loop_enabled = (loop_state == 1)
        ss.log_file("load_song(): Synced loop state: " .. (ss.ui.loop_enabled and "ON" or "OFF"))
        
        reaper.SetEditCurPos(0, false, false)
        reaper.Main_OnCommand(1007, 0)
        
        ss.log("   Playing")
        ss.log_file("load_song(): Started playing index " .. idx .. " - " .. song.name)
    else
        ss.log("ERROR: File not found: " .. path)
        ss.log_file("ERROR: File not found in load_song(): " .. path)
    end
end

-- Load a song without playing (deferred playback)
function playback.load_song_no_play(idx, ss)
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
        
        local loop_state = reaper.GetSetRepeat(-1)
        ss.ui.loop_enabled = (loop_state == 1)
        ss.log_file("load_song_no_play(): Synced loop state: " .. (ss.ui.loop_enabled and "ON" or "OFF"))
        
        reaper.SetEditCurPos(0, false, false)
        ss.auto_switch_state = 1
        ss.log_file("load_song_no_play(): set auto_switch_state=1 for index " .. idx)
    else
        ss.log("ERROR: File not found: " .. path)
        ss.log_file("ERROR: File not found in load_song_no_play(): " .. path)
    end
end

-- Handle auto-switching logic when near end of project
function playback.handle_auto_switch(ss)
    local pos = reaper.GetPlayPosition()
    local is_playing = reaper.GetPlayStateEx(0) == 1
    
    if ss.init_done and #ss.songs > 0 then
        if is_playing then
            if pos >= ss.last_pos then
                ss.last_pos = pos
            else
                local proj_length = reaper.GetProjectLength(0)
                
                if ss.switched then
                    if ss.auto_switch_state == 1 then
                        reaper.Main_OnCommand(1007, 0)
                        ss.auto_switch_state = 0
                        ss.log("Auto-switched and played")
                        ss.log_file("Auto-switched and played index " .. ss.current_index)
                    end
                    ss.switched = false
                end
            end
            
            if ss.switch_cooldown > 0 then
                ss.switch_cooldown = ss.switch_cooldown - 1
            else
                local proj_length = reaper.GetProjectLength(0)
                if pos > proj_length - 3 and not ss.switched and ss.current_index < #ss.songs then
                    ss.log("Song near end, auto-switching...")
                    ss.log_file("Song near end at " .. string.format("%.2f", pos) .. ", length=" .. string.format("%.2f", proj_length))
                    
                    ss.switched = true
                    local next_idx = ss.current_index + 1
                    playback.load_song_no_play(next_idx, ss)
                    ss.switch_cooldown = 10
                    ss.log_file("AUTO_SWITCH: scheduled load_song_no_play for index " .. next_idx .. ", cooldown set to 10")
                end
            end
        else
            if ss.switch_cooldown > 0 then
                ss.switch_cooldown = ss.switch_cooldown - 1
            end
        end
        
        ss.last_pos = pos
    else
        if ss.switch_cooldown > 0 then
            ss.switch_cooldown = ss.switch_cooldown - 1
        end
    end
end

return playback
