-- Setlist Editor - File I/O Operations
-- Load/save setlist.json and config management

local setlist_io = {}

function setlist_io.load_config(ed)
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

function setlist_io.load_json(ed)
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

function setlist_io.save_json(ed)
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

function setlist_io.open_load_dialog(ed)
    -- Open file browser to select a setlist.json file
    local success, filepath = reaper.GetUserFileNameForRead(ed.script_dir, "Load Setlist", "*.json")
    if success and filepath and filepath ~= "" then
        ed.log("Selected setlist: " .. filepath)
        ed.setlist_file = filepath
        ed.songs = {}
        setlist_io.load_json(ed)
        ed.log("Loaded setlist from: " .. filepath)
    else
        ed.log("Load cancelled")
    end
end

function setlist_io.open_create_dialog(ed)
    ed.create_dialog_open = true
    ed.new_setlist_name = ""
    ed.new_setlist_path = ""
    ed.log("Opened create new setlist dialog")
end

function setlist_io.close_create_dialog(ed)
    ed.create_dialog_open = false
    ed.new_setlist_name = ""
    ed.new_setlist_path = ""
end

function setlist_io.finish_create(ed)
    if ed.new_setlist_name == "" or ed.new_setlist_path == "" then
        ed.log("ERROR: Name and path required")
        return
    end
    
    -- Create new setlist with empty songs array
    ed.songs = {}
    ed.base_path = ed.new_setlist_path
    ed.dirty = false
    
    -- Set the new file path
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
    setlist_io.save_json(ed)
    ed.log("Created new setlist: " .. new_file_path)
    setlist_io.close_create_dialog(ed)
end

return setlist_io
