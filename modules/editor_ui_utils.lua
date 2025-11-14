-- Setlist Editor - UI Utilities and Helpers

local ui_utils = {}

function ui_utils.set_font(ed, size, bold)
    local font_flags = bold and 'b' or ''
    local scaled_size = math.floor(size * ed.font_size_multiplier)
    gfx.setfont(1, ed.current_font, scaled_size, font_flags)
end

function ui_utils.mouse_in(x, y, w, h)
    return gfx.mouse_x >= x and gfx.mouse_x < x + w and
           gfx.mouse_y >= y and gfx.mouse_y < y + h
end

function ui_utils.was_clicked(ed, x, y, w, h)
    local is_in = ui_utils.mouse_in(x, y, w, h)
    local was_pressed = (ed.last_mouse_cap & 1) > 0
    local is_pressed = (gfx.mouse_cap & 1) > 0
    local clicked = is_in and is_pressed and not was_pressed
    return clicked
end

function ui_utils.truncate_text(text, max_width)
    -- Approximate: each character is about 9 pixels wide at size 14
    local char_width = 9
    local max_chars = math.floor(max_width / char_width)
    
    if #text <= max_chars then
        return text
    end
    
    -- Truncate from the start, show end of path
    local start_chars = math.floor(max_chars / 3)
    local end_chars = max_chars - start_chars - 3
    return "..." .. text:sub(-end_chars)
end

function ui_utils.draw_rounded_rect(x, y, w, h, r, fill)
    -- Draw a rounded rectangle approximation using small circles at corners
    local radius = r or 4
    
    -- Main rectangle body
    gfx.rect(x + radius, y, w - 2*radius, h, fill)
    gfx.rect(x, y + radius, w, h - 2*radius, fill)
    
    -- Corner circles (approximate)
    if fill == 1 then
        gfx.circle(x + radius, y + radius, radius/2, fill)
        gfx.circle(x + w - radius, y + radius, radius/2, fill)
        gfx.circle(x + radius, y + h - radius, radius/2, fill)
        gfx.circle(x + w - radius, y + h - radius, radius/2, fill)
    end
end

function ui_utils.init_gfx()
    if not gfx.w or gfx.w == 0 then
        gfx.init("Setlist Editor", 700, 800)
    end
    
    if gfx.dock(-1) == 0 then
        gfx.dock(257)  -- DOCKFLAG_RIGHT
    end
end

return ui_utils
