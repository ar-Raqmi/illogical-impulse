#!/usr/bin/env bash
# move_focus.sh
# Smart focus navigation that handles both Dwindle and Scrolling layouts.

DIR=$1
WS_ID=$(hyprctl activeworkspace -j | jq -r '.id')
LAYOUT_CONF="$HOME/.config/hypr/hyprland/layout.conf"

# Check if the current workspace is in scrolling mode in the persistent config
if grep -q "workspace = $WS_ID, layout:scrolling" "$LAYOUT_CONF" 2>/dev/null; then
    # SCROLLING LAYOUT
    case $DIR in
        l|r)
            hyprctl dispatch layoutmsg focus "$DIR"
            ;;
        *)
            hyprctl dispatch movefocus "$DIR"
            ;;
    esac
else
    # DWINDLE LAYOUT
    hyprctl dispatch movefocus "$DIR"
fi
