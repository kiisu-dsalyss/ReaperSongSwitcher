-- Image Loader Module
-- Loads and displays PNG images for backgrounds using REAPER's gfx API

local image_loader = {}
local img_cache = {}

-- Load a PNG image into gfx buffer
function image_loader.load_png(filepath, log_fn)
    if not filepath or filepath == "" then
        return nil
    end
    
    -- Check if file exists
    local f = io.open(filepath, "rb")
    if not f then
        if log_fn then log_fn("Image file not found: " .. filepath) end
        return nil
    end
    f:close()
    
    -- Check cache first
    if img_cache[filepath] then
        if log_fn then log_fn("Using cached image") end
        return img_cache[filepath]
    end
    
    -- Try to load image into buffer 25
    local buf_idx = 25
    if not gfx.loadimg then
        if log_fn then log_fn("gfx.loadimg not available") end
        return nil
    end
    
    local ret = gfx.loadimg(buf_idx, filepath)
    if log_fn then log_fn("gfx.loadimg(" .. buf_idx .. ", ...) returned: " .. tostring(ret)) end
    
    -- Success if ret == buf_idx (the function returns the image index on success)
    if ret == buf_idx or ret >= 0 then
        local img_data = {
            filepath = filepath,
            buf_idx = buf_idx,
            valid = true
        }
        img_cache[filepath] = img_data
        if log_fn then log_fn("Image loaded successfully to buffer " .. buf_idx) end
        return img_data
    else
        if log_fn then log_fn("Failed to load image, gfx.loadimg returned: " .. tostring(ret)) end
        return nil
    end
end

-- Draw image background
function image_loader.draw_centered_background(img_data, bg_x, bg_y, bg_w, bg_h, fallback_r, fallback_g, fallback_b)
    -- Draw fallback background first
    gfx.set(fallback_r or 0.08, fallback_g or 0.12, fallback_b or 0.15)
    gfx.rect(bg_x, bg_y, bg_w, bg_h, true)
    
    if not img_data or not img_data.valid then
        return false
    end
    
    -- Try to get image dimensions
    local w, h = gfx.getimgdim(img_data.buf_idx)
    
    if w == 0 or h == 0 then
        return false
    end
    
    -- Blit from the loaded image buffer to the main framebuffer
    -- gfx.blit(source, scale, rotation, srcx, srcy, srcw, srch, destx, desty, destw, desth)
    if gfx.blit then
        gfx.blit(img_data.buf_idx, 1.0, 0, 0, 0, w, h, bg_x, bg_y, bg_w, bg_h)
        return true
    end
    
    return false
end

function image_loader.draw_overlay(r, g, b, x, y, w, h)
    gfx.set(r, g, b)
    gfx.rect(x, y, w, h, true)
end

return image_loader
