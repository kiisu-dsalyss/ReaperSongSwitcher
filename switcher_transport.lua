-- REAPER SONG SWITCHER - TRANSPORT CONTROL UI
-- Auto-switches songs with visual transport controls
-- Modularized version with imports

-- Set to false to disable console output
local ENABLE_CONSOLE_OUTPUT = false

_G.SS = _G.SS or {}
local ss = _G.SS

-- Initialize script directory first
ss.script_dir = reaper.GetResourcePath() .. "/Scripts/ReaperSongSwitcher"
ss.transport_log = ss.script_dir .. "/switcher_transport.log"

-- Add script directory to Lua path for module loading
package.path = ss.script_dir .. "/?.lua;" .. ss.script_dir .. "/?/init.lua;" .. package.path

-- Load modules with explicit paths
local config_module = dofile(ss.script_dir .. "/modules/config.lua")
local fonts_module = dofile(ss.script_dir .. "/modules/fonts.lua")
local setlist_module = dofile(ss.script_dir .. "/modules/setlist.lua")
local utils = dofile(ss.script_dir .. "/modules/utils.lua")
local ui_module = dofile(ss.script_dir .. "/modules/ui.lua")
local playback_module = dofile(ss.script_dir .. "/modules/playback.lua")
local ui_comp = dofile(ss.script_dir .. "/modules/ui_components.lua")
local input = dofile(ss.script_dir .. "/modules/input.lua")

function ss.log_transport(msg)
    utils.log_transport(ss.script_dir, msg)
end

-- Set to a system font that Reaper can use
-- Available: "Arial", "Menlo", "Courier New", "Courier", "Monaco"
-- Menlo is closest to Hacked-KerX (monospace tech aesthetic)
local PREFERRED_FONT = "Menlo"

ss.config_file = ss.script_dir .. "/config.json"
ss.current_font = PREFERRED_FONT  -- Will be loaded from config
ss.font_size_multiplier = 1.0  -- Will be loaded from config (1.0 = 100%, 1.2 = 120%, etc)
ss.window_x = ss.window_x or 100  -- Will be loaded from config
ss.window_y = ss.window_y or 100  -- Will be loaded from config
ss.window_w = ss.window_w or 700  -- Will be loaded from config
ss.window_h = ss.window_h or 750  -- Will be loaded from config

function ss.load_config()
    ss.config = config_module.load(ss.script_dir, ss.log_transport)
    ss.current_font = ss.config.ui_font or "Menlo"
    ss.font_size_multiplier = ss.config.font_size_multiplier or 1.0
    return true
end

function ss.save_config(font_name, multiplier)
    config_module.save(ss.script_dir, font_name, multiplier, ss.log_transport)
    ss.current_font = font_name
    ss.font_size_multiplier = multiplier
end

function ss.load_window_state()
    local x = reaper.GetExtState("ReaperSongSwitcher", "window_x")
    local y = reaper.GetExtState("ReaperSongSwitcher", "window_y")
    local w = reaper.GetExtState("ReaperSongSwitcher", "window_w")
    local h = reaper.GetExtState("ReaperSongSwitcher", "window_h")
    
    if x ~= "" and y ~= "" and w ~= "" and h ~= "" then
        ss.window_x = tonumber(x) or 100
        ss.window_y = tonumber(y) or 100
        ss.window_w = tonumber(w) or 700
        ss.window_h = tonumber(h) or 750
        ss.log_transport("Loaded window state: x=" .. ss.window_x .. " y=" .. ss.window_y .. " w=" .. ss.window_w .. " h=" .. ss.window_h)
        return true
    else
        ss.window_x = 100
        ss.window_y = 100
        ss.window_w = 700
        ss.window_h = 750
    end
    return false
end

