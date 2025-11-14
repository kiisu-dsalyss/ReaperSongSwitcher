-- UI Module - Config menu with tabs (Font picker, Background image), dialogs, main UI rendering

local ui = {}

-- Initialize config menu state
function ui.init_config_menu(ss)
    ss.config_menu_tab = ss.config_menu_tab or "font"  -- "font" or "background"
    ss.font_search = ss.font_search or ""
    ss.font_picker_scroll = ss.font_picker_scroll or 0
    ss.font_picker_dragging = ss.font_picker_dragging or false
    ss.font_picker_drag_offset = ss.font_picker_drag_offset or 0
end

-- Config menu with tabs
function ui.draw_config_menu(ss, fonts_module, utils, image_loader)
    -- Capture font_size_multiplier at function start with defensive fallback
    local font_size_multiplier = ss.font_size_multiplier or 1.0
    
    local w = gfx.w
    local h = gfx.h
    local dialog_w = 500
    local dialog_h = 700
    local dialog_x = (w - dialog_w) / 2
    local dialog_y = (h - dialog_h) / 2
    
    dialog_w = math.min(dialog_w, math.max(300, w - 40))
    dialog_h = math.min(dialog_h, math.max(250, h - 40))
    
    gfx.set(0, 0, 0, 0.7)
    gfx.rect(0, 0, w, h, true)
    
    gfx.set(0.08, 0.15, 0.2)
    gfx.rect(dialog_x, dialog_y, dialog_w, dialog_h, true)
    gfx.set(0, 1, 1)
    gfx.rect(dialog_x, dialog_y, dialog_w, dialog_h, false)
    
    -- Tab buttons
    local tab_y = dialog_y + 15
    local tab_h = 28
    local tab1_x = dialog_x + 15
    local tab1_w = (dialog_w - 45) / 2
    local tab2_x = tab1_x + tab1_w + 15
    local tab2_w = tab1_w
    
    -- Font tab
    if ss.config_menu_tab == "font" then
        gfx.set(0, 1, 1)
    else
        gfx.set(0.3, 0.6, 0.7)
    end
    gfx.rect(tab1_x, tab_y, tab1_w, tab_h, true)
    gfx.set(0, 0.8, 0.9)
    gfx.rect(tab1_x, tab_y, tab1_w, tab_h, false)
    gfx.set(1, 1, 1)
    ss.set_font(12, true)
    gfx.x, gfx.y = tab1_x + 15, tab_y + 6
    gfx.drawstr("FONT")
    
    if utils.was_clicked(gfx, tab1_x, tab_y, tab1_w, tab_h, ss.ui.last_mouse_cap) then
        ss.config_menu_tab = "font"
    end
    
    -- Background tab
    if ss.config_menu_tab == "background" then
        gfx.set(0, 1, 1)
    else
        gfx.set(0.3, 0.6, 0.7)
    end
    gfx.rect(tab2_x, tab_y, tab2_w, tab_h, true)
    gfx.set(0, 0.8, 0.9)
    gfx.rect(tab2_x, tab_y, tab2_w, tab_h, false)
    gfx.set(1, 1, 1)
    ss.set_font(12, true)
    gfx.x, gfx.y = tab2_x + 10, tab_y + 6
    gfx.drawstr("BACKGROUND")
    
    if utils.was_clicked(gfx, tab2_x, tab_y, tab2_w, tab_h, ss.ui.last_mouse_cap) then
        ss.config_menu_tab = "background"
    end
    
    local content_y = tab_y + tab_h + 15
    local content_h = dialog_h - 100 - (content_y - dialog_y)
    
    if ss.config_menu_tab == "font" then
        ui.draw_font_config(ss, fonts_module, utils, dialog_x, content_y, dialog_w, content_h, font_size_multiplier)
    else
        ui.draw_background_config(ss, utils, image_loader, dialog_x, content_y, dialog_w, content_h)
    end
    
    -- Close button
    local close_y = dialog_y + dialog_h - 35
    gfx.set(1, 0.2, 0.2)
    gfx.rect(dialog_x + 20, close_y, dialog_w - 40, 30, true)
    gfx.set(1, 1, 1)
    ss.set_font(12, true)
    gfx.x, gfx.y = dialog_x + dialog_w/2 - 20, close_y + 8
    gfx.drawstr("CLOSE")
    
    if utils.was_clicked(gfx, dialog_x + 20, close_y, dialog_w - 40, 30, ss.ui.last_mouse_cap) then
        ss.show_config_menu = false
    end
