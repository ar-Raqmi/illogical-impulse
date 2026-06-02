#!/bin/bash

TARGET_DIR="$HOME/Applications"

rm -rf "$TARGET_DIR"
mkdir -p "$TARGET_DIR"

for f in /usr/share/applications/*.desktop ~/.local/share/applications/*.desktop; do
    if [ -f "$f" ]; then
        if ! grep -q "NoDisplay=true" "$f"; then
            APP_NAME=$(grep -m 1 "^Name=" "$f" | cut -d= -f2-)
            APP_NAME=$(echo "$APP_NAME" | tr '/' '-')
            cp "$f" "$TARGET_DIR/$APP_NAME" 2>/dev/null
            chmod +x "$TARGET_DIR/$APP_NAME"
        fi
    fi
done