function ss.save_window_position()
    reaper.SetExtState("ReaperSongSwitcher", "window_x", tostring(math.floor(gfx.x)), true)
    reaper.SetExtState("ReaperSongSwitcher", "window_y", tostring(math.floor(gfx.y)), true)
    reaper.SetExtState("ReaperSongSwitcher", "window_w", tostring(gfx.w), true)
    reaper.SetExtState("ReaperSongSwitcher", "window_h", tostring(gfx.h), true)
    ss.log_transport("Saved window state: x=" .. math.floor(gfx.x) .. " y=" .. math.floor(gfx.y) .. " w=" .. gfx.w .. " h=" .. gfx.h)
end

function ss.set_font(size, bold)
    local multiplier = ss.font_size_multiplier or 1.0
    local scaled_size = math.floor(size * multiplier)
    fonts_module.set_font(gfx, ss.current_font, scaled_size, bold)
    if not ss.font_logged then
        ss.log_file("set_font() called with: font=" .. ss.current_font .. ", size=" .. scaled_size .. ", bold=" .. tostring(bold))
        ss.font_logged = true
    end
end

ss.setlist_file = ss.script_dir .. "/setlist.json"
ss.current_setlist_path = ss.current_setlist_path or ss.setlist_file  -- Currently loaded setlist
ss.songs = ss.songs or {}
ss.base_path = ss.base_path or ""
ss.current_index = ss.current_index or 1
ss.last_pos = ss.last_pos or 0
ss.init_done = ss.init_done or false
ss.switch_cooldown = ss.switch_cooldown or 0
ss.auto_switch_state = ss.auto_switch_state or 0  -- 0=idle, 1=loaded_waiting_to_play
ss.auto_switch_next_idx = ss.auto_switch_next_idx or 0
ss.loop_check_counter = ss.loop_check_counter or 0
ss.show_load_setlist_dialog = ss.show_load_setlist_dialog or false  -- Show load setlist dialog
ss.ui = ss.ui or {}
ss.ui.selected = ss.ui.selected or 1
ss.ui.last_mouse_cap = ss.ui.last_mouse_cap or 0
ss.font_logged = ss.font_logged or false  -- Debug flag for font logging
ss.show_font_picker = ss.show_font_picker or false  -- Show font picker dialog
ss.font_search = ss.font_search or ""  -- Font search string
ss.setlist_load_input = ss.setlist_load_input or ""  -- Setlist load input string
ss.available_fonts = ss.available_fonts or {}  -- Will be populated by get_system_fonts()
ss.font_picker_scroll = ss.font_picker_scroll or 0
ss.font_picker_dragging = ss.font_picker_dragging or false
ss.font_picker_drag_offset = ss.font_picker_drag_offset or 0
ss.window_save_counter = ss.window_save_counter or 0  -- Counter for periodic window position saves