end

-- Font configuration tab
function ui.draw_font_config(ss, fonts_module, utils, dialog_x, content_y, dialog_w, content_h, font_size_multiplier)
    local search_y = content_y
    gfx.set(0.1, 0.2, 0.3)
    gfx.rect(dialog_x + 10, search_y, dialog_w - 20, 28, true)
    gfx.set(0, 1, 1)
    gfx.rect(dialog_x + 10, search_y, dialog_w - 20, 28, false)
    
    gfx.set(0.7, 0.7, 0.7)
    ss.set_font(12, false)
    gfx.x, gfx.y = dialog_x + 20, search_y + 6
    gfx.drawstr("Search: " .. ss.font_search .. (math.floor(reaper.time_precise() * 2) % 2 == 0 and "_" or ""))
    
    local filtered_fonts = {}
    local search_lower = ss.font_search:lower()
    for i, font_name in ipairs(ss.available_fonts) do
        if search_lower == "" or font_name:lower():find(search_lower, 1, true) then
            table.insert(filtered_fonts, font_name)
        end
    end
    
    local list_y = search_y + 40
    local list_h = content_h - 60
    local item_h = math.max(18, math.floor(24 * font_size_multiplier))
    local max_visible = math.max(1, math.floor(list_h / item_h))
    local scrollbar_w = 12
    local list_w = dialog_w - 20 - scrollbar_w - 5
    
    local scroll_delta = gfx.mouse_wheel
    if scroll_delta ~= 0 then
        local step = 3
        local max_scroll_wheel = math.max(0, #filtered_fonts - max_visible)
        ss.font_picker_scroll = math.max(0, math.min(ss.font_picker_scroll - scroll_delta * step, max_scroll_wheel))
        gfx.mouse_wheel = 0
    end
    
    for i = 1, #filtered_fonts do
        local visible_idx = i - ss.font_picker_scroll
        if visible_idx < 1 or visible_idx > max_visible then
            goto continue_fonts
        end
        
        local font_name = filtered_fonts[i]
        local y = list_y + (visible_idx - 1) * item_h
        local is_current = (font_name == ss.current_font)
        
        if is_current then
            gfx.set(0, 0.8, 0.8)
        elseif utils.mouse_in(gfx, dialog_x + 10, y, list_w, item_h) then
            gfx.set(0.2, 0.4, 0.5)
        else
            if i % 2 == 0 then
                gfx.set(0.08, 0.15, 0.2)
            else
                gfx.set(0.12, 0.19, 0.26)
            end
        end
        gfx.rect(dialog_x + 10, y, list_w, item_h, true)
        
        gfx.set(1, 1, 1)
        ss.set_font(13, false)
        gfx.x, gfx.y = dialog_x + 20, y + 3
        local display_name = font_name
        if #font_name > 50 then
            display_name = font_name:sub(1, 47) .. "..."
        end
        gfx.drawstr(display_name)
        
        if utils.was_clicked(gfx, dialog_x + 10, y, list_w, item_h, ss.ui.last_mouse_cap) then
            ss.save_config(font_name, ss.font_size_multiplier, ss.background_image_path or "")
            ss.show_config_menu = false
            ss.font_search = ""
        end
        
        ::continue_fonts::
    end
    
    if #filtered_fonts > max_visible then
        local scrollbar_x = dialog_x + dialog_w - scrollbar_w - 10
        local scrollbar_h = list_h
        local max_scroll = math.max(0, #filtered_fonts - max_visible)
        
        local scroll_ratio = 0
        if max_scroll > 0 then
            scroll_ratio = ss.font_picker_scroll / max_scroll
        end
        
        local thumb_h = math.max(20, scrollbar_h * (max_visible / #filtered_fonts))
        local thumb_y = list_y + (scroll_ratio * math.max(0, (scrollbar_h - thumb_h)))
        
        gfx.set(0.05, 0.1, 0.15)
        gfx.rect(scrollbar_x, list_y, scrollbar_w, scrollbar_h, true)
        
        gfx.set(0, 0.6, 0.6)
        gfx.rect(scrollbar_x, thumb_y, scrollbar_w, thumb_h, true)
        
        if utils.was_clicked(gfx, scrollbar_x, list_y, scrollbar_w, scrollbar_h, ss.ui.last_mouse_cap) then
            local mx, my = gfx.mouse_x, gfx.mouse_y
            local rel = 0
            if scrollbar_h - thumb_h > 0 then
                rel = (my - list_y) / (scrollbar_h - thumb_h)
            end
            rel = math.max(0, math.min(1, rel))
            ss.font_picker_scroll = math.floor(rel * max_scroll + 0.5)
        end
        
        if (gfx.mouse_cap & 1) == 1 and utils.mouse_in(gfx, scrollbar_x, thumb_y, scrollbar_w, thumb_h) and not ss.font_picker_dragging then
            ss.font_picker_dragging = true
            ss.font_picker_drag_offset = gfx.mouse_y - thumb_y
        end
        if ss.font_picker_dragging then
            if (gfx.mouse_cap & 1) == 0 then
                ss.font_picker_dragging = false
            else
                local my = gfx.mouse_y
                local new_thumb_y = my - ss.font_picker_drag_offset
                new_thumb_y = math.max(list_y, math.min(list_y + scrollbar_h - thumb_h, new_thumb_y))
                local rel = 0
                if scrollbar_h - thumb_h > 0 then
                    rel = (new_thumb_y - list_y) / (scrollbar_h - thumb_h)
                end
                ss.font_picker_scroll = math.floor(rel * max_scroll + 0.5)
            end
        end
    end
    
    local controls_y = list_y + list_h + 8
    local btn_w = 50
    local btn_h = 28
    local minus_x = dialog_x + 20
    local plus_x = dialog_x + dialog_w - btn_w - 20
    local label_x = dialog_x + dialog_w / 2 - 30
    
    gfx.set(0.08, 0.15, 0.2)
    gfx.rect(minus_x, controls_y, btn_w, btn_h, true)
    
    if utils.mouse_in(gfx, minus_x, controls_y, btn_w, btn_h) then
        gfx.set(1, 0.5, 1)
    else
        gfx.set(0.3, 0.8, 0.8)
    end
    gfx.rect(minus_x, controls_y, btn_w, btn_h, false)
    
    gfx.set(0.3, 0.8, 0.8)
    ss.set_font(16, true)
    gfx.x, gfx.y = minus_x + 14, controls_y + 4
    gfx.drawstr("-")
    
    if utils.was_clicked(gfx, minus_x, controls_y, btn_w, btn_h, ss.ui.last_mouse_cap) then
        local current_mult = ss.font_size_multiplier or 1.0
        ss.font_size_multiplier = math.max(0.7, current_mult - 0.1)
        ss.save_config(ss.current_font, ss.font_size_multiplier, ss.background_image_path or "")
    end
    
    gfx.set(0.08, 0.15, 0.2)
    gfx.rect(plus_x, controls_y, btn_w, btn_h, true)
    
    if utils.mouse_in(gfx, plus_x, controls_y, btn_w, btn_h) then
        gfx.set(1, 0.5, 1)
    else
        gfx.set(0.3, 0.8, 0.8)
    end
    gfx.rect(plus_x, controls_y, btn_w, btn_h, false)
    
    gfx.set(0.3, 0.8, 0.8)
    ss.set_font(16, true)
    gfx.x, gfx.y = plus_x + 12, controls_y + 2
    gfx.drawstr("+")
    
    if utils.was_clicked(gfx, plus_x, controls_y, btn_w, btn_h, ss.ui.last_mouse_cap) then
        local current_mult = ss.font_size_multiplier or 1.0
        ss.font_size_multiplier = math.min(1.5, current_mult + 0.1)
        ss.save_config(ss.current_font, ss.font_size_multiplier, ss.background_image_path or "")
    end
    
    gfx.set(0.7, 0.7, 0.7)
    ss.set_font(12, false)
    gfx.x, gfx.y = label_x, controls_y + 7
    gfx.drawstr(string.format("%.0f%%", font_size_multiplier * 100))
end

-- Background image configuration tab
function ui.draw_background_config(ss, utils, image_loader, dialog_x, content_y, dialog_w, content_h)
    local list_y = content_y
    local list_h = content_h - 50
    
    gfx.set(0.7, 0.7, 0.7)
    ss.set_font(12, false)
    gfx.x, gfx.y = dialog_x + 20, list_y
    gfx.drawstr("Background Image:")
    
    -- Draw preview box
    local preview_y = list_y + 25
    local preview_h = 60
    gfx.set(0.05, 0.08, 0.1)
    gfx.rect(dialog_x + 20, preview_y, dialog_w - 40, preview_h, true)
    gfx.set(0.3, 0.5, 0.6)
    gfx.rect(dialog_x + 20, preview_y, dialog_w - 40, preview_h, false)
    
    if ss.background_image_path and ss.background_image_path ~= "" then
        gfx.set(0, 1, 0.5)
        ss.set_font(10, false)
        gfx.x, gfx.y = dialog_x + 30, preview_y + 10
        gfx.drawstr("✓ Image Loaded")
        
        ss.set_font(9, false)
        gfx.x, gfx.y = dialog_x + 30, preview_y + 25
        local display_path = ss.background_image_path
        if #display_path > 55 then
            display_path = "..." .. display_path:sub(-52)
        end
        gfx.drawstr(display_path)
        
        gfx.x, gfx.y = dialog_x + 30, preview_y + 40
        gfx.drawstr("(Visible on main UI)")
    else
        gfx.set(0.5, 0.5, 0.5)
        ss.set_font(10, false)
        gfx.x, gfx.y = dialog_x + 30, preview_y + 25
        gfx.drawstr("No background image selected")
    end
    
    -- Browse button
    local btn_y = list_y + 95
    local btn_w = 100
    local btn_h = 28
    local btn_x = dialog_x + 20
    
    gfx.set(0.08, 0.15, 0.2)
    gfx.rect(btn_x, btn_y, btn_w, btn_h, true)
    
    if utils.mouse_in(gfx, btn_x, btn_y, btn_w, btn_h) then
        gfx.set(0, 1, 1)
    else
        gfx.set(0, 0.8, 0.9)
    end
    gfx.rect(btn_x, btn_y, btn_w, btn_h, false)
    
    gfx.set(0, 0.8, 0.9)
    ss.set_font(12, true)
    gfx.x, gfx.y = btn_x + 8, btn_y + 6
    gfx.drawstr("BROWSE")
    
    if utils.was_clicked(gfx, btn_x, btn_y, btn_w, btn_h, ss.ui.last_mouse_cap) then
        -- File picker for PNG images
        local file_path = reaper.GetExtState("filedlg", "filterdir") or ss.script_dir
        local retval, filename = reaper.GetUserFileNameForRead(file_path, "Select PNG Image", "*.png")
        if retval and filename ~= "" then
            ss.background_image_path = filename
            ss.background_image = image_loader.load_png(filename, ss.log_transport)
            ss.save_config(ss.current_font, ss.font_size_multiplier, filename)
            ss.log_transport("Selected background image: " .. filename)
        end
    end
    
    -- Clear button
    local clear_x = btn_x + btn_w + 15
    gfx.set(0.08, 0.15, 0.2)
    gfx.rect(clear_x, btn_y, btn_w, btn_h, true)
    
    if utils.mouse_in(gfx, clear_x, btn_y, btn_w, btn_h) then
        gfx.set(1, 0.3, 0.3)
    else
        gfx.set(1, 0.1, 0.1)
    end
    gfx.rect(clear_x, btn_y, btn_w, btn_h, false)
    
    gfx.set(1, 0.1, 0.1)
    ss.set_font(12, true)
    gfx.x, gfx.y = clear_x + 12, btn_y + 6
    gfx.drawstr("CLEAR")
    
    if utils.was_clicked(gfx, clear_x, btn_y, btn_w, btn_h, ss.ui.last_mouse_cap) then
        ss.background_image_path = ""
        ss.background_image = nil
        ss.save_config(ss.current_font, ss.font_size_multiplier, "")
        ss.log_transport("Cleared background image")
    end
    
    gfx.set(0.5, 0.5, 0.5)
    ss.set_font(10, false)
    gfx.x, gfx.y = dialog_x + 20, btn_y + btn_h + 15
    gfx.drawstr("PNG files will be centered and not tiled.")
end

-- Font picker dialog (OLD - kept for compatibility)
function ui.draw_font_picker(ss, fonts_module, utils)
    ui.draw_config_menu(ss, fonts_module, utils, nil)
end

-- Load setlist dialog
function ui.draw_load_setlist_dialog(ss, setlist_module, utils)
    -- Capture font_size_multiplier at function start with defensive fallback
    local font_size_multiplier = ss.font_size_multiplier or 1.0
    
    local w = gfx.w
    local h = gfx.h
    local dialog_w = 500
    local dialog_h = 400
    local dialog_x = (w - dialog_w) / 2
    local dialog_y = (h - dialog_h) / 2
    
    dialog_w = math.min(dialog_w, math.max(200, w - 40))
    dialog_h = math.min(dialog_h, math.max(150, h - 40))
    
    gfx.set(0, 0, 0, 0.7)
    gfx.rect(0, 0, w, h, true)
    
    gfx.set(0.08, 0.15, 0.2)
    gfx.rect(dialog_x, dialog_y, dialog_w, dialog_h, true)
    gfx.set(0, 1, 1)
    gfx.rect(dialog_x, dialog_y, dialog_w, dialog_h, false)
    
    gfx.set(0, 1, 1)
    ss.set_font(16, true)
    gfx.x, gfx.y = dialog_x + 20, dialog_y + 15
    gfx.drawstr("LOAD SETLIST")
    
    gfx.set(0.7, 0.7, 0.7)
    ss.set_font(12, false)
    gfx.x, gfx.y = dialog_x + 20, dialog_y + 45
    gfx.drawstr("Enter setlist filename (in Scripts folder):")
    
    gfx.set(0.1, 0.2, 0.3)
    gfx.rect(dialog_x + 20, dialog_y + 75, dialog_w - 40, 30, true)
    gfx.set(0, 1, 1)
    gfx.rect(dialog_x + 20, dialog_y + 75, dialog_w - 40, 30, false)
    
    gfx.set(0.7, 0.7, 0.7)
    ss.set_font(12, false)
    gfx.x, gfx.y = dialog_x + 30, dialog_y + 82
    gfx.drawstr(ss.setlist_load_input .. (math.floor(reaper.time_precise() * 2) % 2 == 0 and "_" or ""))
    
    gfx.set(0.5, 0.7, 0.8)
    ss.set_font(10, false)
    gfx.x, gfx.y = dialog_x + 20, dialog_y + 115
    gfx.drawstr("(e.g., 'setlist.json' or 'my_songs.json')")
    
    gfx.x, gfx.y = dialog_x + 20, dialog_y + 130
    gfx.drawstr("Files should be in the Scripts/ReaperSongSwitcher folder")
    
    gfx.set(0.08, 0.15, 0.2)
    gfx.rect(dialog_x + 20, dialog_y + dialog_h - 50, (dialog_w - 40) / 2 - 5, 35, true)
    
    if utils.mouse_in(gfx, dialog_x + 20, dialog_y + dialog_h - 50, (dialog_w - 40) / 2 - 5, 35) then
        gfx.set(1, 0.5, 1)
    else
        gfx.set(0.3, 0.8, 0.8)
    end
    gfx.rect(dialog_x + 20, dialog_y + dialog_h - 50, (dialog_w - 40) / 2 - 5, 35, false)
    
    gfx.set(0.3, 0.8, 0.8)
    ss.set_font(12, true)
    gfx.x, gfx.y = dialog_x + 40, dialog_y + dialog_h - 40
    gfx.drawstr("CANCEL")
    
    if utils.was_clicked(gfx, dialog_x + 20, dialog_y + dialog_h - 50, (dialog_w - 40) / 2 - 5, 35, ss.ui.last_mouse_cap) then
        ss.show_load_setlist_dialog = false
        ss.setlist_load_input = ""
    end
    
    gfx.set(0.08, 0.15, 0.2)
    gfx.rect(dialog_x + (dialog_w - 40) / 2 + 15, dialog_y + dialog_h - 50, (dialog_w - 40) / 2 - 5, 35, true)
    
    if utils.mouse_in(gfx, dialog_x + (dialog_w - 40) / 2 + 15, dialog_y + dialog_h - 50, (dialog_w - 40) / 2 - 5, 35) then
        gfx.set(0, 1, 0.4)
    else
        gfx.set(0, 1, 0)
    end
    gfx.rect(dialog_x + (dialog_w - 40) / 2 + 15, dialog_y + dialog_h - 50, (dialog_w - 40) / 2 - 5, 35, false)
    
    gfx.set(0, 1, 0)
    ss.set_font(12, true)
    gfx.x, gfx.y = dialog_x + (dialog_w - 40) / 2 + 30, dialog_y + dialog_h - 40
    gfx.drawstr("LOAD")
    
    if utils.was_clicked(gfx, dialog_x + (dialog_w - 40) / 2 + 15, dialog_y + dialog_h - 50, (dialog_w - 40) / 2 - 5, 35, ss.ui.last_mouse_cap) then
        if ss.setlist_load_input ~= "" then
            local filepath = ss.script_dir .. "/" .. ss.setlist_load_input
            if not filepath:match("%.json$") then
                filepath = filepath .. ".json"
            end
            
            if ss.load_json_from_path(filepath) then
                ss.show_load_setlist_dialog = false
                ss.setlist_load_input = ""
                ss.log_file("Loaded setlist from user selection: " .. filepath)
            else
                ss.log("Failed to load setlist: " .. filepath)
                ss.log_file("Failed to load setlist: " .. filepath)
            end
        end
    end
    
    local char = gfx.getchar()
    if char > 0 then
        if char == 8 then
            if #ss.setlist_load_input > 0 then
                ss.setlist_load_input = ss.setlist_load_input:sub(1, -2)
            end
        elseif char == 13 then
            if ss.setlist_load_input ~= "" then
                local filepath = ss.script_dir .. "/" .. ss.setlist_load_input
                if not filepath:match("%.json$") then
                    filepath = filepath .. ".json"
                end
                if ss.load_json_from_path(filepath) then
                    ss.show_load_setlist_dialog = false
                    ss.setlist_load_input = ""
                end
            end
        elseif char == 27 then
            ss.show_load_setlist_dialog = false
            ss.setlist_load_input = ""
        elseif char >= 32 and char <= 126 then
            ss.setlist_load_input = ss.setlist_load_input .. string.char(char)
        end
    end
end

return ui
