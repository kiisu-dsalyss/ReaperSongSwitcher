-- Setlist Editor - Dialog UI Drawing
-- Edit song, Create setlist, and other modal dialogs

local dialogs = {}

function dialogs.draw_edit_dialog(ed, ui_utils, songs_mod)
    if not ed.edit_mode then return end
    
    -- Dim background
    gfx.set(0, 0, 0)
    gfx.rect(0, 0, gfx.w, gfx.h, 1)
    gfx.set(0, 0, 0)
    gfx.rect(0, 0, gfx.w, gfx.h, 1)
    
    -- Dialog box - cyberpunk dark blue with neon cyan border
    local dialog_w = 500
    local dialog_h = 280
    local dialog_x = (gfx.w - dialog_w) / 2
    local dialog_y = (gfx.h - dialog_h) / 2
    
    gfx.set(0.08, 0.12, 0.15)  -- dark blue background
    gfx.rect(dialog_x, dialog_y, dialog_w, dialog_h, 1)
    
    gfx.set(0, 1, 1)  -- neon cyan border
    gfx.rect(dialog_x, dialog_y, dialog_w, dialog_h, 0)
    
    -- Title
    gfx.set(0, 1, 1)
    ui_utils.set_font(ed, 18, true)
    gfx.x, gfx.y = dialog_x + 20, dialog_y + 10
    gfx.drawstr("EDIT SONG #" .. ed.edit_idx)
    
    -- Name field
    local field_y = dialog_y + 50
    gfx.set(0, 1, 1)
    ui_utils.set_font(ed, 14, false)
    gfx.x, gfx.y = dialog_x + 20, field_y
    gfx.drawstr("NAME:")
    
    local name_field_h = 40
    local name_field_y = field_y + 25
    if ui_utils.mouse_in(dialog_x + 20, name_field_y, dialog_w - 40, name_field_h) then
        if ui_utils.was_clicked(ed, dialog_x + 20, name_field_y, dialog_w - 40, name_field_h) then
            ed.edit_focus = "name"
        end
    end
    
    if ed.edit_focus == "name" then
        gfx.set(0, 1, 1)
    else
        gfx.set(0.1, 0.2, 0.25)
    end
    gfx.rect(dialog_x + 20, name_field_y, dialog_w - 40, name_field_h, 1)
    
    gfx.set(0.25, 0.25, 0.25)
    gfx.rect(dialog_x + 22, name_field_y + 2, dialog_w - 44, name_field_h - 4, 1)
    
    gfx.set(1, 1, 1)
    ui_utils.set_font(ed, 16, false)
    gfx.x, gfx.y = dialog_x + 25, name_field_y + 8
    gfx.drawstr(ed.edit_name)
    
    if ed.edit_focus == "name" then
        ui_utils.set_font(ed, 16, false)
        local text_w, text_h = gfx.measurestr(ed.edit_name)
        local cursor_x = dialog_x + 25 + text_w
        gfx.set(1, 1, 1)
        if (reaper.time_precise() * 2) % 1 < 0.5 then
            gfx.rect(cursor_x, name_field_y + 8, 2, 24, 1)
        end
    end
    
    -- Path field
    local path_y = field_y + 80
    gfx.set(0, 1, 1)
    ui_utils.set_font(ed, 14, false)
    gfx.x, gfx.y = dialog_x + 20, path_y
    gfx.drawstr("PATH: (CLICK TO BROWSE)")
    
    local path_field_h = 40
    local path_field_y = path_y + 25
    local browse_btn_w = 40
    local path_input_w = dialog_w - 40 - browse_btn_w - 10
    
    if ed.edit_focus == "path" then
        gfx.set(0, 1, 1)
    else
        gfx.set(0.1, 0.2, 0.25)
    end
    gfx.rect(dialog_x + 20, path_field_y, path_input_w, path_field_h, 1)
    
    if ui_utils.mouse_in(dialog_x + 20, path_field_y, path_input_w, path_field_h) then
        if ui_utils.was_clicked(ed, dialog_x + 20, path_field_y, path_input_w, path_field_h) then
            ed.edit_focus = "path"
        end
    end
    
    gfx.set(0.25, 0.25, 0.25)
    gfx.rect(dialog_x + 22, path_field_y + 2, path_input_w - 4, path_field_h - 4, 1)
    
    gfx.set(1, 1, 1)
    ui_utils.set_font(ed, 14, false)
    gfx.x, gfx.y = dialog_x + 25, path_field_y + 8
    gfx.drawstr(ed.edit_path)
    
    if ed.edit_focus == "path" then
        ui_utils.set_font(ed, 14, false)
        local text_w, text_h = gfx.measurestr(ed.edit_path)
        local cursor_x = dialog_x + 25 + text_w
        gfx.set(1, 1, 1)
        if (reaper.time_precise() * 2) % 1 < 0.5 then
            gfx.rect(cursor_x, path_field_y + 8, 2, 24, 1)
        end
    end
    
    -- Browse button
    local browse_x = dialog_x + dialog_w - browse_btn_w - 20
    if ui_utils.mouse_in(browse_x, path_field_y, browse_btn_w, path_field_h) then
        gfx.set(0, 1, 1)
    else
        gfx.set(0.1, 0.2, 0.25)
    end
    gfx.rect(browse_x, path_field_y, browse_btn_w, path_field_h, 1)
    if ui_utils.was_clicked(ed, browse_x, path_field_y, browse_btn_w, path_field_h) then
        songs_mod.pick_file(ed)
    end
    gfx.set(0, 0, 0)
    ui_utils.set_font(ed, 12, true)
    gfx.x, gfx.y = browse_x + 4, path_field_y + 12
    gfx.drawstr("...")
    
    -- Buttons at bottom
    local ok_x = dialog_x + 20
    local ok_y = dialog_y + dialog_h - 45
    local ok_w = (dialog_w - 60) / 2
    
    if ui_utils.mouse_in(ok_x, ok_y, ok_w, 35) then
        gfx.set(1, 0.2, 1)
    else
        gfx.set(1, 0, 1)
    end
    gfx.rect(ok_x, ok_y, ok_w, 35, 1)
    if ui_utils.was_clicked(ed, ok_x, ok_y, ok_w, 35) then
        songs_mod.finish_edit(ed)
    end
    gfx.set(0, 0, 0)
    ui_utils.set_font(ed, 16, true)
    gfx.x, gfx.y = ok_x + ok_w/2 - 18, ok_y + 35/2 - 8
    gfx.drawstr("SAVE")
    
    -- Cancel button
    local cancel_x = ok_x + ok_w + 20
    if ui_utils.mouse_in(cancel_x, ok_y, ok_w, 35) then
        gfx.set(1, 0.4, 0.4)
    else
        gfx.set(1, 0.2, 0.2)
    end
    gfx.rect(cancel_x, ok_y, ok_w, 35, 1)
    if ui_utils.was_clicked(ed, cancel_x, ok_y, ok_w, 35) then
        songs_mod.cancel_edit(ed)
    end
    gfx.set(0, 0, 0)
    ui_utils.set_font(ed, 16, true)
    gfx.x, gfx.y = cancel_x + ok_w/2 - 26, ok_y + 35/2 - 8
    gfx.drawstr("CANCEL")
    
    ed.last_mouse_cap = gfx.mouse_cap
    gfx.update()
