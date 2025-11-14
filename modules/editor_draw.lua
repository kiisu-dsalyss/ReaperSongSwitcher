-- Setlist Editor - UI Drawing
-- All gfx drawing functions for main UI and dialogs

local ui_draw = {}

function ui_draw.draw_ui(ed, ui_utils, songs_mod, io_mod, json_editor_mod)
    -- Initialize gfx window if needed
    ui_utils.init_gfx()
    
    -- Background - cyberpunk dark with slight blue tint
    gfx.set(0.08, 0.12, 0.15)  -- dark blue-black
    gfx.rect(0, 0, gfx.w, gfx.h, 1)
    
    -- Add subtle scanline effect
    gfx.set(0, 0, 0)
    gfx.set(0, 0, 0, 0.02)  -- very subtle lines
    for line_y = 0, gfx.h, 2 do
        gfx.line(0, line_y, gfx.w, line_y)
    end
    
    local x, y = 10, 10
    local w = gfx.w - 20
    
    -- Title - neon cyan
    gfx.set(0, 1, 1)  -- cyan neon
    ui_utils.set_font(ed, 32, true)
    gfx.x, gfx.y = x, y
    gfx.drawstr("SETLIST EDITOR")
    
    -- Top right buttons: JSON, Load, Create, Save
    local top_button_h = 35
    local top_button_w = 85
    local top_button_y = y + 2
    local save_x = gfx.w - top_button_w - 10
    local create_x = save_x - top_button_w - 5
    local load_x = create_x - top_button_w - 5
    local json_x = load_x - top_button_w - 5
    
    -- JSON button - neon green
    gfx.set(0, 1, 0.5)
    gfx.rect(json_x, top_button_y, top_button_w, top_button_h, 1)
    if ui_utils.mouse_in(json_x, top_button_y, top_button_w, top_button_h) then
        gfx.set(0.5, 1, 0.8)  -- lighter green on hover
        gfx.rect(json_x, top_button_y, top_button_w, top_button_h, 1)
    end
    if ui_utils.was_clicked(ed, json_x, top_button_y, top_button_w, top_button_h) then
        json_editor_mod.open_json_editor(ed)
        json_editor_mod.load_json_to_editor(ed)
    end
    gfx.set(0, 0, 0)  -- black text
    ui_utils.set_font(ed, 14, true)
    gfx.x, gfx.y = json_x + top_button_w/2 - 20, top_button_y + top_button_h/2 - 8
    gfx.drawstr("JSON")
    
    -- Load button - neon green
    gfx.set(0, 1, 0.5)
    gfx.rect(load_x, top_button_y, top_button_w, top_button_h, 1)
    if ui_utils.mouse_in(load_x, top_button_y, top_button_w, top_button_h) then
        gfx.set(0.5, 1, 0.8)  -- lighter green on hover
        gfx.rect(load_x, top_button_y, top_button_w, top_button_h, 1)
    end
    if ui_utils.was_clicked(ed, load_x, top_button_y, top_button_w, top_button_h) then
        io_mod.open_load_dialog(ed)
    end
    gfx.set(0, 0, 0)  -- black text
    ui_utils.set_font(ed, 14, true)
    gfx.x, gfx.y = load_x + top_button_w/2 - 24, top_button_y + top_button_h/2 - 8
    gfx.drawstr("LOAD")
    
    -- Create button - neon orange
    gfx.set(1, 0.6, 0)
    gfx.rect(create_x, top_button_y, top_button_w, top_button_h, 1)
    if ui_utils.mouse_in(create_x, top_button_y, top_button_w, top_button_h) then
        gfx.set(1, 0.8, 0.3)  -- lighter orange on hover
        gfx.rect(create_x, top_button_y, top_button_w, top_button_h, 1)
    end
    if ui_utils.was_clicked(ed, create_x, top_button_y, top_button_w, top_button_h) then
        io_mod.open_create_dialog(ed)
    end
    gfx.set(0, 0, 0)  -- black text
    ui_utils.set_font(ed, 14, true)
    gfx.x, gfx.y = create_x + top_button_w/2 - 30, top_button_y + top_button_h/2 - 8
    gfx.drawstr("CREATE")
    
    -- Save button - neon magenta
    gfx.set(1, 0, 1)  -- bright magenta
    gfx.rect(save_x, top_button_y, top_button_w, top_button_h, 1)
    if ui_utils.mouse_in(save_x, top_button_y, top_button_w, top_button_h) then
        gfx.set(1, 0.5, 1)  -- lighter magenta on hover
        gfx.rect(save_x, top_button_y, top_button_w, top_button_h, 1)
    end
    if ui_utils.was_clicked(ed, save_x, top_button_y, top_button_w, top_button_h) then
        io_mod.save_json(ed)
    end
    gfx.set(0, 0, 0)  -- black text
    ui_utils.set_font(ed, 14, true)
    gfx.x, gfx.y = save_x + top_button_w/2 - 16, top_button_y + top_button_h/2 - 8
    gfx.drawstr("SAVE")
    
    -- Dirty indicator - neon yellow at bottom right
    if ed.dirty then
        gfx.set(1, 1, 0)  -- neon yellow
        ui_utils.set_font(ed, 12, true)
        gfx.x, gfx.y = gfx.w - 150, gfx.h - 25
        gfx.drawstr("● UNSAVED")
    end
    
    y = y + 45
    
    -- Base path editor - neon cyan labels
    ui_utils.set_font(ed, 14, false)
    gfx.set(0, 1, 1)  -- cyan
    gfx.x, gfx.y = x, y
    gfx.drawstr("BASE PATH:")
    y = y + 22
    
    gfx.set(0.1, 0.2, 0.25)  -- dark blue
    gfx.rect(x, y, w, 32, 1)
    gfx.set(1, 1, 1)
    ui_utils.set_font(ed, 13, false)
    gfx.x, gfx.y = x + 5, y + 6
    gfx.drawstr(ed.base_path)
    y = y + 40
    
    -- Songs list header - neon cyan
    gfx.set(0, 1, 1)  -- cyan
    ui_utils.set_font(ed, 14, false)
    gfx.x, gfx.y = x, y
    gfx.drawstr("SONGS (" .. #ed.songs .. "):")
    y = y + 28
    
    -- Song list
    local song_y = y
    local song_h = 50
    local max_visible = math.floor((gfx.h - song_y - 70) / song_h)
    
    for i = 1, #ed.songs do
        if i <= max_visible then
            local is_selected = (i == ed.selected_idx)
            local is_hovered = ui_utils.mouse_in(x, song_y, w, song_h)
            local is_dragged = (i == ed.drag_idx and ed.drag_active)
            
            -- Background with alternating stripes and cyberpunk colors
            if is_dragged then
                gfx.set(1, 1, 0)  -- neon yellow when dragging
            elseif is_selected then
                gfx.set(0, 1, 1)  -- cyan when selected
            elseif is_hovered then
                gfx.set(1, 0, 1)  -- magenta when hovered
            else
                -- Alternating row colors
                if i % 2 == 0 then
                    gfx.set(0.08, 0.15, 0.2)  -- dark blue
                else
                    gfx.set(0.1, 0.18, 0.25)  -- slightly lighter blue
                end
            end
            gfx.rect(x, song_y, w, song_h, 1)
            
            -- Song info
            gfx.set(1, 1, 1)
            ui_utils.set_font(ed, 18, true)
            gfx.x, gfx.y = x + 5, song_y + 2
            gfx.drawstr(i .. ". " .. ed.songs[i].name)
            gfx.x, gfx.y = x + 5, song_y + 25
            gfx.set(0.7, 0.7, 0.7)
            ui_utils.set_font(ed, 14, false)
            gfx.drawstr(ed.songs[i].path)
            
            -- Click to select
            if ui_utils.was_clicked(ed, x, song_y, w, song_h) then
                local current_time = reaper.time_precise()
                if ed.last_click_idx == i and (current_time - ed.last_click_time) < 0.3 then
                    -- Double-click! Open edit dialog
                    songs_mod.start_edit(ed, i)
                    ed.log("Double-clicked song " .. i .. ", opening edit dialog")
                else
                    -- Single click
                    ed.selected_idx = i
                    ed.last_click_idx = i
                    ed.last_click_time = current_time
                    ed.log("Selected song " .. i)
                end
            end
            
            -- Handle drag start
            local is_pressed = (gfx.mouse_cap & 1) > 0
            local was_pressed = (ed.last_mouse_cap & 1) > 0
            if is_hovered and is_pressed and not was_pressed then
                ed.drag_idx = i
                ed.drag_active = true
                ed.drag_y_start = gfx.mouse_y
            end
            
            song_y = song_y + song_h
        end
    end
    
    -- Handle drag end and reordering
    local is_pressed = (gfx.mouse_cap & 1) > 0
    if ed.drag_active and not is_pressed then
        local drop_y = gfx.mouse_y
        local song_y_base = y
        local song_h = 50
        
        local drop_idx = math.floor((drop_y - song_y_base) / song_h) + 1
        
        if drop_idx >= 1 and drop_idx <= #ed.songs and drop_idx ~= ed.drag_idx then
            songs_mod.swap_songs(ed, ed.drag_idx, drop_idx)
        end
        
        ed.drag_active = false
        ed.drag_idx = 0
    end
    
    -- Buttons at bottom
    local button_y = gfx.h - 115
    local button_w = (w - 20) / 3
    local bh = 40
    
    -- Add button - neon cyan
    gfx.set(0, 1, 1)
    gfx.rect(x, button_y, button_w, bh, 1)
    if ui_utils.mouse_in(x, button_y, button_w, bh) then
        gfx.set(0.5, 1, 1)  -- lighter cyan on hover
        gfx.rect(x, button_y, button_w, bh, 1)
    end
    if ui_utils.was_clicked(ed, x, button_y, button_w, bh) then
        songs_mod.add_song(ed)
    end
    gfx.set(0, 0, 0)  -- black text
    ui_utils.set_font(ed, 16, true)
    gfx.x, gfx.y = x + button_w/2 - 20, button_y + bh/2 - 8
    gfx.drawstr("+ ADD")
    
    -- Edit button - neon magenta
    local edit_x = x + button_w + 10
    gfx.set(1, 0, 1)
    gfx.rect(edit_x, button_y, button_w, bh, 1)
    if ui_utils.mouse_in(edit_x, button_y, button_w, bh) then
        gfx.set(0.4, 0.5, 0.6)
        gfx.rect(edit_x, button_y, button_w, bh, 1)
    end
    if ui_utils.was_clicked(ed, edit_x, button_y, button_w, bh) then
        if ed.selected_idx > 0 then
            songs_mod.start_edit(ed, ed.selected_idx)
        end
    end
    gfx.set(0, 0, 0)  -- black text
    ui_utils.set_font(ed, 16, true)
    gfx.x, gfx.y = edit_x + button_w/2 - 18, button_y + bh/2 - 8
    gfx.drawstr("EDIT")
    
    -- Delete button - neon red
    local del_x = edit_x + button_w + 10
    gfx.set(1, 0.2, 0.2)  -- neon red
    gfx.rect(del_x, button_y, button_w, bh, 1)
    if ui_utils.mouse_in(del_x, button_y, button_w, bh) then
        gfx.set(1, 0.5, 0.5)  -- lighter red on hover
        gfx.rect(del_x, button_y, button_w, bh, 1)
    end
    if ui_utils.was_clicked(ed, del_x, button_y, button_w, bh) then
        if ed.selected_idx > 0 then
            songs_mod.delete_song(ed, ed.selected_idx)
        end
    end
    gfx.set(0, 0, 0)  -- black text
    ui_utils.set_font(ed, 16, true)
    gfx.x, gfx.y = del_x + button_w/2 - 26, button_y + bh/2 - 8
    gfx.drawstr("DELETE")
    
    -- CRITICAL: Track mouse state for next frame's click detection
    ed.last_mouse_cap = gfx.mouse_cap
    
    gfx.update()
end

return ui_draw
