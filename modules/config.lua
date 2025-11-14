-- Configuration management module
local config = {}

function config.load(script_dir, log_transport_fn)
    local config_file = script_dir .. "/config.json"
    local f = io.open(config_file, "r")
    if not f then
        log_transport_fn("Creating default config.json")
        return {
            ui_font = "Menlo",
            font_size_multiplier = 1.0,
            window_w = 700,
            window_h = 750
        }
    end
    
    local content = f:read("*a")
    f:close()
    
    local cfg = {
        ui_font = "Menlo",
        font_size_multiplier = 1.0,
        window_w = 700,
        window_h = 750
    }
    
    -- Parse JSON values
    local font_match = string.match(content, '"ui_font"%s*:%s*"([^"]+)"')
    if font_match then
        cfg.ui_font = font_match
        log_transport_fn("Loaded font from config: " .. cfg.ui_font)
    end
    
    local mult_match = string.match(content, '"font_size_multiplier"%s*:%s*([%d.]+)')
    if mult_match then
        cfg.font_size_multiplier = tonumber(mult_match)
        log_transport_fn("Loaded font size multiplier from config: " .. cfg.font_size_multiplier)
    end
    
    local w_match = string.match(content, '"window_w"%s*:%s*(%d+)')
    local h_match = string.match(content, '"window_h"%s*:%s*(%d+)')
    if w_match then cfg.window_w = tonumber(w_match) end
    if h_match then cfg.window_h = tonumber(h_match) end
    
    return cfg
end

function config.save(script_dir, font_name, multiplier, log_transport_fn)
    multiplier = multiplier or 1.0
    local config_file = script_dir .. "/config.json"
    local content = '{\n  "ui_font": "' .. font_name .. '",\n  "font_size_multiplier": ' .. 
                    string.format("%.2f", multiplier) .. ',\n  "window_w": 700,\n  "window_h": 750,\n' ..
                    '  "available_fonts": ["Arial", "Menlo", "Courier New", "Courier", "Monaco", "Helvetica"]\n}\n'
    
    local f = io.open(config_file, "w")
    if f then
        f:write(content)
        f:close()
        log_transport_fn("Saved config: " .. font_name .. " (multiplier: " .. string.format("%.2f", multiplier) .. ")")
        return true
    end
    return false
end

return config