-- Get all available system fonts
function ss.get_system_fonts()
    if #ss.available_fonts > 0 then
        ss.log_transport("Fonts already loaded: " .. #ss.available_fonts)
        return
    end
    ss.available_fonts = fonts_module.load_system_fonts(ss.script_dir, ss.log_transport)
end

function ss.log_file(msg)
    utils.log_switcher(ss.script_dir, msg)
end

function ss.load_json_from_path(filepath)
    local result = setlist_module.load_from_path(filepath, ss.log, ss.log_file)
    if result then
        ss.current_setlist_path = result.path
        ss.base_path = result.base_path
        ss.songs = result.songs
        ss.current_index = 1
        ss.ui.selected = 1
        return true
    end
    return false
end

function ss.load_json()
    return ss.load_json_from_path(ss.current_setlist_path or ss.setlist_file)
end

function ss.load_song(idx)
    playback_module.load_song(idx, ss)
end

function ss.load_song_no_play(idx)
    playback_module.load_song_no_play(idx, ss)
end

function ss.init()
    if not ss.init_done then
        ss.load_config()  -- Load font preference from config
        ss.get_system_fonts()  -- Populate available fonts list
        if ss.load_json() then
            ss.init_done = true
            ss.log("Ready!")
            ss.log_file("=== INIT: Font attempting to use: " .. ss.current_font .. " ===")
            
            -- Sync loop button with Reaper's actual transport loop state on first run only
            if not ss.ui.loop_initialized then
                -- Read Reaper's repeat/loop state: GetSetRepeat(-1) returns 0 if off, 1 if on
                local loop_state = reaper.GetSetRepeat(-1)
                ss.ui.loop_enabled = (loop_state == 1)
                ss.ui.loop_initialized = true
                ss.log("Loop initialized: " .. (ss.ui.loop_enabled and "ON" or "OFF"))
                ss.log_file("Loop initialized: " .. (ss.ui.loop_enabled and "ON" or "OFF"))
            end
            
            ss.load_song(1)  -- Auto-load first song
        else
            reaper.defer(ss.init)
            return
        end
    end
end

-- Font picker UI wrapper
function ss.draw_font_picker()
    ui_module.draw_font_picker(ss, fonts_module, utils)
end

-- Load setlist dialog wrapper
function ss.draw_load_setlist_dialog()
    ui_module.draw_load_setlist_dialog(ss, setlist_module, utils)
end

-- UI helper functions
function ss.ui.mouse_in(x, y, w, h)
    return utils.mouse_in(gfx, x, y, w, h)
end

function ss.ui.was_clicked(x, y, w, h)
    return utils.was_clicked(gfx, x, y, w, h, ss.ui.last_mouse_cap)
end

function ss.ui.draw()
    -- Draw main UI using modular components
    ui_comp.draw_header(ss, setlist_module, utils)
    ui_comp.draw_header_buttons(ss, utils)
    ui_comp.draw_song_list(ss, utils)
    ui_comp.draw_loop_button(ss, utils)
    ui_comp.draw_transport_controls(ss, utils)
end

function ss.main()
    ss.init()
    
    -- Auto-switch state machine for deferred playback
    -- State 0: idle
    -- State 1: loaded, waiting to play (give Reaper one frame to settle)
    if ss.auto_switch_state == 1 then
        reaper.Main_OnCommand(1007, 0)
        ss.auto_switch_state = 0  -- Back to idle
        ss.log_file("auto_switch: playing after wait for index " .. ss.current_index)
    end
    
    -- Handle auto-switching with End marker detection
    playback_module.handle_auto_switch_v2(ss)
    
    -- Handle keyboard input for dialogs
    input.handle_font_search(ss, ss.show_font_picker, ss.show_load_setlist_dialog)
    
    -- Draw UI
    ss.ui.draw()
    
    -- Draw font picker if shown
    if ss.show_font_picker then
        ss.draw_font_picker()
    end
    
    -- Draw load setlist dialog if shown
    if ss.show_load_setlist_dialog then
        ss.draw_load_setlist_dialog()
    end
    
    -- Periodically save window position (every 30 frames)
    ss.window_save_counter = ss.window_save_counter + 1
    if ss.window_save_counter >= 30 then
        ss.save_window_position()
        ss.window_save_counter = 0
    end
    
    -- Update mouse state
    input.update_mouse_state(ss)
    gfx.update()
    
    reaper.defer(ss.main)
end

-- Initialize gfx window with remembered size
ss.load_window_state()

-- Create window with saved dimensions
gfx.init("REAPER Song Switcher - Transport", ss.window_w or 700, ss.window_h or 750, 0)

-- Load system fonts and config on startup
ss.load_config()
ss.get_system_fonts()

-- Dock the window so REAPER remembers its position
-- Using dock flag 257 (DOCKFLAG_RIGHT) like the setlist editor does
if gfx.dock(-1) == 0 then
    -- Not docked yet, apply docking
    gfx.dock(257)  -- DOCKFLAG_RIGHT
    ss.log_transport("Docking window to REAPER layout")
end

ss.log_transport("Window initialized with size " .. (ss.window_w or 700) .. "x" .. (ss.window_h or 750) .. " and docked for position persistence")

ss.main()
