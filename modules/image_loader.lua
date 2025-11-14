-- Image Loader Module
-- Note: REAPER's gfx API has limited built-in image support
-- This module manages image paths and provides fallback visualization

local image_loader = {}

-- Load a PNG image reference (not actual pixel data)
function image_loader.load_png(filepath, log_fn)
    if not filepath or filepath == "" then
        return nil
    end
    
    -- Check if file exists
    local f = io.open(filepath, "rb")
    if not f then
        if log_fn then log_fn("Image not found: " .. filepath) end
        return nil
    end
    f:close()
    
    -- Just store the filepath
    local img_data = {
        filepath = filepath,
        valid = true
    }
    
    if log_fn then log_fn("Registered PNG: " .. filepath) end
    
    return img_data
end

-- Draw background with image path indicator
-- Since REAPER gfx has limited image support, we'll draw a patterned background
function image_loader.draw_centered_background(img_data, bg_x, bg_y, bg_w, bg_h, fallback_r, fallback_g, fallback_b)
    if not img_data or not img_data.valid then
        -- Draw fallback color
        gfx.set(fallback_r or 0.08, fallback_g or 0.12, fallback_b or 0.15)
        gfx.rect(bg_x, bg_y, bg_w, bg_h, true)
        return false
    end
    
    -- Draw gradient or pattern as background with image tint
    -- Use a subtle pattern to indicate an image is loaded
    local r = (fallback_r or 0.08) * 1.3
    local g = (fallback_g or 0.12) * 1.3
    local b = (fallback_b or 0.15) * 1.3
    
    -- Clamp to 1.0
    r = math.min(1.0, r)
    g = math.min(1.0, g)
    b = math.min(1.0, b)
    
    gfx.set(r, g, b)
    gfx.rect(bg_x, bg_y, bg_w, bg_h, true)
    
    -- Draw subtle grid pattern to indicate an image is present
    gfx.set(r * 0.7, g * 0.7, b * 0.7, 0.3)
    local grid_size = 40
    for x = bg_x, bg_x + bg_w, grid_size do
        gfx.line(x, bg_y, x, bg_y + bg_h, 1)
    end
    for y = bg_y, bg_y + bg_h, grid_size do
        gfx.line(bg_x, y, bg_x + bg_w, y, 1)
    end
    
    return true
end

-- Simple version: draw background color
function image_loader.draw_overlay(r, g, b, x, y, w, h)
    gfx.set(r, g, b)
    gfx.rect(x, y, w, h, true)
end

return image_loader
