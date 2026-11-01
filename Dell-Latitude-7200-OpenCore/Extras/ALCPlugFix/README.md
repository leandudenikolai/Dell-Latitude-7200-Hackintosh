# ALCPlugFix für den Kopfhöreranschluss (ALC295/ALC3254)

Die Lautsprecher laufen direkt mit AppleALC (Layout-ID 77). Der Kopfhöreranschluss (Combo-Jack) braucht zusätzlich **[ALCPlugFix-Swift](https://github.com/black-dragon74/ALCPlugFix-Swift)** von black-dragon74. Es schickt beim Einstecken einen HDA-Befehl an den Audio-Chip.

Quelle für die Werte: [AppleBreak1, Dell Latitude 7210 2-in-1](https://github.com/AppleBreak1/Dell-Latitude-7210-2-in-1-Hackintosh) (Layout-ID 77, `alc-verbs <01000000>`, Node ID 0x19, Param 20).

## Inhalt
- `alc295-verbs.plist`: Node `0x19`, `SET_PIN_WIDGET_CONTROL`, Param `0x20`, gesendet beim Einstecken, beim Start und nach dem Aufwachen
- `com.black-dragon74.ALCPlugFix.plist`: LaunchDaemon, Log unter `/var/log/alcplugfix.log`
- `install.command` / `uninstall.command`

Die Programmdatei selbst liegt **nicht** im Repo. `install.command` lädt `ALCPlugFix-Swift-RELEASE-1.5.zip` vom offiziellen GitHub-Release und prüft die SHA-256-Prüfsumme. Wer offline installieren will, legt die Datei `ALCPlugFix-Swift` aus dem Release neben `install.command`.

## Voraussetzungen
In der config unter `DeviceProperties → PciRoot(0x0)/Pci(0x1F,0x3)` müssen `layout-id` = `4D000000` (77) und `alc-verbs` = `01000000` stehen. Das ist in allen configs dieses Repos schon so. Ohne `alc-verbs` (oder den boot-arg `alcverbs=1`) lässt AppleALC keine Befehle von ALCPlugFix zu.

SIP muss **nicht** abgeschaltet werden (`/usr/local/bin` und `/Library/LaunchDaemons` sind nicht SIP-geschützt).

## Installieren
`install.command` per **Rechtsklick → „Öffnen“** starten, Passwort eingeben, dann Kopfhörer aus- und wieder einstecken.

## Prüfen
```
sudo launchctl print system/com.black-dragon74.ALCPlugFix | grep state
ioreg -l | grep -E '"layout-id"|"alc-verbs"'
sudo cat /var/log/alcplugfix.log
```

## Wenn es nicht geht
- `Param` in `/usr/local/share/ALCPlugFix/alc295-verbs.plist` auf `0x24` ändern (Wert aus der Beispieldatei von ALCPlugFix-Swift), dann `sudo launchctl kickstart -k system/com.black-dragon74.ALCPlugFix`.
- Eine andere Layout-ID per boot-arg testen, z. B. `alcid=33` (AppleALC: „Dell Latitude 7210 2-in-1“), `alcid=13` oder `alcid=3`. `alcid` überschreibt die `layout-id`.

## Entfernen
`uninstall.command` per Rechtsklick → „Öffnen“.
