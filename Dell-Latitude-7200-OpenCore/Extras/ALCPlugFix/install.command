#!/bin/bash
# ALCPlugFix-Swift Installer fuer Dell Latitude 7200 2-in-1 (ALC295/ALC3254, Layout-ID 77)
# ALCPlugFix-Swift (c) black-dragon74: https://github.com/black-dragon74/ALCPlugFix-Swift
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
cd "$DIR" || exit 1
LABEL=com.black-dragon74.ALCPlugFix
REL_URL="https://github.com/black-dragon74/ALCPlugFix-Swift/releases/download/1.5/ALCPlugFix-Swift-RELEASE-1.5.zip"
REL_SHA="cac9beb330b39ceb0e55a06c3391eeabcf965eca26c7504177fe9d4038e8bd00"

abort() { echo; echo "FEHLER: $1"; echo; read -n1 -p "Taste druecken zum Schliessen..."; exit 1; }

echo "=== ALCPlugFix (AppleALC-Variante) fuer ALC295 installieren ==="
echo

# 1) Pruefen, ob AppleALC die Verbs erlaubt (alc-verbs / alcverbs=1)
if ! ioreg -r -c ALCUserClientProvider 2>/dev/null | grep -q ALCUserClientProvider; then
  echo "Warnung: ALCUserClientProvider (AppleALC) wurde nicht gefunden."
  echo "Ist die neue config.plist mit alc-verbs schon aktiv und wurde neu gestartet?"
fi
if ! ioreg -l 2>/dev/null | grep -q '"alc-verbs"' && ! nvram boot-args 2>/dev/null | grep -q 'alcverbs=1'; then
  echo "Warnung: weder alc-verbs (DeviceProperties) noch alcverbs=1 gefunden."
  echo "Ohne das darf ALCPlugFix keine Befehle an den Audio-Chip schicken."
fi
echo "Aktuelle Layout-ID:"; ioreg -l 2>/dev/null | grep -m1 '"layout-id"' || echo "  (nicht gefunden)"
echo

# 2) Programmdatei holen (liegt bei oder wird vom offiziellen Release geladen)
BIN="$DIR/ALCPlugFix-Swift"
if [ ! -f "$BIN" ]; then
  echo "Lade ALCPlugFix-Swift 1.5 vom offiziellen GitHub-Release ..."
  TMP=$(mktemp -d)
  curl -fsSL -o "$TMP/apf.zip" "$REL_URL" || abort "Download fehlgeschlagen."
  SUM=$(shasum -a 256 "$TMP/apf.zip" | awk '{print $1}')
  [ "$SUM" = "$REL_SHA" ] || abort "Pruefsumme stimmt nicht ($SUM)."
  unzip -q -o "$TMP/apf.zip" -d "$TMP" || abort "Entpacken fehlgeschlagen."
  BIN="$TMP/ALCPlugFix-Swift"
  [ -f "$BIN" ] || abort "ALCPlugFix-Swift nicht im Archiv gefunden."
fi
plutil -lint "$DIR/alc295-verbs.plist" >/dev/null || abort "alc295-verbs.plist ist ungueltig."

echo "Fuer die Installation wird dein Passwort gebraucht (sudo)."
sudo -v || abort "sudo abgebrochen."

# 3) Alte Installationen entfernen
for p in /Library/LaunchAgents/good.win.ALCPlugFix.plist /Library/LaunchAgents/$LABEL.plist /Library/LaunchDaemons/$LABEL.plist; do
  if [ -f "$p" ]; then sudo launchctl bootout system "$p" 2>/dev/null; sudo launchctl unload "$p" 2>/dev/null; sudo rm -f "$p"; fi
done

# 4) Dateien kopieren
sudo mkdir -p /usr/local/bin /usr/local/share/ALCPlugFix || abort "Ordner anlegen fehlgeschlagen."
sudo cp "$BIN" /usr/local/bin/ALCPlugFix || abort "Kopieren von ALCPlugFix fehlgeschlagen."
sudo cp "$DIR/alc295-verbs.plist" /usr/local/share/ALCPlugFix/alc295-verbs.plist || abort "Kopieren der Verbs fehlgeschlagen."
sudo cp "$DIR/$LABEL.plist" /Library/LaunchDaemons/$LABEL.plist || abort "Kopieren des LaunchDaemon fehlgeschlagen."
sudo xattr -c /usr/local/bin/ALCPlugFix /usr/local/share/ALCPlugFix/alc295-verbs.plist /Library/LaunchDaemons/$LABEL.plist 2>/dev/null
sudo chown root:wheel /usr/local/bin/ALCPlugFix /usr/local/share/ALCPlugFix/alc295-verbs.plist /Library/LaunchDaemons/$LABEL.plist
sudo chmod 755 /usr/local/bin/ALCPlugFix
sudo chmod 644 /usr/local/share/ALCPlugFix/alc295-verbs.plist /Library/LaunchDaemons/$LABEL.plist

# 5) Starten
sudo launchctl bootstrap system /Library/LaunchDaemons/$LABEL.plist 2>/dev/null || sudo launchctl load -w /Library/LaunchDaemons/$LABEL.plist
sleep 2
echo
if sudo launchctl print system/$LABEL 2>/dev/null | grep -q "state = running"; then
  echo "ALCPlugFix laeuft."
else
  echo "ALCPlugFix laeuft (noch) nicht. Log:"; sudo tail -n 10 /var/log/alcplugfix.log 2>/dev/null
fi
echo
echo "Fertig. Jetzt Kopfhoerer ab- und wieder anstecken und testen."
read -n1 -p "Taste druecken zum Schliessen..."
