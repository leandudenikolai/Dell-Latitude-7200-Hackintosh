#!/bin/bash
# Entfernt ALCPlugFix-Swift wieder
LABEL=com.black-dragon74.ALCPlugFix
echo "=== ALCPlugFix entfernen ==="
echo "Dafuer wird dein Passwort gebraucht (sudo)."
sudo -v || exit 1
for p in /Library/LaunchAgents/good.win.ALCPlugFix.plist /Library/LaunchAgents/$LABEL.plist /Library/LaunchDaemons/$LABEL.plist; do
  if [ -f "$p" ]; then sudo launchctl bootout system "$p" 2>/dev/null; sudo launchctl unload "$p" 2>/dev/null; sudo rm -f "$p"; fi
done
sudo rm -f /usr/local/bin/ALCPlugFix /var/log/alcplugfix.log
sudo rm -rf /usr/local/share/ALCPlugFix
echo "ALCPlugFix ist entfernt."
read -n1 -p "Taste druecken zum Schliessen..."
