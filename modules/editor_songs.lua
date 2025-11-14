-- Setlist Editor - Song Management Operations

local songs = {}

function songs.add_song(ed)
    table.insert(ed.songs, {name = "New Song", path = "path/to/song.rpp"})
    ed.dirty = true
    ed.log("Added new song")
end

function songs.delete_song(ed, idx)
    if idx >= 1 and idx <= #ed.songs then
        table.remove(ed.songs, idx)
        ed.dirty = true
        ed.selected_idx = 0
        ed.log("Deleted song " .. idx)
    end
end

function songs.start_edit(ed, idx)
    if idx >= 1 and idx <= #ed.songs then
        ed.edit_mode = true
        ed.edit_idx = idx
        ed.edit_name = ed.songs[idx].name
        ed.edit_path = ed.songs[idx].path
        ed.edit_focus = "name"
        ed.log("Started editing song " .. idx .. ": " .. ed.edit_name)
    end
end

function songs.finish_edit(ed)
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

function songs.cancel_edit(ed)
    ed.edit_mode = false
    ed.edit_name = ""
    ed.edit_path = ""
    ed.edit_idx = 0
end

function songs.pick_file(ed)
    -- Open file browser to select a .rpp file
    local success, filepath = reaper.GetUserFileNameForRead(ed.base_path, "Open REAPER Project", ".rpp")
    if success and filepath and filepath ~= "" then
        ed.log("Selected file (full): " .. filepath)
        
        -- Trim base path to make it relative
        if ed.base_path and ed.base_path ~= "" then
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

function songs.swap_songs(ed, i, j)
    if i >= 1 and i <= #ed.songs and j >= 1 and j <= #ed.songs then
        ed.songs[i], ed.songs[j] = ed.songs[j], ed.songs[i]
        ed.dirty = true
        ed.log("Reordered songs")
    end
end

return songs
