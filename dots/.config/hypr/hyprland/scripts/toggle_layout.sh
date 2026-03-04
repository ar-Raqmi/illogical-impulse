#!/usr/bin/env bash
# toggle_layout.sh
# Persistent workspace layout toggle.
# This script manages ~/.config/hypr/hyprland/layout.conf

LAYOUT_CONF="$HOME/.config/hypr/hyprland/layout.conf"
WORKSPACE_ID=$(hyprctl activeworkspace -j | jq -r '.id')
RULE="workspace = $WORKSPACE_ID, layout:scrolling"

# Ensure file exists
[ ! -f "$LAYOUT_CONF" ] && echo "# Managed by toggle_layout.sh" > "$LAYOUT_CONF"

if grep -Fxq "$RULE" "$LAYOUT_CONF"; then
    # Rule exists → remove it (back to dwindle)
    # Using a temporary file for safety
    grep -v -x "$RULE" "$LAYOUT_CONF" > "$LAYOUT_CONF.tmp" && mv "$LAYOUT_CONF.tmp" "$LAYOUT_CONF"
    notify-send "Layout" "Workspace $WORKSPACE_ID → Dwindle" -a "Layout" -t 2000
else
    # Rule missing → add it
    echo "$RULE" >> "$LAYOUT_CONF"
    notify-send "Layout" "Workspace $WORKSPACE_ID → Scrolling" -a "Layout" -t 2000
fi

# Reload Hyprland to apply the specific config rule
# This ensures full inheritance of custom scrolling widths/options
hyprctl reload
