-- Reaper Song Switcher Launcher
-- This Lua script loads and runs the Python Song Switcher
-- @description Load Reaper Song Switcher (Python)
-- @version 1.0
-- @author DSALYSS

local script_dir = debug.getinfo(1).source:match("@?(.*/)")
local python_script = script_dir .. "switcher.py"

-- Try to run the Python script
if reaper.APIExists("py_exec") then
    -- Use Reaper's Python extension
    reaper.py_exec(string.format('exec(open(r"%s").read())', python_script))
else
    -- Fallback: Show error message
    reaper.ShowConsoleMsg("ERROR: Reaper Python extension not installed!\n")
    reaper.ShowConsoleMsg("Please install the Python extension from:\n")
    reaper.ShowConsoleMsg("https://github.com/cfillion/reaper-python\n")
    reaper.MB("Reaper Python extension required. See console for details.", "Error", 0)
end
