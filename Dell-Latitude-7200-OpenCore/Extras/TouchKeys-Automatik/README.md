# TouchKeys-Automatik (optional)

Startet **TouchKeys** (aus [TouchDeck](https://www.whiteoakmedia.io/tools/touchdeck)) automatisch, wenn weder das Tastatur-Dock noch eine externe Tastatur angeschlossen ist, und beendet es wieder, sobald eine Tastatur dran ist. Prüfung alle 3 Sekunden über den LaunchAgent `com.latitude7200.touchkeys-auto`.

- Voraussetzung: `/Applications/TouchKeys.app` (nur TouchKeys, **nicht** den Treiber „Touch Up“ benutzen).
- Installieren: `installieren.command` per Rechtsklick → „Öffnen“.
- Fehlersuche: `~/Library/Scripts/touchkeys-auto.sh liste`
- Entfernen: `deinstallieren.command` per Rechtsklick → „Öffnen“.

Details: siehe Haupt-README, Abschnitt „Optional: Touch / Tablet-Modus“.

*English:* Starts TouchKeys only when no keyboard dock ("Alps Touchpad" HID device) or external keyboard is connected. Install with right-click → Open on `installieren.command`, remove with `deinstallieren.command`.
