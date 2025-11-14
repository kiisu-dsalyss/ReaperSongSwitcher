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

-- Handle auto-switching logic with End marker detection
function playback.handle_auto_switch_v2(ss)
    if #ss.songs == 0 or ss.switch_cooldown > 0 then
        if ss.switch_cooldown > 0 then
            ss.switch_cooldown = ss.switch_cooldown - 1
        end
        return
    end
    
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
        ss.log_file("MONITOR: index=" .. ss.current_index .. " pos=" .. string.format("%.2f", pos) .. " end_marker=" .. end_info .. " playing=" .. (is_playing and "yes" or "no"))
    end
    
    if is_playing then
        -- Detect when playback passes the End marker
        if end_marker_pos and ss.last_pos < end_marker_pos and pos >= end_marker_pos then
            ss.log_file("END_MARKER_REACHED: index=" .. ss.current_index .. " pos=" .. string.format("%.2f", pos) .. " marker_pos=" .. string.format("%.2f", end_marker_pos))
            
            -- If this is the LAST song, just stop
            if ss.current_index >= #ss.songs then
                ss.log_file("LAST_SONG: stopping playback")
                reaper.OnStopButtonEx(0)
            else
                -- Auto-switch to next song
                ss.log_file("AUTO_SWITCH: End marker reached at index " .. ss.current_index .. ", switching to next")
                reaper.OnStopButtonEx(0)
                
                local next_idx = ss.current_index + 1
                playback.load_song_no_play(next_idx, ss)
                ss.switch_cooldown = 10
                ss.log_file("AUTO_SWITCH: scheduled load_song_no_play for index " .. next_idx)
            end
        end
    else
        -- Playback stopped - check if we were near the end marker (song finished)
        if end_marker_pos and ss.last_pos >= end_marker_pos - 2 and ss.last_pos > 0 then
            ss.log_file("SONG_FINISHED: index=" .. ss.current_index .. " last_pos=" .. string.format("%.2f", ss.last_pos))
            
            -- If this is the LAST song, just stop
            if ss.current_index >= #ss.songs then
                ss.log_file("LAST_SONG: finished")
            else
                -- Auto-switch to next song
                ss.log_file("AUTO_SWITCH: song finished at index " .. ss.current_index .. ", switching to next")
                
                local next_idx = ss.current_index + 1
                playback.load_song_no_play(next_idx, ss)
                ss.switch_cooldown = 10
                ss.log_file("AUTO_SWITCH: scheduled load_song_no_play for index " .. next_idx)
            end
            ss.last_pos = 0
        elseif not is_playing then
            ss.switch_cooldown = 0
        end
    end
    
    ss.last_pos = pos
end

return playback
