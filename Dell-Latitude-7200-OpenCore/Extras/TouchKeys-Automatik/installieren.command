#!/bin/bash
# Installiert die TouchKeys-Automatik: TouchKeys läuft nur, wenn keine Tastatur angeschlossen ist.
set -e
if [ ! -d "/Applications/TouchKeys.app" ]; then
  echo "Hinweis: /Applications/TouchKeys.app nicht gefunden. Bitte TouchKeys (aus TouchDeck) nach /Applications installieren."
fi
mkdir -p "$HOME/Library/Scripts" "$HOME/Library/LaunchAgents"

cat > "$HOME/Library/Scripts/touchkeys-auto.sh" <<'SKRIPT'
#!/bin/bash
APP="TouchKeys"
# Geräte mit diesen Namen zählen NICHT als Tastatur (bei Bedarf ergänzen, mit | trennen)
IGNORIEREN="VoodooI2C|ELAN|Wacom|Touch|Pen|ControlVault|58200|Webcam|Camera|Virtual|PS2|Apple Internal|^Keyboard$"

tastaturen() {
  ioreg -r -c IOHIDDevice -k PrimaryUsage -d 1 | awk '
    /\+-o/ {if (p==1 && u==6) print name; p=0; u=0; name="(ohne Namen)"}
    /"PrimaryUsagePage" = / {split($0,a,"= "); p=a[2]+0}
    /"PrimaryUsage" = /     {split($0,a,"= "); u=a[2]+0}
    /"Product" = /          {split($0,a,"\""); name=a[4]}
    END {if (p==1 && u==6) print name}'
}

if [ "$1" = "liste" ]; then tastaturen; exit 0; fi

while true; do
  # Dock erkannt am "Alps Touchpad" + echte externe Tastaturen (USB/Bluetooth)
  DOCK=$(ioreg -r -c IOHIDDevice -d 1 | grep -c '"Product" = "Alps Touchpad"' || true)
  EXTERN=$(tastaturen | grep -viE "$IGNORIEREN" | grep -c . || true)
  ANZAHL=$(( ${DOCK:-0} + ${EXTERN:-0} ))
  if [ "${ANZAHL:-0}" -gt 0 ]; then
    pgrep -xq "$APP" && osascript -e "quit app \"$APP\"" >/dev/null 2>&1
  else
    pgrep -xq "$APP" || open -ga "$APP" >/dev/null 2>&1
  fi
  sleep 3
done
SKRIPT
chmod +x "$HOME/Library/Scripts/touchkeys-auto.sh"

cat > "$HOME/Library/LaunchAgents/com.latitude7200.touchkeys-auto.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>Label</key><string>com.latitude7200.touchkeys-auto</string>
<key>ProgramArguments</key><array><string>/bin/bash</string><string>$HOME/Library/Scripts/touchkeys-auto.sh</string></array>
<key>RunAtLoad</key><true/><key>KeepAlive</key><true/>
</dict></plist>
PLIST
launchctl bootout gui/$(id -u)/com.latitude7200.touchkeys-auto 2>/dev/null || true
launchctl bootstrap gui/$(id -u) "$HOME/Library/LaunchAgents/com.latitude7200.touchkeys-auto.plist"
echo "Fertig! TouchKeys läuft jetzt nur noch, wenn keine Tastatur angeschlossen ist."
echo ""
echo "Gerade erkannte Tastaturen:"
"$HOME/Library/Scripts/touchkeys-auto.sh" liste
