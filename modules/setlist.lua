-- Setlist loading and management module
local setlist = {}

function setlist.load_from_path(filepath, log_fn, log_file_fn)
    local f = io.open(filepath, "r")
    if not f then
        log_fn("ERROR: Could not open file: " .. filepath)
        log_file_fn("ERROR: Could not open file: " .. filepath)
        return nil
    end
    
    local content = f:read("*a")
    f:close()
    
    local base_path = string.match(content, '"base_path"%s*:%s*"([^"]+)"')
    if not base_path then
        log_fn("ERROR: No base_path in JSON at " .. filepath)
        log_file_fn("ERROR: No base_path in JSON at " .. filepath)
        return nil
    end
    
    local songs = {}
    for name, path in string.gmatch(content, '"name"%s*:%s*"([^"]+)".-"path"%s*:%s*"([^"]+)"') do
        table.insert(songs, {name = name, path = path})
    end
    
    if #songs == 0 then
        log_fn("ERROR: No songs in JSON at " .. filepath)
        log_file_fn("ERROR: No songs parsed from " .. filepath)
        return nil
    end
    
    log_fn("✓ Loaded " .. #songs .. " songs from " .. filepath)
    log_file_fn("Loaded " .. #songs .. " songs from " .. filepath)
    
    return {
        path = filepath,
        base_path = base_path,
        songs = songs
    }
end

function setlist.get_filename(filepath)
    return filepath:match("([^/]+)$") or "setlist.json"
end

return setlist
