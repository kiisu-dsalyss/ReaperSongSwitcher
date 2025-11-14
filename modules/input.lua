-- Input Handling Module
-- Manages keyboard input, mouse state, and dialog interactions

local input = {}

-- Handle keyboard input for font search
function input.handle_font_search(ss, show_font_picker, show_load_setlist_dialog)
    -- Only process if font picker is open and load dialog is NOT open
    if show_font_picker and not show_load_setlist_dialog then
        local char = gfx.getchar()
        if char > 0 then
            if char == 8 then  -- Backspace
                if #ss.font_search > 0 then
                    ss.font_search = ss.font_search:sub(1, -2)
                end
            elseif char == 27 then  -- Escape - close picker
                ss.show_font_picker = false
                ss.font_search = ""
            elseif char >= 32 and char <= 126 then  -- Printable ASCII
                ss.font_search = ss.font_search .. string.char(char)
            end
            ss.font_picker_scroll = 0  -- Reset scroll on search change
        end
    end
end

-- Update mouse state for next frame
function input.update_mouse_state(ss)
    ss.ui.last_mouse_cap = gfx.mouse_cap
end

return input
