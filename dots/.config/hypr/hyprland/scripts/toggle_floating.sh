#!/bin/bash

# Get active window info
WINDOW=$(hyprctl activewindow -j)
IS_FLOATING=$(echo "$WINDOW" | jq -r '.floating')

if [ "$IS_FLOATING" = "false" ]; then
    # Toggle floating
    hyprctl dispatch togglefloating
    
    # add cooldown if didnt catchup data
    # sleep 0.05 # // I'll leave it here
    
    # Refresh window info
    WINDOW=$(hyprctl activewindow -j)
    W_WIDTH=$(echo "$WINDOW" | jq -r '.size[0]')
    W_HEIGHT=$(echo "$WINDOW" | jq -r '.size[1]')
    MONITOR_ID=$(echo "$WINDOW" | jq -r '.monitor')
    
    # Get monitor dimensions
    MONITOR=$(hyprctl monitors -j | jq -r ".[] | select(.id == $MONITOR_ID)")
    M_WIDTH=$(echo "$MONITOR" | jq -r '.width')
    M_HEIGHT=$(echo "$MONITOR" | jq -r '.height')
    
    # Thresholds (50% width, 60% height)
    T_WIDTH=$(( M_WIDTH * 50 / 100 ))
    T_HEIGHT=$(( M_HEIGHT * 60 / 100 ))
    
    # Calculate new dimensions
    RESIZE_W=$W_WIDTH
    RESIZE_H=$W_HEIGHT
    MODIFIED=0

    if [ "$W_WIDTH" -gt "$T_WIDTH" ]; then
        RESIZE_W=$T_WIDTH
        MODIFIED=1
    fi
    
    if [ "$W_HEIGHT" -gt "$T_HEIGHT" ]; then
        RESIZE_H=$T_HEIGHT
        MODIFIED=1
    fi
    
    # Apply resize if hitting the thresholds
    if [ "$MODIFIED" -eq 1 ]; then
        hyprctl dispatch resizeactive exact $RESIZE_W $RESIZE_H
        hyprctl dispatch centerwindow
    fi
else
    hyprctl dispatch togglefloating
fi
