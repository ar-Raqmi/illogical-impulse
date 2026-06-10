#!/usr/bin/env bash

hyprctl dispatch "function()
  local w = hl.get_active_window()
  if not w then return end

  if not w.floating then
    hl.dispatch(hl.dsp.window.float({ action = \"toggle\" }))
    
    local m = w.monitor or hl.get_active_monitor()
    local m_width = m.width
    local m_height = m.height
    
    local t_width = math.floor(m_width * 0.50)
    local t_height = math.floor(m_height * 0.60)
    
    -- Refresh window details after floating if necessary, or just use w
    -- To be safe, let's get the active window again to ensure its sizes are correct
    w = hl.get_active_window()
    if not w then return end
    
    local resize_w = w.size.x
    local resize_y = w.size.y
    local modified = false
    
    if resize_w > t_width then
      resize_w = t_width
      modified = true
    end
    if resize_y > t_height then
      resize_y = t_height
      modified = true
    end
    
    if modified then
      hl.dispatch(hl.dsp.window.resize({ x = resize_w, y = resize_y }))
      hl.dispatch(hl.dsp.window.center())
    end
  else
    hl.dispatch(hl.dsp.window.float({ action = \"toggle\" }))
  end
end"