end

function dialogs.draw_create_dialog(ed, ui_utils, io_mod)
    if not ed.create_dialog_open then return end
    
    -- Dim background
    gfx.set(0, 0, 0)
    gfx.rect(0, 0, gfx.w, gfx.h, 1)
    gfx.set(0, 0, 0)
    gfx.rect(0, 0, gfx.w, gfx.h, 1)
    
    -- Dialog box
    local dialog_w = 500
    local dialog_h = 250
    local dialog_x = (gfx.w - dialog_w) / 2
    local dialog_y = (gfx.h - dialog_h) / 2
    
    gfx.set(0.08, 0.12, 0.15)
    gfx.rect(dialog_x, dialog_y, dialog_w, dialog_h, 1)
    
    gfx.set(1, 0.6, 0)  -- neon orange border
    gfx.rect(dialog_x, dialog_y, dialog_w, dialog_h, 0)
    
    -- Title
    gfx.set(1, 0.6, 0)
    ui_utils.set_font(ed, 18, true)
    gfx.x, gfx.y = dialog_x + 20, dialog_y + 10
    gfx.drawstr("CREATE NEW SETLIST")
    
    -- Name field
    local field_y = dialog_y + 50
    gfx.set(1, 0.6, 0)
    ui_utils.set_font(ed, 14, false)
    gfx.x, gfx.y = dialog_x + 20, field_y
    gfx.drawstr("SETLIST NAME:")
    
    local name_field_h = 35
    local name_field_y = field_y + 22
    if ui_utils.mouse_in(dialog_x + 20, name_field_y, dialog_w - 40, name_field_h) then
        if ui_utils.was_clicked(ed, dialog_x + 20, name_field_y, dialog_w - 40, name_field_h) then
            ed.create_focus = "name"
        end
    end
    
    if (ed.create_focus or "") == "name" then
        gfx.set(1, 0.6, 0)
    else
        gfx.set(0.1, 0.2, 0.25)
    end
    gfx.rect(dialog_x + 20, name_field_y, dialog_w - 40, name_field_h, 1)
    
    gfx.set(0.25, 0.25, 0.25)
    gfx.rect(dialog_x + 22, name_field_y + 2, dialog_w - 44, name_field_h - 4, 1)
    
    gfx.set(1, 1, 1)
    ui_utils.set_font(ed, 14, false)
    gfx.x, gfx.y = dialog_x + 25, name_field_y + 8
    gfx.drawstr(ed.new_setlist_name)
    
    if (ed.create_focus or "") == "name" then
        ui_utils.set_font(ed, 14, false)
        local text_w, text_h = gfx.measurestr(ed.new_setlist_name)
        local cursor_x = dialog_x + 25 + text_w
        gfx.set(1, 1, 1)
        if (reaper.time_precise() * 2) % 1 < 0.5 then
            gfx.rect(cursor_x, name_field_y + 5, 2, 24, 1)
        end
    end
    
    -- Path field
    local path_y = field_y + 70
    gfx.set(1, 0.6, 0)
    ui_utils.set_font(ed, 14, false)
    gfx.x, gfx.y = dialog_x + 20, path_y
    gfx.drawstr("BASE PATH:")
    
    local path_field_h = 35
    local path_field_y = path_y + 22
    
    if ui_utils.mouse_in(dialog_x + 20, path_field_y, dialog_w - 40, path_field_h) then
        if ui_utils.was_clicked(ed, dialog_x + 20, path_field_y, dialog_w - 40, path_field_h) then
            ed.create_focus = "path"
        end
    end
    
    if (ed.create_focus or "") == "path" then
        gfx.set(1, 0.6, 0)
    else
        gfx.set(0.1, 0.2, 0.25)
    end
    gfx.rect(dialog_x + 20, path_field_y, dialog_w - 40, path_field_h, 1)
    
    gfx.set(0.25, 0.25, 0.25)
    gfx.rect(dialog_x + 22, path_field_y + 2, dialog_w - 44, path_field_h - 4, 1)
    
    gfx.set(0.8, 0.8, 0.8)
    ui_utils.set_font(ed, 12, false)
    gfx.x, gfx.y = dialog_x + 25, path_field_y + 8
    gfx.drawstr(ed.new_setlist_path ~= "" and ui_utils.truncate_text(ed.new_setlist_path, dialog_w - 90) or "(type or paste path)")
    
    if (ed.create_focus or "") == "path" then
        ui_utils.set_font(ed, 12, false)
        local text_w, text_h = gfx.measurestr(ed.new_setlist_path)
        local cursor_x = dialog_x + 25 + text_w
        gfx.set(1, 1, 1)
        if (reaper.time_precise() * 2) % 1 < 0.5 then
            gfx.rect(cursor_x, path_field_y + 5, 2, 24, 1)
        end
    end
    
    -- Buttons at bottom
    local btn_x = dialog_x + 20
    local btn_y = dialog_y + dialog_h - 45
    local btn_w = (dialog_w - 60) / 2
    
    if ui_utils.mouse_in(btn_x, btn_y, btn_w, 35) then
        gfx.set(1, 0.8, 0.3)
    else
        gfx.set(1, 0.6, 0)
    end
    gfx.rect(btn_x, btn_y, btn_w, 35, 1)
    if ui_utils.was_clicked(ed, btn_x, btn_y, btn_w, 35) then
        io_mod.finish_create(ed)
    end
    gfx.set(0, 0, 0)
    ui_utils.set_font(ed, 16, true)
    gfx.x, gfx.y = btn_x + btn_w/2 - 28, btn_y + 35/2 - 8
    gfx.drawstr("CREATE")
    
    local cancel_x = btn_x + btn_w + 20
    if ui_utils.mouse_in(cancel_x, btn_y, btn_w, 35) then
        gfx.set(1, 0.4, 0.4)
    else
        gfx.set(1, 0.2, 0.2)
    end
    gfx.rect(cancel_x, btn_y, btn_w, 35, 1)
    if ui_utils.was_clicked(ed, cancel_x, btn_y, btn_w, 35) then
        io_mod.close_create_dialog(ed)
    end
    gfx.set(0, 0, 0)
    ui_utils.set_font(ed, 16, true)
    gfx.x, gfx.y = cancel_x + btn_w/2 - 26, btn_y + 35/2 - 8
    gfx.drawstr("CANCEL")
    
    ed.last_mouse_cap = gfx.mouse_cap
    gfx.update()
end

return dialogs
