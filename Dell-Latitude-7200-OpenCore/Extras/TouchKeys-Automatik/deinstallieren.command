#!/bin/bash
launchctl bootout gui/$(id -u)/com.latitude7200.touchkeys-auto 2>/dev/null
rm -f "$HOME/Library/LaunchAgents/com.latitude7200.touchkeys-auto.plist" "$HOME/Library/Scripts/touchkeys-auto.sh"
echo "Entfernt."
