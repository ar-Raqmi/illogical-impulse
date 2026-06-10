#!/usr/bin/env bash

hyprctl dispatch "function()
  local WindowMinimizer = {}
  WindowMinimizer.__index = WindowMinimizer

  function WindowMinimizer.new(state_file)
    local self = setmetatable({}, WindowMinimizer)
    self.state_file = state_file or (os.getenv(\"HOME\") .. \"/.cache/hypr_floating_minimized.txt\")
    return self
  end

  function WindowMinimizer:is_minimized(w)
    local name = w.workspace.name
    return string.sub(name, 1, 7) == \"special\"
  end

  function WindowMinimizer:remember_floating(address)
    local f = io.open(self.state_file, \"a\")
    if f then
      f:write(address .. \"\\n\")
      f:close()
    end
  end

  function WindowMinimizer:forget_floating(address)
    local was_floating = false
    local lines = {}
    local f = io.open(self.state_file, \"r\")
    if f then
      for line in f:lines() do
        if line == address then
          was_floating = true
        else
          table.insert(lines, line)
        end
      end
      f:close()
    end
    if was_floating then
      local f = io.open(self.state_file, \"w\")
      if f then
        for _, line in ipairs(lines) do
          f:write(line .. \"\\n\")
        end
        f:close()
      end
    end
    return was_floating
  end

  function WindowMinimizer:minimize(w)
    if w.floating then
      self:remember_floating(w.address)
    else
      hl.dispatch(hl.dsp.window.float({ action = \"toggle\" }))
    end
    
    local m = w.monitor or hl.get_active_monitor()
    local max_w = math.floor(m.width * 0.8)
    local max_h = math.floor(m.height * 0.8)
    
    local target_w = w.size.x
    local target_h = w.size.y
    if target_w > max_w then target_w = max_w end
    if target_h > max_h then target_h = max_h end
    
    hl.dispatch(hl.dsp.window.resize({ x = target_w, y = target_h }))
    hl.dispatch(hl.dsp.window.center())
    hl.dispatch(hl.dsp.window.move({ workspace = \"special\", follow = false }))
  end

  function WindowMinimizer:restore(w)
    hl.dispatch(hl.dsp.window.move({ workspace = \"e+0\" }))
    local was_floating = self:forget_floating(w.address)
    if not was_floating then
      hl.dispatch(hl.dsp.window.float({ action = \"toggle\" }))
    end
  end

  function WindowMinimizer:toggle()
    local w = hl.get_active_window()
    if not w then return end
    
    if self:is_minimized(w) then
      self:restore(w)
    else
      self:minimize(w)
    end
  end

  local minimizer = WindowMinimizer.new()
  minimizer:toggle()
end"
