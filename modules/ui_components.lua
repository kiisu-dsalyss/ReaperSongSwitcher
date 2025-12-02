-- UI Component Drawing Functions
-- Modular drawing functions for main transport UI

local ui_comp = {}

-- Draw header with setlist title and current filename
function ui_comp.draw_header(ss, setlist_module, utils, image_loader, bg_image)
    local w, h = gfx.w, gfx.h
    
    -- Debug: log image state
    if bg_image then
        if not ss._image_debug_logged then
            ss.log_transport("DEBUG: bg_image exists, buffer_idx=" .. tostring(bg_image.buffer_idx))
            ss._image_debug_logged = true
        end
    end
    
    -- Draw background image if available, otherwise use solid color
    if bg_image and image_loader then
        local drew_img = image_loader.draw_centered_background(bg_image, 0, 0, w, h, 0.08, 0.12, 0.15)
        if not drew_img then
            -- Fallback if image draw failed
            gfx.set(0.08, 0.12, 0.15)
            gfx.rect(0, 0, w, h, true)
        end
    else
        -- Fallback to solid color background
        gfx.set(0.08, 0.12, 0.15)
        gfx.rect(0, 0, w, h, true)
    end
    
    -- Header
    gfx.set(0.1, 0.18, 0.25)
    gfx.rect(0, 0, w, 50, true)
    gfx.set(0, 1, 1)
    gfx.rect(0, 0, w, 50, false)
    
    gfx.set(0, 1, 1)
    ss.set_font(24, true)
    gfx.x, gfx.y = 15, 12
    gfx.drawstr("SETLIST")
    
    -- Display current setlist filename
    local setlist_name = setlist_module.get_filename(ss.current_setlist_path)
    gfx.set(0.5, 0.8, 0.9)
    ss.set_font(11, false)
    gfx.x, gfx.y = 15, 35
    gfx.drawstr(setlist_name)
end

