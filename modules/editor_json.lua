-- Setlist Editor - JSON Editor Dialog
-- Raw JSON editing modal with proper text input

local json_editor = {}

function json_editor.open_json_editor(ed)
    ed.json_editor_open = true
    ed.json_content = ""
    ed.json_scroll_offset = 0
    ed.json_edit_focus = true
    ed.json_cursor_pos = 0
    ed.log("Opened JSON editor")
end

function json_editor.close_json_editor(ed)
    ed.json_editor_open = false
    ed.json_content = ""
    ed.json_scroll_offset = 0
    ed.json_cursor_pos = 0
end

function json_editor.load_json_to_editor(ed, io_mod)
    -- Read the current setlist.json into the editor
    local f = io.open(ed.setlist_file, "r")
    if f then
        ed.json_content = f:read("*a")
        f:close()
        ed.json_cursor_pos = 0
        ed.log("Loaded JSON content into editor")
    else
        ed.json_content = '{\n  "base_path": "",\n  "songs": []\n}'
        ed.json_cursor_pos = 0
        ed.log("Created empty JSON template")
    end
end

function json_editor.save_json_from_editor(ed)
    -- Parse and save the JSON from the editor
    if ed.json_content == "" then
        ed.log("ERROR: Empty JSON content")
        return false
    end
    
    local f = io.open(ed.setlist_file, "w")
    if not f then
        ed.log("ERROR: Cannot write setlist.json")
        return false
    end
    f:write(ed.json_content)
    f:close()
    
    ed.log("Saved JSON from editor")
    ed.dirty = false
    return true
end

function json_editor.draw_json_editor(ed, ui_utils)
    if not ed.json_editor_open then return end
    
    -- Dim background
    gfx.set(0, 0, 0)
    gfx.rect(0, 0, gfx.w, gfx.h, 1)
    gfx.set(0, 0, 0)
    gfx.rect(0, 0, gfx.w, gfx.h, 1)
    
    -- Dialog box
    local dialog_w = math.floor(gfx.w * 0.9)
    local dialog_h = math.floor(gfx.h * 0.85)
    local dialog_x = (gfx.w - dialog_w) / 2
    local dialog_y = (gfx.h - dialog_h) / 2
    
    gfx.set(0.08, 0.12, 0.15)  -- dark blue background
    gfx.rect(dialog_x, dialog_y, dialog_w, dialog_h, 1)
    
    gfx.set(0, 1, 0.5)  -- neon green border
    gfx.rect(dialog_x, dialog_y, dialog_w, dialog_h, 0)
    
    -- Title
    gfx.set(0, 1, 0.5)
    ui_utils.set_font(ed, 16, true)
    gfx.x, gfx.y = dialog_x + 20, dialog_y + 10
    gfx.drawstr("JSON EDITOR - Click to edit, Enter for newline, Backspace to delete")
    
    -- Text area
    local text_area_y = dialog_y + 35
    local text_area_h = dialog_h - 90
    local text_area_w = dialog_w - 40
    
    -- Background
    gfx.set(0.1, 0.15, 0.2)
    gfx.rect(dialog_x + 20, text_area_y, text_area_w, text_area_h, 1)
    
    -- Border
    gfx.set(0, 1, 0.5)
    gfx.rect(dialog_x + 20, text_area_y, text_area_w, text_area_h, 0)
    
    -- Make text area clickable to focus
    if ui_utils.was_clicked(ed, dialog_x + 20, text_area_y, text_area_w, text_area_h) then
        ed.json_edit_focus = true
    end
    
    -- Draw JSON content
    gfx.set(0.9, 0.9, 0.9)
    ui_utils.set_font(ed, 11, false)
    
    local lines = {}
    for line in ed.json_content:gmatch("[^\n]*") do
        table.insert(lines, line)
    end
    
    local line_h = 16
    local visible_lines = math.floor(text_area_h / line_h)
    
    -- Draw lines with line numbers
    for i = 1, math.min(visible_lines, #lines) do
        local line_num = i + ed.json_scroll_offset
        if line_num <= #lines then
            local line = lines[line_num]
            
            -- Line number
            gfx.set(0.5, 0.5, 0.5)
            gfx.x, gfx.y = dialog_x + 25, text_area_y + (i - 1) * line_h + 5
            gfx.drawstr(string.format("%3d ", line_num))
            
            -- Line content
            gfx.set(0.9, 0.9, 0.9)
            gfx.x, gfx.y = dialog_x + 50, text_area_y + (i - 1) * line_h + 5
            gfx.drawstr(line)
        end
    end
    
    -- Blinking cursor at end of content
    if ed.json_edit_focus and (reaper.time_precise() * 2) % 1 < 0.5 then
        gfx.set(0, 1, 0.5)
        ui_utils.set_font(ed, 11, false)
        -- Find last line
        local last_line_num = math.min(visible_lines, #lines)
        if last_line_num > 0 then
            local last_line = lines[#lines] or ""
            local text_w, _ = gfx.measurestr(last_line)
            local display_line_y = text_area_y + (last_line_num - 1) * line_h + 5
            gfx.x, gfx.y = dialog_x + 50 + text_w, display_line_y
            gfx.drawstr("|")
        end
    end
    
    -- Buttons at bottom
    local btn_y = dialog_y + dialog_h - 45
    local btn_w = 100
    local btn_h = 35
    
    -- Save button
    local save_x = dialog_x + dialog_w - btn_w - 20
    if ui_utils.mouse_in(save_x, btn_y, btn_w, btn_h) then
        gfx.set(0, 1, 0.5)
    else
        gfx.set(0, 0.7, 0.3)
    end
    gfx.rect(save_x, btn_y, btn_w, btn_h, 1)
    if ui_utils.was_clicked(ed, save_x, btn_y, btn_w, btn_h) then
        json_editor.save_json_from_editor(ed)
    end
    gfx.set(0, 0, 0)
    ui_utils.set_font(ed, 14, true)
    gfx.x, gfx.y = save_x + btn_w/2 - 18, btn_y + btn_h/2 - 8
    gfx.drawstr("SAVE")
    
    -- Close button
    local close_x = save_x - btn_w - 10
    if ui_utils.mouse_in(close_x, btn_y, btn_w, btn_h) then
        gfx.set(1, 0.4, 0.4)
    else
        gfx.set(1, 0.2, 0.2)
    end
    gfx.rect(close_x, btn_y, btn_w, btn_h, 1)
    if ui_utils.was_clicked(ed, close_x, btn_y, btn_w, btn_h) then
        json_editor.close_json_editor(ed)
    end
    gfx.set(0, 0, 0)
    ui_utils.set_font(ed, 14, true)
    gfx.x, gfx.y = close_x + btn_w/2 - 20, btn_y + btn_h/2 - 8
    gfx.drawstr("CLOSE")
    
    ed.last_mouse_cap = gfx.mouse_cap
    gfx.update()
end

return json_editor

