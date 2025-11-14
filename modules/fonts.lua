-- Font detection and management module
local fonts = {}

function fonts.load_system_fonts(script_dir, log_transport_fn)
    local available_fonts = {}
    local font_set = {}
    
    log_transport_fn("Starting font detection...")
    
    local fonts_list_file = script_dir .. "/fonts_list.txt"
    log_transport_fn("Fonts list file: " .. fonts_list_file)
    
    local f = io.open(fonts_list_file, "r")
    if f then
        log_transport_fn("Fonts file opened")
        local count = 0
        for line in f:lines() do
            line = line:gsub("^%s+", ""):gsub("%s+$", "")
            if line ~= "" and #line < 200 then
                if not font_set[line] then
                    table.insert(available_fonts, line)
                    font_set[line] = true
                    count = count + 1
                    if count <= 10 then
                        log_transport_fn("  Font " .. count .. ": " .. line)
                    end
                end
            end
        end
        f:close()
        log_transport_fn("Fonts file closed. Total fonts found: " .. count)
    else
        log_transport_fn("ERROR: Could not open fonts_list.txt!")
    end
    
    if #available_fonts == 0 then
        log_transport_fn("No fonts found, using fallback list")
        available_fonts = {"Arial", "Menlo", "Courier New", "Courier", "Monaco", "Helvetica", "Times New Roman", "Verdana"}
    end
    
    log_transport_fn("Font loading complete: " .. #available_fonts .. " fonts available")
    return available_fonts
end

function fonts.set_font(gfx, font_name, size, bold)
    local font_flags = bold and 'b' or ''
    gfx.setfont(1, font_name, size, font_flags)
end

return fonts
