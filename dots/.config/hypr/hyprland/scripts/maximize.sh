#!/usr/bin/env bash
# maximize.sh
# Smart maximize/resize that handles both Dwindle and Scrolling layouts.

WS_ID=$(hyprctl activeworkspace -j | jq -r '.id')
LAYOUT_CONF="$HOME/.config/hypr/hyprland/layout.conf"

# Check if the current workspace is in scrolling mode in the persistent config
if grep -q "workspace = $WS_ID, layout:scrolling" "$LAYOUT_CONF" 2>/dev/null; then
    # SCROLLING LAYOUT
    hyprctl dispatch layoutmsg colresize +conf
else
    # DWINDLE LAYOUT
    hyprctl dispatch fullscreen 1
fi
