#!/usr/bin/env bash

ADDR="$1"
if [ -z "$ADDR" ]; then
    echo "Usage: $0 <window_address>"
    exit 1
fi

WINDOW_INFO=$(hyprctl clients -j | jq -c ".[] | select(.address == \"$ADDR\")")
if [ -z "$WINDOW_INFO" ]; then
    exit 1
fi

WORKSPACE_NAME=$(echo "$WINDOW_INFO" | jq -r ".workspace.name")

if [[ "$WORKSPACE_NAME" == special* ]]; then
    hyprctl dispatch "hl.dsp.window.move({ workspace = 'e+0', window = 'address:$ADDR' })"
    # sleep 0.01
    
    hyprctl dispatch "function()
      local WindowRestorer = {}
      WindowRestorer.__index = WindowRestorer

      function WindowRestorer.new(addr)
        local self = setmetatable({}, WindowRestorer)
        self.addr = addr
        self.state_file = os.getenv('HOME') .. '/.cache/hypr_floating_minimized.txt'
        return self
      end

      function WindowRestorer:forget_floating()
        local was_floating = false
        local lines = {}
        local f = io.open(self.state_file, 'r')
        if f then
          for line in f:lines() do
            if line == self.addr then
              was_floating = true
            else
              table.insert(lines, line)
            end
          end
          f:close()
        end
        if was_floating then
          local f = io.open(self.state_file, 'w')
          if f then
            for _, line in ipairs(lines) do
              f:write(line .. '\n')
            end
            f:close()
          end
        end
        return was_floating
      end

      local restorer = WindowRestorer.new('$ADDR')
      if not restorer:forget_floating() then
        hl.dispatch(hl.dsp.window.float({ action = 'toggle', window = 'address:$ADDR' }))
      end
    end"
fi

hyprctl dispatch "hl.dsp.focus({ window = 'address:$ADDR' })"
