-- Utility functions module
local utils = {}

function utils.log_to_file(filepath, msg)
    local f = io.open(filepath, "a")
    if not f then
        os.execute('mkdir -p "' .. filepath:match("^(.+)/[^/]+$") .. '"')
        f = io.open(filepath, "a")
        if not f then return end
    end
    local ts = os.date("%Y-%m-%d %H:%M:%S")
    f:write("[" .. ts .. "] " .. msg .. "\n")
    f:close()
end

function utils.log_transport(script_dir, msg)
    utils.log_to_file(script_dir .. "/switcher_transport.log", msg)
end

function utils.log_switcher(script_dir, msg)
    utils.log_to_file(script_dir .. "/switcher.log", msg)
end

function utils.mouse_in(gfx, x, y, w, h)
    return gfx.mouse_x >= x and gfx.mouse_x < x + w and
           gfx.mouse_y >= y and gfx.mouse_y < y + h
end

function utils.was_clicked(gfx, x, y, w, h, last_mouse_cap)
    local clicking = (gfx.mouse_cap & 1 == 1) and utils.mouse_in(gfx, x, y, w, h)
    local was_down = (last_mouse_cap & 1 == 1)
    return clicking and not was_down
end

return utils
