-- REAPER SETLIST EDITOR - MODULARIZED
-- Main entry point - coordinates modules

-- Set to false to disable console output
local ENABLE_CONSOLE_OUTPUT = false

if not gfx then
    reaper.ShowConsoleMsg("ERROR: gfx library not available. This script requires a graphical environment.\n")
    return
end

_G.SETLIST_EDITOR = _G.SETLIST_EDITOR or {}
local ed = _G.SETLIST_EDITOR

-- Load all modules
local script_dir = reaper.GetResourcePath() .. "/Scripts/ReaperSongSwitcher"
local state_module = dofile(script_dir .. "/modules/editor_state.lua")
local io_module = dofile(script_dir .. "/modules/editor_io.lua")
local songs_module = dofile(script_dir .. "/modules/editor_songs.lua")
local ui_utils = dofile(script_dir .. "/modules/editor_ui_utils.lua")
local ui_draw = dofile(script_dir .. "/modules/editor_draw.lua")
local dialogs = dofile(script_dir .. "/modules/editor_dialogs.lua")
local json_editor = dofile(script_dir .. "/modules/editor_json.lua")

-- Initialize state
ed.script_dir = script_dir
state_module.init_all(ed)
ed.config_loaded = false

function ed.log(msg)
    if ENABLE_CONSOLE_OUTPUT then
        reaper.ShowConsoleMsg("[SE] " .. msg .. "\n")
    end
end

function ed.main()
    -- Load shared config on first run
    if not ed.config_loaded then
        io_module.load_config(ed)
        ed.config_loaded = true
    end
    
    if not ed.songs or #ed.songs == 0 then
        local loaded = io_module.load_json(ed)
        if not loaded then
            ed.log("Failed to load setlist.json - check path")
        end
    end
    
    -- Initialize gfx
    ui_utils.init_gfx()
    
    -- Handle keyboard input when in edit mode
    if ed.edit_mode then
        local char = gfx.getchar()
        if char ~= -1 then
            if char == 8 then
                -- Backspace: delete last character
                if ed.edit_focus == "name" and #ed.edit_name > 0 then
                    ed.edit_name = ed.edit_name:sub(1, -2)
                elseif ed.edit_focus == "path" and #ed.edit_path > 0 then
                    ed.edit_path = ed.edit_path:sub(1, -2)
                end
            elseif char == 9 then
                -- Tab: switch focus between name and path fields
                ed.edit_focus = (ed.edit_focus == "name") and "path" or "name"
            elseif char == 13 then
                -- Enter: save the edit
                songs_module.finish_edit(ed)
            elseif char == 27 then
                -- Escape: cancel the edit
                songs_module.cancel_edit(ed)
            elseif char >= 32 and char < 127 then
                -- Regular printable character
                local c = string.char(char)
                if ed.edit_focus == "name" then
                    ed.edit_name = ed.edit_name .. c
                else
                    ed.edit_path = ed.edit_path .. c
                end
            end
        end
    end
    
    -- Handle keyboard input when in create dialog
    if ed.create_dialog_open then
        local char = gfx.getchar()
        if char ~= -1 then
            if char == 8 then
                -- Backspace: delete last character
                if (ed.create_focus or "") == "name" and #ed.new_setlist_name > 0 then
                    ed.new_setlist_name = ed.new_setlist_name:sub(1, -2)
                elseif (ed.create_focus or "") == "path" and #ed.new_setlist_path > 0 then
                    ed.new_setlist_path = ed.new_setlist_path:sub(1, -2)
                end
            elseif char == 9 then
                -- Tab: switch focus
                ed.create_focus = ((ed.create_focus or "name") == "name") and "path" or "name"
            elseif char == 13 then
                -- Enter: create the setlist
                io_module.finish_create(ed)
            elseif char == 27 then
                -- Escape: cancel
                io_module.close_create_dialog(ed)
            elseif char >= 32 and char < 127 then
                -- Regular printable character
                local c = string.char(char)
                if (ed.create_focus or "") == "name" then
                    ed.new_setlist_name = ed.new_setlist_name .. c
                elseif (ed.create_focus or "") == "path" then
                    ed.new_setlist_path = ed.new_setlist_path .. c
                end
            end
        end
    end
    
    -- Handle keyboard input when in JSON editor
    if ed.json_editor_open then
        local char = gfx.getchar()
        if char ~= -1 then
            if char == 8 then
                -- Backspace: delete last character
                if #ed.json_content > 0 then
                    ed.json_content = ed.json_content:sub(1, -2)
                end
            elseif char == 27 then
                -- Escape: close editor
                json_editor.close_json_editor(ed)
            elseif char >= 32 and char < 127 then
                -- Regular printable character - append to end
                local c = string.char(char)
                ed.json_content = ed.json_content .. c
            elseif char == 13 then
                -- Enter: add newline
                ed.json_content = ed.json_content .. "\n"
            end
        end
        
        -- Handle scroll wheel for JSON editor
        local scroll = gfx.mouse_wheel
        if scroll ~= 0 then
            ed.json_scroll_offset = math.max(0, ed.json_scroll_offset - scroll)
            gfx.mouse_wheel = 0
        end
    end
    
    -- Draw edit dialog if active (returns early)
    if ed.edit_mode then
        dialogs.draw_edit_dialog(ed, ui_utils, songs_module)
        reaper.defer(ed.main)
        return
    end
    
    -- Draw create dialog if active (returns early)
    if ed.create_dialog_open then
        dialogs.draw_create_dialog(ed, ui_utils, io_module)
        reaper.defer(ed.main)
        return
    end
    
    -- Draw JSON editor if active (returns early)
    if ed.json_editor_open then
        json_editor.draw_json_editor(ed, ui_utils)
        reaper.defer(ed.main)
        return
    end
    
    -- Draw main UI
    ui_draw.draw_ui(ed, ui_utils, songs_module, io_module, json_editor)
    
    -- Check if close was requested
    if ed.close_requested then
        gfx.quit()
        return
    end
    
    reaper.defer(ed.main)
end

ed.log("Starting Setlist Editor...")
ed.main()