-- Draw load button and gear config button in header area
function ui_comp.draw_header_buttons(ss, utils)
    local w = gfx.w
    local gear_size = 24
    local close_size = 24
    
    -- Close button (X) - top right corner
    local close_btn_x = w - close_size - 10
    local close_btn_y = 13
    
    if ss.ui.mouse_in(close_btn_x - 3, close_btn_y - 3, close_size + 6, close_size + 6) then
        gfx.set(1, 0.3, 0.3)  -- red hover
    else
        gfx.set(0.6, 0.6, 0.6)  -- gray
    end
    
    -- Draw X
    local cx = close_btn_x + close_size / 2
    local cy = close_btn_y + close_size / 2
    local xr = close_size / 3
    gfx.line(cx - xr, cy - xr, cx + xr, cy + xr)
    gfx.line(cx + xr, cy - xr, cx - xr, cy + xr)
    
    if ss.ui.was_clicked(close_btn_x - 3, close_btn_y - 3, close_size + 6, close_size + 6) then
        ss.close_requested = true
    end
    
    -- Load Setlist button (left of close button)
    local load_btn_w = 60
    local load_btn_h = 28
    local load_btn_x = close_btn_x - load_btn_w - 15
    local load_btn_y = 11
    
    -- Config gear button (left of load button)
    local gear_btn_x = load_btn_x - gear_size - 15
    local gear_btn_y = 13
    
    gfx.set(0.08, 0.15, 0.2)
    gfx.rect(load_btn_x, load_btn_y, load_btn_w, load_btn_h, true)
    
    if ss.ui.mouse_in(load_btn_x, load_btn_y, load_btn_w, load_btn_h) then
        gfx.set(0, 1, 1)  -- cyan hover
    else
        gfx.set(0.3, 0.8, 0.8)  -- cyan
    end
    gfx.rect(load_btn_x, load_btn_y, load_btn_w, load_btn_h, false)
    
    gfx.set(0.3, 0.8, 0.8)
    ss.set_font(12, true)
    gfx.x, gfx.y = load_btn_x + 8, load_btn_y + 7
    gfx.drawstr("LOAD")
    
    if ss.ui.was_clicked(load_btn_x, load_btn_y, load_btn_w, load_btn_h) then
        ss.show_load_setlist_dialog = true
    end
    
    -- Draw gear button
    if ss.ui.mouse_in(gear_btn_x - 5, gear_btn_y - 5, gear_size + 10, gear_size + 10) then
        gfx.set(1, 0.5, 1)  -- magenta hover
    else
        gfx.set(0.3, 0.8, 0.8)  -- cyan
    end
    
    -- Draw proper gear icon
    local gcx = gear_btn_x + gear_size / 2
    local gcy = gear_btn_y + gear_size / 2
    local outer_r = gear_size / 2 - 2
    local inner_r = outer_r * 0.6
    local tooth_depth = outer_r * 0.3
    
    -- Draw gear using filled polygon (teeth and body)
    local points = {}
    local num_teeth = 12
    
    for i = 0, num_teeth - 1 do
        -- Outer tooth point
        local angle_tooth = (i * math.pi * 2 / num_teeth)
        table.insert(points, {gcx + math.cos(angle_tooth) * outer_r, gcy + math.sin(angle_tooth) * outer_r})
        
        -- Inner valley point
        local angle_valley = ((i + 0.5) * math.pi * 2 / num_teeth)
        table.insert(points, {gcx + math.cos(angle_valley) * inner_r, gcy + math.sin(angle_valley) * inner_r})
    end
    
    -- Draw filled gear
    gfx.mode = 2  -- antialiasing
    for i = 1, #points do
        if i == 1 then
            gfx.line(points[i][1], points[i][2], points[#points][1], points[#points][2])
        else
            gfx.line(points[i][1], points[i][2], points[i-1][1], points[i-1][2])
        end
    end
    
    -- Draw center hole
    gfx.circle(gcx, gcy, inner_r * 0.35, true)
    
    if ss.ui.was_clicked(gear_btn_x - 5, gear_btn_y - 5, gear_size + 10, gear_size + 10) then
        ss.show_config_menu = true
    end
end

-- Draw the song list
function ui_comp.draw_song_list(ss, utils)
    local w, h = gfx.w, gfx.h
    
    -- Song list area
    local list_y = 60
    local list_h = h - 150
    local row_h = 40
    local max_rows = math.floor(list_h / row_h)
    
    -- Draw songs
    for i = 1, math.min(#ss.songs, max_rows) do
        local y = list_y + (i - 1) * row_h
        local is_current = (ss.current_index == i)
        local is_selected = (ss.ui.selected == i)
        local is_playing = reaper.GetPlayStateEx(0) == 1
        
        -- Row background - alternating stripes
        if i % 2 == 0 then
            gfx.set(0.08, 0.15, 0.2)
        else
            gfx.set(0.1, 0.18, 0.25)
        end
        gfx.rect(0, y, w, row_h, true)
        
        -- Current/selected highlight
        if is_current and is_playing then
            gfx.set(0, 1, 1)  -- cyan for currently playing
            gfx.rect(0, y, w, row_h, false)
        elseif is_selected then
            gfx.set(1, 0, 1)  -- magenta for selected
            gfx.rect(0, y, w, row_h, false)
        end
        
        -- Song text
        if is_current and is_playing then
            gfx.set(0, 1, 1)  -- cyan text
        elseif is_selected then
            gfx.set(1, 0, 1)  -- magenta text
        else
            gfx.set(0.7, 0.7, 0.7)  -- normal text
        end
        -- Scale text size based on configured multiplier (maintains relative sizing)
        local font_mult = ss.font_size_multiplier or 1.0
        local text_size = math.floor(18 * font_mult)
        ss.set_font(text_size, true)
        gfx.x, gfx.y = 20, y + 11
        gfx.drawstr(i .. ". " .. ss.songs[i].name)
        
        -- Click to select
        if ss.ui.was_clicked(0, y, w, row_h) then
            ss.ui.selected = i
            ss.log_file("Selected song " .. i)
        end
    end
end

-- Draw loop toggle button
function ui_comp.draw_loop_button(ss, utils)
    local w, h = gfx.w, gfx.h
    
    -- Loop toggle button (full width)
    local loop_btn_y = h - 280
    local loop_btn_h = 140
    
    -- Check if user toggled loop (sync UI state with Reaper state changes)
    if ss.ui.was_clicked(10, loop_btn_y, w - 20, loop_btn_h) then
        -- Toggle Reaper's loop state via action 1068 (Toggle loop)
        reaper.Main_OnCommand(1068, 0)
        
        ss.log_file("Loop toggled via button")
    end
    
    -- Always read the actual loop state from Reaper, don't cache it
    -- This ensures sync even if the user toggles loop via keyboard/menu/other UI
    local loop_state = reaper.GetSetRepeat(-1)
    local loop_is_enabled = (loop_state == 1)
    
    -- Calculate pulse effect based on tempo
    local tempo = reaper.Master_GetTempo()
    local beat_time = 60 / tempo  -- seconds per beat
    local pulse_cycle = beat_time * 2  -- full pulse cycle = 2 beats
    local phase = (reaper.time_precise() % pulse_cycle) / pulse_cycle  -- 0 to 1
    
    -- When disabled, pulse the opacity; when enabled, solid
    local brightness = 1.0
    if not loop_is_enabled then
        -- Sine wave pulse from 0.5 to 1.0
        brightness = 0.5 + 0.5 * math.sin(phase * math.pi)
    end
    
    -- Set background color based on state with pulse effect
    if loop_is_enabled then
        gfx.set(1, 1, 0)  -- yellow when enabled
    else
        gfx.set(0 * brightness, 1 * brightness, 0 * brightness)  -- pulsing green when disabled
    end
    gfx.rect(10, loop_btn_y, w - 20, loop_btn_h, true)
    
    -- Border
    if ss.ui.mouse_in(10, loop_btn_y, w - 20, loop_btn_h) then
        gfx.set(1, 1, 1)  -- white hover
    else
        gfx.set(0.2, 0.2, 0.2)  -- dark border
    end
    gfx.rect(10, loop_btn_y, w - 20, loop_btn_h, false)
    
    -- Draw "LOOP ON" or "LOOP OFF" text centered, based on actual Reaper state
    gfx.set(0, 0, 0)  -- black text
    ss.set_font(56, true)
    local loop_text = loop_is_enabled and "LOOP ON" or "LOOP OFF"
    local text_width = gfx.measurestr(loop_text)
    gfx.x, gfx.y = (w - 20) / 2 + 10 - text_width / 2, loop_btn_y + loop_btn_h / 2 - 28
    gfx.drawstr(loop_text)
end

-- Draw transport control buttons (back, play/stop, skip)
function ui_comp.draw_transport_controls(ss, utils)
    local w, h = gfx.w, gfx.h
    
    -- Transport controls at bottom
    local transport_y = h - 120
    local btn_h = 100
    local btn_w = 100
    local spacing = 80
    local center_x = (w - (btn_w * 3 + spacing * 2)) / 2
    local is_playing = reaper.GetPlayStateEx(0) == 1
    
    -- << Back button
    local back_x = center_x
    gfx.set(0.08, 0.15, 0.2)
    gfx.rect(back_x, transport_y, btn_w, btn_h, true)
    
    if ss.ui.mouse_in(back_x, transport_y, btn_w, btn_h) then
        gfx.set(0, 1, 1)
        gfx.rect(back_x, transport_y, btn_w, btn_h, false)
    else
        gfx.set(0.3, 0.3, 0.3)
        gfx.rect(back_x, transport_y, btn_w, btn_h, false)
    end
    
    if ss.ui.was_clicked(back_x, transport_y, btn_w, btn_h) then
        local new_idx = ss.ui.selected - 1
        if new_idx < 1 then new_idx = #ss.songs end
        ss.ui.selected = new_idx
        ss.load_song(new_idx)
        ss.log_file("Back: loaded song " .. new_idx)
    end
    
    -- Draw << icon
    gfx.set(0, 1, 1)
    ss.set_font(48, true)
    gfx.x, gfx.y = back_x + 20, transport_y + 25
    gfx.drawstr("<<")
    
    -- Play/Stop toggle button (combined)
    local play_stop_x = back_x + btn_w + spacing
    gfx.set(0.08, 0.15, 0.2)
    gfx.rect(play_stop_x, transport_y, btn_w, btn_h, true)
    
    if ss.ui.mouse_in(play_stop_x, transport_y, btn_w, btn_h) then
        if is_playing then
            gfx.set(1, 0.4, 0.4)  -- lighter red for stop hover
        else
            gfx.set(0, 1, 0.4)  -- lighter green for play hover
        end
        gfx.rect(play_stop_x, transport_y, btn_w, btn_h, false)
    else
        if is_playing then
            gfx.set(1, 0.2, 0.2)  -- red for stop
        else
            gfx.set(0, 1, 0)  -- green for play
        end
        gfx.rect(play_stop_x, transport_y, btn_w, btn_h, false)
    end
    
    if ss.ui.was_clicked(play_stop_x, transport_y, btn_w, btn_h) then
        if is_playing then
            reaper.OnStopButtonEx(0)
            ss.log_file("Stop pressed")
        else
            ss.load_song(ss.ui.selected)
            ss.log_file("Play pressed for song " .. ss.ui.selected)
        end
    end
    
    -- Draw play triangle or stop square icon
    if is_playing then
        -- Draw stop square icon (red)
        gfx.set(1, 0.2, 0.2)
        gfx.rect(play_stop_x + 30, transport_y + 30, 40, 40, true)
    else
        -- Draw play triangle icon (green) - pointing right
        gfx.set(0, 1, 0)
        local cx = play_stop_x + 50
        local cy = transport_y + 50
        for x_offset = 0, 30 do
            local top = cy - (x_offset * 30 / 30)
            local bottom = cy + (x_offset * 30 / 30)
            gfx.line(cx - 15 + 30 - x_offset, top, cx - 15 + 30 - x_offset, bottom)
        end
    end
    
    -- >> Skip button
    local skip_x = play_stop_x + btn_w + spacing
    gfx.set(0.08, 0.15, 0.2)
    gfx.rect(skip_x, transport_y, btn_w, btn_h, true)
    
    if ss.ui.mouse_in(skip_x, transport_y, btn_w, btn_h) then
        gfx.set(0, 1, 1)
        gfx.rect(skip_x, transport_y, btn_w, btn_h, false)
    else
        gfx.set(0.3, 0.3, 0.3)
        gfx.rect(skip_x, transport_y, btn_w, btn_h, false)
    end
    
    if ss.ui.was_clicked(skip_x, transport_y, btn_w, btn_h) then
        local new_idx = ss.ui.selected + 1
        if new_idx > #ss.songs then new_idx = 1 end
        ss.ui.selected = new_idx
        ss.load_song(new_idx)
        ss.log_file("Skip: loaded song " .. new_idx)
    end
    
    -- Draw >> icon
    gfx.set(0, 1, 1)
    ss.set_font(48, true)
    gfx.x, gfx.y = skip_x + 20, transport_y + 25
    gfx.drawstr(">>")
end

return ui_comp
