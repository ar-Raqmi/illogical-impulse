#!/usr/bin/env bash

ADDR=$(hyprctl activewindow -j | jq -r '.address')
hyprctl keyword scrolling:focus_fit_method 0
sleep 0.05
hyprctl dispatch focuswindow "address:$ADDR"
sleep 0.05
hyprctl keyword scrolling:focus_fit_method 1
