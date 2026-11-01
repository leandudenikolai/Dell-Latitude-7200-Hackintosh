# Dell Latitude 7200 2-in-1 – OpenCore EFI (macOS Sequoia)

OpenCore-EFI für das **Dell Latitude 7200 2-in-1**. Damit läuft macOS Sequoia mit Grafikbeschleunigung, WLAN, Bluetooth, Ruhezustand, Touch, Ton und Akkuanzeige.

> ⚠️ **Wichtig:** In dieser EFI sind **keine Seriennummern** eingetragen (`SystemSerialNumber`, `MLB`, `SystemUUID` und `ROM` sind leer). Jeder muss sich **eigene** SMBIOS-Daten erzeugen, siehe [Schritt 3](#3-eigene-smbios-daten-erzeugen-pflicht). Ohne eigene Daten funktionieren Apple-Account, iCloud, iMessage und FaceTime nicht richtig.

> ⚠️ **Keine Garantie.** Benutzung auf eigene Gefahr. Mach vorher ein Backup deiner Daten. Die EFI wurde auf **einem** Gerät (Konfiguration siehe unten) getestet.

🇬🇧 **English summary:** see [below](#english).

---

## Inhalt

- [Hardware](#hardware)
- [Was geht, was nicht](#was-geht-was-nicht)
- [Versionen](#versionen)
- [Aufbau der EFI](#aufbau-der-efi)
- [BIOS-Einstellungen](#bios-einstellungen)
- [Installation Schritt für Schritt](#installation-schritt-für-schritt)
- [Nach der Installation](#nach-der-installation)
- [Kopfhöreranschluss (ALCPlugFix)](#kopfhöreranschluss-alcplugfix)
- [Optional: Touch / Tablet-Modus](#optional-touch--tablet-modus)
- [Zweites Gerät / System klonen](#zweites-gerät--system-klonen)
- [Fehlerbehebung](#fehlerbehebung)
- [USB-Map](#usb-map)
- [Updates](#updates)
- [Credits](#credits)
- [Lizenzen](#lizenzen)
- [English](#english)

---

## Hardware

| Komponente | Getestetes Gerät |
|---|---|
| Modell | Dell Latitude 7200 2-in-1 |
| CPU | Intel Core i7-8665U (Whiskey Lake) |
| Grafik | Intel UHD Graphics 620 |
| RAM | 16 GB |
| SSD | M.2 2230 NVMe |
| Display | 12,3", 1920 × 1280, Touch und Stift |
| WLAN/Bluetooth | Intel (über itlwm / IntelBluetoothFirmware) |
| Audio | Realtek ALC3254 (ALC295), Layout-ID 77 (`layout-id` + `alc-verbs` in DeviceProperties) |
| BIOS | 1.39.0 |
| macOS | Sequoia 15.8.2 |
| SMBIOS | MacBookPro16,3 |

## Was geht, was nicht

**✅ Funktioniert**
- Grafik mit voller Beschleunigung (Metal 3), externer Monitor auch über Dell-Dock bzw. USB-C
- WLAN (itlwm + HeliPort-App)
- Bluetooth
- Ruhezustand (Sleep) und Aufwachen, über Menü und Deckel
- Touchscreen
- Ton über die Lautsprecher
- Kopfhöreranschluss: nur mit [ALCPlugFix](#kopfhöreranschluss-alcplugfix) (noch nicht auf dem 7200 getestet)
- Akkuanzeige
- Alle USB-Ports inkl. beider USB-C-Ports (eigene USB-Map)
- CPU-Taktung (XCPM, mit CPUFriend etwas sparsamer im Leerlauf)
- iCloud/Apple-Account (mit **eigener**, gültig erzeugter SMBIOS)

**❌ Funktioniert nicht**
- **AirDrop, Handoff, Sidecar, Universelle Zwischenablage, Continuity:** geht mit der Intel-WLAN-Karte grundsätzlich nicht. Dafür braucht man eine Broadcom-Karte (z. B. BCM94360NG oder DW1820A) und eine angepasste EFI.
- **Fingerabdruckleser**
- **WWAN/LTE-Modem**
- **SD-Kartenleser**
- „Wo ist?“ im Ruhezustand (wegen `tcpkeepalive 0`, siehe unten)

**❔ Nicht ausdrücklich getestet:** Kameras, Stift, Helligkeitstasten, Mikrofon, Thunderbolt-PCIe-Geräte.

## Versionen

| Komponente | Version |
|---|---|
| OpenCore | 1.0.8 (RELEASE) |
| Lilu | 1.7.2 |
| VirtualSMC / SMCBatteryManager / SMCProcessor | 1.3.8 |
| WhateverGreen | 1.7.1 |
| AppleALC | 1.9.8 |
| CPUFriend | 1.3.0 |
| CPUFriendDataProvider | 1.0.1 (für dieses Gerät erzeugt, siehe unten) |
| ECEnabler | 1.0.6 |
| NVMeFix | 1.1.3 |
| USBToolBox | 1.2.0 |
| UTBMap (USB-Map für dieses Gerät) | 1.1 |
| UTBDefault (nur für die VESA-Notfall-config) | 1.0 |
| VoodooPS2Controller | 2.3.7 |
| VoodooI2C | 2.9.1 (VoodooI2CHID 1.0) |
| itlwm | 2.3.0 |
| IntelBluetoothFirmware / IntelBTPatcher | 2.4.0 |
| BlueToolFixup (BrcmPatchRAM) | 2.7.2 |

Die Versionen stammen aus den `Info.plist`-Dateien der Kexts.

## Aufbau der EFI

```
EFI/
├── BOOT/BOOTx64.efi
└── OC/
    ├── ACPI/         SSDT-AWAC, SSDT-EC-USBX-LAPTOP, SSDT-GPRW, SSDT-PLUG-DRTNIA,
    │                 SSDT-PMC, SSDT-PNLF, SSDT-XOSI
    ├── Drivers/      OpenRuntime, OpenHfsPlus, ResetNvramEntry, (OpenUsbKbDxe, deaktiviert)
    ├── Kexts/
    ├── Tools/        OpenShell, ControlMsrE2
    ├── OpenCore.efi
    ├── config.plist                ← normaler Betrieb
    ├── config-installation.plist   ← für die Installation
    └── config-vesa-fallback.plist  ← Notfall, falls der Installer hängt
Extras/
└── TouchKeys-Automatik/   ← optional, siehe „Touch / Tablet-Modus“
```

| Datei | Wofür |
|---|---|
| `config.plist` | **Normaler Betrieb.** Startet direkt macOS, ohne Auswahlmenü und ohne Text. Mit USB-Map, Sleep-Fix (SSDT-GPRW) und CPUFriend. |
| `config-installation.plist` | Gleich wie `config.plist`, aber mit **Auswahlmenü** (10 Sekunden) und **Verbose-Modus** (`-v debug=0x100 keepsyms=1`). Für die Installation und zur Fehlersuche. |
| `config-vesa-fallback.plist` | **Notfall:** Grafik ohne Beschleunigung (`-igfxvesa`), allgemeine USB-Einstellung (UTBDefault), ohne CPUFriend und Sleep-Fix, mit Auswahlmenü und Verbose. Nur zum Installieren benutzen, wenn der Installer mit den anderen configs hängt. |

OpenCore lädt **immer nur** die Datei mit dem Namen `config.plist`. Zum Wechseln die gewünschte Datei also in `config.plist` umbenennen (vorher die alte umbenennen, z. B. in `config-normal.plist`).

## BIOS-Einstellungen

Ins BIOS kommst du mit **F2** beim Dell-Logo, ins einmalige Bootmenü mit **F12**. Tipp: Zuerst „Restore Settings → BIOS Defaults“, dann die Liste abarbeiten und mit „Apply“ speichern. Punkte, die es bei dir nicht gibt, einfach ignorieren.

**Pflicht**

| Menü | Einstellung | Wert |
|---|---|---|
| Secure Boot | Secure Boot Enable | **aus** |
| General → Advanced Boot Options | Enable Legacy Option ROMs / Attempt Legacy Boot | **aus** |
| System Configuration → USB Configuration | Enable USB Boot Support, Enable External USB Port | **an** |
| System Configuration → Drives | M.2 PCIe SSD-0 | **an** |
| System Configuration → Audio | Enable Audio, Microphone, Internal Speaker | **an** |
| System Configuration | Touchscreen | **an** |
| Wireless → Wireless Device Enable | WLAN, Bluetooth | **an** |
| Performance | Multi Core Support **All**, SpeedStep **an**, C-States **an**, Turbo Boost **an**, HyperThreading **an** | |
| Power Management | Enable Intel Speed Shift Technology | **an** |

**Empfohlen**

| Menü | Einstellung | Wert |
|---|---|---|
| Intel Software Guard Extensions | Intel SGX | **Disabled** |
| Virtualization Support | VT for Direct I/O (VT-d) | **aus** (die config setzt zusätzlich `DisableIoMapper`) |
| Virtualization Support | Trusted Execution | aus |
| POST Behavior | **Sign of Life Indication** | **alle Haken aus** (Audio, Display, Keyboard Backlight). Sonst kann das Gerät nach dem Ruhezustand am Dell-Logo hängen bleiben. |
| Power Management | Wake on AC, Wake on Dell USB-C Dock, Wake on LAN/WLAN, Auto On Time | **aus** |
| System Configuration → Thunderbolt Adapter Configuration | Security Level | **No Security** (Thunderbolt-Geräte lassen sich unter macOS sonst nicht freigeben) |
| System Configuration → Thunderbolt Adapter Configuration | Enable Thunderbolt Boot Support | **an** |
| SupportAssist System Resolution | Auto OS Recovery Threshold **OFF**, SupportAssist OS Recovery **aus**, BIOSConnect **aus** | |
| Security | Absolute | **niemals** „Permanently Disabled“ wählen |
| General | Date/Time | aktuelle Zeit (sonst „beschädigt“-Fehler im Installer) |

**Optional (spart Strom bzw. Startzeit)**

| Menü | Einstellung | Wert |
|---|---|---|
| Miscellaneous Devices | SD Card | aus (geht unter macOS nicht, und die CPU erreicht sonst nicht die tiefsten Stromsparstufen) |
| Wireless / System Configuration | WWAN/GPS, NFC/Smartcard, Fingerprint Reader | aus (geht unter macOS nicht) |
| Miscellaneous Devices | World-Facing Camera (Rückkamera) | aus, wenn nicht benötigt |
| General → Advanced Boot Options | Enable UEFI Network Stack | aus (schnellerer Start) |
| Security | UEFI Capsule Firmware Updates | aus (verhindert ungeplante BIOS-Updates) |
| POST Behavior | Fastboot | „Thorough“ ist am sichersten. „Minimal“ startet schneller; wenn danach Tastatur oder USB-Stick im OpenCore-Menü nicht mehr gehen, zurück auf „Thorough“. |

> Einen „SATA Operation/AHCI“-Schalter gibt es bei diesem Gerät nicht. Die NVMe-SSD wird von macOS direkt erkannt.

## Installation Schritt für Schritt

### 1. USB-Stick erstellen (mind. 16 GB)

**Unter macOS** (vollständiger Installer, kein Internet bei der Installation nötig):
1. „macOS Sequoia installieren“ aus dem App Store laden.
2. Den Stick im Festplattendienstprogramm als **Mac OS Extended (Journaled)** mit **GUID-Partitionstabelle** löschen, Name z. B. `MyVolume`.
3. Im Terminal:
   ```
   sudo /Applications/Install\ macOS\ Sequoia.app/Contents/Resources/createinstallmedia --volume /Volumes/MyVolume
   ```

**Unter Windows oder Linux** (Recovery-Image, lädt macOS während der Installation aus dem Internet):
1. [OpenCorePkg](https://github.com/acidanthera/OpenCorePkg/releases) (RELEASE) herunterladen und entpacken. Python 3 muss installiert sein.
2. In `Utilities/macrecovery` ein Terminal öffnen und ausführen:
   ```
   python3 macrecovery.py -b Mac-937A206F2EE63C01 -m 00000000000000000 download
   ```
3. Den Stick mit **GPT** und **FAT32** formatieren.
4. Den entstandenen Ordner `com.apple.recovery.boot` auf den Stick kopieren.

Ausführliche Anleitung: [Dortania – Creating the USB](https://dortania.github.io/OpenCore-Install-Guide/installer-guide/).

### 2. EFI auf den Stick kopieren

- **Windows/Linux-Stick (FAT32):** Den Ordner `EFI` aus diesem Repo direkt ins Hauptverzeichnis des Sticks kopieren.
- **macOS-Stick (createinstallmedia):** Die EFI-Partition des Sticks einhängen und den Ordner `EFI` hineinkopieren:
  ```
  diskutil list                       # Stick suchen, z. B. disk4
  sudo diskutil mount disk4s1         # EFI-Partition des Sticks einhängen
  ```

### 3. Eigene SMBIOS-Daten erzeugen (Pflicht)

1. [GenSMBIOS](https://github.com/corpnewt/GenSMBIOS) herunterladen und starten (`GenSMBIOS.command` unter macOS, `GenSMBIOS.bat` unter Windows, `GenSMBIOS.py` unter Linux).
2. Bei Bedarf zuerst „Install/Update MacSerial“ wählen, dann „Generate SMBIOS“ und als Modell **`MacBookPro16,3`** eingeben.
3. Du bekommst **Serial**, **Board Serial** und **SmUUID**.
4. `EFI/OC/config-installation.plist` (und später auch `config.plist`) mit [ProperTree](https://github.com/corpnewt/ProperTree), [OCAuxiliaryTools](https://github.com/ic005k/OCAuxiliaryTools) oder OpenCore Configurator öffnen (Editor-Version passend zu OpenCore 1.0.8 verwenden) und unter **PlatformInfo → Generic** eintragen:

   | Feld in der config | Wert |
   |---|---|
   | `SystemSerialNumber` | Serial |
   | `MLB` | Board Serial |
   | `SystemUUID` | SmUUID |
   | `ROM` | MAC-Adresse der Netzwerkkarte **ohne Doppelpunkte** als Daten (12 Hex-Zeichen, z. B. `112233AABBCC`). Das Gerät hat kein LAN, nimm also die WLAN-MAC (steht auf dem Typenschild bzw. später unter macOS in HeliPort / `ifconfig en0`) oder 6 zufällige Bytes. |

   `SystemProductName` bleibt `MacBookPro16,3`.
5. Die Seriennummer auf [checkcoverage.apple.com](https://checkcoverage.apple.com) prüfen. **Gut** ist die Meldung, dass die Seriennummer ungültig ist bzw. nicht erkannt wird. Zeigt die Seite ein Kaufdatum oder eine Garantie an, gehört die Nummer einem echten Mac: dann eine neue erzeugen.
6. **Dieselben Werte in alle configs eintragen**, die du benutzt. Nie dieselben Werte auf zwei Geräten verwenden.

> Tipp: Du kannst auch ohne eigene Nummern installieren. Dann darfst du dich aber **erst** mit dem Apple-Account anmelden, wenn die eigenen Nummern eingetragen sind und du einmal neu gestartet hast.

### 4. Installations-config aktivieren

Auf dem **Stick** in `EFI/OC`:
1. `config.plist` umbenennen in `config-normal.plist`.
2. `config-installation.plist` umbenennen in **`config.plist`**.

So siehst du beim Installieren das Auswahlmenü und den Text, und bei Problemen sieht man, wo es hängt.

### 5. macOS installieren

1. Stick in den **USB-A-Port** stecken, einschalten und **F12** drücken, dann den Stick (UEFI) auswählen.
2. Im OpenCore-Menü den Installer wählen („Install macOS Sequoia“ bzw. „macOS Base System“ beim Recovery-Stick).
3. Im Installer das **Festplattendienstprogramm** öffnen, oben **Darstellung → „Alle Geräte einblenden“**, die ganze SSD auswählen und als **APFS** mit **GUID-Partitionstabelle** löschen (Name z. B. `Macintosh HD`). **Achtung: Dabei wird alles auf der SSD gelöscht.**
4. macOS auf „Macintosh HD“ installieren.
5. Der Laptop startet mehrmals neu. Im OpenCore-Menü jedes Mal **„macOS Installer“** wählen, solange es diesen Eintrag gibt, danach **„Macintosh HD“**.
6. Bei der Einrichtung **nicht** mit dem Apple-Account anmelden, falls du noch keine eigenen SMBIOS-Daten eingetragen hast (siehe Schritt 3).

### 6. EFI auf die SSD kopieren (damit es ohne Stick startet)

1. In macOS das Terminal öffnen:
   ```
   diskutil list                  # interne SSD suchen, meist disk0
   sudo diskutil mount disk0s1    # EFI-Partition der SSD einhängen
   ```
2. Den Ordner `EFI` vom Stick auf die EFI-Partition der SSD kopieren (`/Volumes/EFI`).
3. Dort in `EFI/OC` die **normale** `config.plist` (aus dem Repo bzw. `config-normal.plist`) verwenden – **mit deinen eigenen SMBIOS-Daten**.
4. Neu starten (ohne Stick). Falls das BIOS die SSD nicht von selbst startet: im BIOS unter **General → Boot Sequence → Add Boot Option** einen Eintrag auf `\EFI\BOOT\BOOTx64.efi` der SSD anlegen und an die erste Stelle setzen.

### 7. NVRAM zurücksetzen

Nach dem Wechsel auf die normale config einmal das NVRAM zurücksetzen: Beim Start **Esc** gedrückt halten (das Auswahlmenü erscheint), dann **„Reset NVRAM“** wählen. Das ist für Bluetooth wichtig.

## Nach der Installation

### WLAN: HeliPort
Die EFI benutzt `itlwm.kext`. Dazu brauchst du die App **HeliPort**:
1. Die aktuelle Version von [OpenIntelWireless/HeliPort Releases](https://github.com/OpenIntelWireless/HeliPort/releases) herunterladen und nach „Programme“ ziehen.
2. Starten und dein WLAN auswählen.
3. In HeliPort „Beim Anmelden starten“ (Launch at Login) aktivieren oder unter **Systemeinstellungen → Allgemein → Anmeldeobjekte** hinzufügen.

Optional: Das normale WLAN-Symbol in der Menüleiste ausblenden (Systemeinstellungen → Kontrollzentrum → WLAN → „Nicht in der Menüleiste anzeigen“).

### Ruhezustand und Energie einstellen
Einmal im Terminal ausführen (alles auf einmal kopieren):
```
sudo pmset -a hibernatemode 0; sudo pmset -a standby 0; sudo pmset -a autopoweroff 0; sudo pmset -a powernap 0; sudo pmset -a proximitywake 0; sudo pmset -a tcpkeepalive 0; sudo rm -f /var/vm/sleepimage
sudo pmset -a displaysleep 10 sleep 10
```

| Befehl | Warum |
|---|---|
| `hibernatemode 0`, `standby 0`, `autopoweroff 0` | Kein Ruhezustand auf die SSD („Hibernate“). Das funktioniert auf Hackintosh-Laptops nicht zuverlässig. |
| `rm -f /var/vm/sleepimage` | Löscht das dann nicht mehr benötigte Hibernate-Abbild (spart Speicherplatz). |
| `powernap 0`, `proximitywake 0`, `tcpkeepalive 0` | Verhindert ungewolltes Aufwachen im Ruhezustand. |
| `displaysleep 10 sleep 10` | **Wichtig:** Bildschirm und System schlafen **gleichzeitig** ein (hier nach 10 Minuten, Zahl nach Wunsch). |

**Warum `displaysleep` = `sleep`?** Beim automatischen Ruhezustand im Leerlauf ist der Laptop abgestürzt, wenn macOS zuerst nur den Bildschirm ausgeschaltet hat und das System erst später schlafen gegangen ist. Gehen Bildschirm und System gleichzeitig schlafen, funktioniert es. Deckel zuklappen und Ruhezustand über das Menü gingen schon vorher, weil dabei beides auf einmal passiert.

> Hinweis: Mit `tcpkeepalive 0` findet „Wo ist?“ den Mac im Ruhezustand nicht. Die Warnung, die `pmset` dabei anzeigt, ist harmlos.

Optional: Soll der Laptop beim Aufklappen **nicht** von selbst aufwachen, `sudo pmset -a lidwake 0` (zurück mit `lidwake 1`).

Aktuelle Werte anzeigen: `pmset -g`

### Empfohlene Einstellungen
- **Akku in Prozent:** Systemeinstellungen → Kontrollzentrum → Batterie → „Prozentangabe anzeigen“, oder fest per Terminal:
  ```
  defaults -currentHost write com.apple.controlcenter BatteryShowPercentage -bool true; killall ControlCenter
  ```
- **WLAN-Symbol ausblenden:** Systemeinstellungen → Kontrollzentrum → WLAN → „Nicht in der Menüleiste anzeigen“. Das WLAN zeigt HeliPort in der Menüleiste an.
- **HeliPort in die Anmeldeobjekte:** Systemeinstellungen → Allgemein → Anmeldeobjekte → „+“ → HeliPort, damit das WLAN nach jedem Start verbindet.
- **Tastaturlayout im Boot:** In den configs steht unter NVRAM `prev-lang:kbd = de-DE:3` (Deutsch). Für Englisch z. B. auf `en-US:0` ändern oder den Eintrag löschen.

> Die Kontrollzentrum-Einstellungen speichert macOS **pro Gerät** (anhand der Hardware-UUID). Bleiben sie nach einem Neustart nicht erhalten, siehe [Fehlerbehebung](#fehlerbehebung).

### CPUFriend (sparsamere CPU-Taktung)
`CPUFriendDataProvider.kext` wurde für **MacBookPro16,3** aus Apples originalem Energieprofil (der Original-plist von macOS) erzeugt. Geändert sind nur:
- **LFM 800 MHz** (niedrigster Takt im Leerlauf, statt 1200 MHz) und
- **EPP `0x90`** (Energy Performance Preference, etwas stromsparender).

Unter Last taktet die CPU weiterhin voll hoch. Prüfen, ob beide Kexts geladen sind:
```
kmutil showloaded | grep -i cpufriend
```
Es sollten zwei Zeilen erscheinen (`CPUFriend` und `CPUFriendDataProvider`). Den aktuellen Takt zeigt `sudo powermetrics --samplers cpu_power -i 1000 -n 5`.

Wichtig: Nur die Kexts in den Ordner `Kexts` zu legen reicht nicht. OpenCore lädt nur Kexts, die in der `config.plist` unter Kernel → Add eingetragen sind (hier direkt nach `SMCProcessor.kext`).

### Kontrollieren
```
sysctl machdep.xcpm.mode                         # 1 = CPU-Taktung läuft
kmutil showloaded 2>/dev/null | grep -i cpufriend # CPUFriend geladen?
system_profiler SPDisplaysDataType | grep -i metal
system_profiler SPHardwareDataType | grep UUID   # muss nach jedem Neustart gleich bleiben
```

## Kopfhöreranschluss (ALCPlugFix)

Die Lautsprecher laufen direkt mit AppleALC. Der Kopfhöreranschluss (Combo-Jack) des ALC295/ALC3254 braucht zusätzlich **[ALCPlugFix-Swift](https://github.com/black-dragon74/ALCPlugFix-Swift)**. Die Werte stammen aus dem Repo von [AppleBreak1 (Latitude 7210 2-in-1)](https://github.com/AppleBreak1/Dell-Latitude-7210-2-in-1-Hackintosh): Layout-ID 77, `alc-verbs <01000000>`, Node ID 0x19, Param 20.

- In allen configs steht unter `DeviceProperties → PciRoot(0x0)/Pci(0x1F,0x3)`: `layout-id` = `4D000000` (77) und `alc-verbs` = `01000000`. In den boot-args steht **kein** `alcid` mehr, die Layout-ID ist also nur an einer Stelle eingetragen.
- [`Extras/ALCPlugFix`](Extras/ALCPlugFix): `install.command` per Rechtsklick → „Öffnen“ starten. Es lädt ALCPlugFix-Swift 1.5 vom offiziellen Release (SHA-256 geprüft) und richtet einen LaunchDaemon ein, der beim Einstecken der Kopfhörer, beim Start und nach dem Aufwachen `SET_PIN_WIDGET_CONTROL 0x20` an Node `0x19` schickt.
- SIP muss dafür **nicht** abgeschaltet werden.
- Geht es nicht: `Param` auf `0x24` ändern oder per boot-arg eine andere Layout-ID testen (`alcid=33`, `13`, `3`; `alcid` überschreibt `layout-id`). Details im [Extras-README](Extras/ALCPlugFix/README.md).

## Optional: Touch / Tablet-Modus

Ohne Tastatur-Dock (Tablet-Modus) braucht man eine Bildschirmtastatur.

**Einfach (in macOS eingebaut):** Systemeinstellungen → Bedienungshilfen → Tastatur → **„Bedienungshilfen-Tastatur“** einschalten. Damit du dich auch ohne Tastatur anmelden kannst, dort zusätzlich die Bedienungshilfen-Tastatur für das **Anmeldefenster** aktivieren. Schneller ein- und ausschalten: unter Kontrollzentrum „Kurzbefehle für Bedienungshilfen“ in der Menüleiste anzeigen.

**Besser (wie beim iPad):** **TouchKeys** aus [TouchDeck](https://www.whiteoakmedia.io/tools/touchdeck). Die Tastatur erscheint, sobald man in ein Textfeld tippt.

> ⚠️ Nur **TouchKeys** benutzen, **nicht** den mitgelieferten Touch-Treiber **„Touch Up“**. Der Touchscreen läuft hier schon über VoodooI2C, ein zweiter Treiber kann sich damit beißen.

### TouchKeys-Automatik (nur ohne Tastatur)
Im Ordner [`Extras/TouchKeys-Automatik`](Extras/TouchKeys-Automatik) liegt ein kleines Skript: Ein LaunchAgent (`com.latitude7200.touchkeys-auto`) prüft alle 3 Sekunden, ob eine Tastatur angeschlossen ist. Ist **keine** dran, startet er TouchKeys, sonst beendet er TouchKeys.

Als Tastatur zählen:
- das **Tastatur-Dock**: erkannt am HID-Gerät **„Alps Touchpad“** (USB), das nur bei angestecktem Dock auftaucht. Die Dock-Tastatur selbst meldet sich nicht als eigenes Gerät.
- echte **externe Tastaturen** per USB oder Bluetooth (HID Usage Page 1 / Usage 6).

Nicht als Tastatur zählen die virtuelle VoodooPS2-Tastatur (`Keyboard`, Transport PS2, ist immer da) sowie Touchscreen, Stift und andere interne Geräte.

**Installieren:**
1. TouchKeys muss als **`TouchKeys.app`** in **`/Applications`** (Programme) liegen.
2. `installieren.command` per **Rechtsklick → „Öffnen“** starten (beim ersten Mal blockiert macOS sonst die Datei). Am Ende zeigt das Skript die gerade erkannten Tastaturen an.

**Fehlersuche:** Welche Geräte gerade als Tastatur erkannt werden:
```
~/Library/Scripts/touchkeys-auto.sh liste
```
Ohne Dock sollte hier höchstens `Keyboard` (die virtuelle PS2-Tastatur, wird ignoriert) stehen. Weitere Geräte, die fälschlich als Tastatur zählen, kann man in `~/Library/Scripts/touchkeys-auto.sh` in der Zeile `IGNORIEREN=` ergänzen und dann mit `launchctl kickstart -k gui/$(id -u)/com.latitude7200.touchkeys-auto` neu starten.

**Deinstallieren:** `deinstallieren.command` per Rechtsklick → „Öffnen“ starten. Das entfernt LaunchAgent und Skript, TouchKeys selbst bleibt installiert.

## Zweites Gerät / System klonen

- **Jedes Gerät braucht eigene SMBIOS-Daten** (Seriennummer, MLB, SystemUUID, ROM). Nie die EFI bzw. config eines Geräts mit dessen Nummern auf ein anderes kopieren, sonst haben beide dieselben Nummern und Apple-Account/iMessage machen Probleme.
- Ein fertig eingerichtetes System lässt sich auf ein baugleiches Gerät übertragen: Auf dem ersten Gerät ein **Time-Machine-Backup** machen, auf dem zweiten macOS frisch installieren (mit seiner eigenen EFI) und bei der Einrichtung „Von Time-Machine-Backup übertragen“ wählen. Apps, Dateien und Einstellungen kommen mit.
- Danach auf dem zweiten Gerät: eigene EFI auf die SSD, einmal NVRAM-Reset, Kontrollzentrum/Menüleiste neu einstellen (neue UUID), Seriennummer auf checkcoverage.apple.com prüfen und den Apple-Account einmal ab- und wieder anmelden.

## Fehlerbehebung

| Problem | Lösung |
|---|---|
| Installer bleibt hängen / schwarzer Bildschirm | Auf dem Stick `config-vesa-fallback.plist` in `config.plist` umbenennen (eigene SMBIOS-Daten nicht vergessen). Damit läuft die Grafik ohne Beschleunigung. Nach der Installation wieder die normale `config.plist` verwenden. |
| Fehler beim Installieren / Update „An error occurred preparing the software update“ bzw. Seal-Fehler, **MSU 1130** | In der config unter Misc → Security muss `SecureBootModel` auf **`Disabled`** stehen. Das ist in allen configs dieses Repos schon so; nur falls du es geändert hast, zurückstellen. |
| Ich brauche das Auswahlmenü (z. B. für NVRAM-Reset) | Beim Start **Esc** (oder **Alt**) gedrückt halten. |
| Bild über Thunderbolt-/USB-C-Dock fehlt | Dock **vor dem Einschalten** einstecken. Thunderbolt-Security im BIOS auf „No Security“. |
| Bluetooth geht nicht | NVRAM zurücksetzen (Esc beim Start → „Reset NVRAM“). |
| Hänger nach dem Aufwachen am Dell-Logo | BIOS: „Sign of Life Indication“ – alle Haken raus, Wake on AC/Dock aus. |
| Kein WLAN | HeliPort installiert und gestartet? |
| Absturz beim **automatischen** Ruhezustand (Deckel zu oder Ruhezustand über das Menü gehen aber) | `sudo pmset -a displaysleep 10 sleep 10`, damit Bildschirm und System gleichzeitig schlafen gehen, siehe [Ruhezustand](#ruhezustand-und-energie-einstellen). |
| **Einstellungen (Kontrollzentrum) werden nicht gespeichert**, z. B. Akku in Prozent ist nach dem Neustart weg | Die Hardware-UUID ändert sich, wenn `SystemUUID` in der config leer ist oder sich ändert. macOS speichert diese Einstellungen pro UUID. Prüfen mit `system_profiler SPHardwareDataType \| grep UUID` (muss nach jedem Neustart gleich sein) und `ls ~/Library/Preferences/ByHost/` (mehrere `com.apple.controlcenter.<UUID>.plist` = UUID hat sich geändert). Lösung: eigene SMBIOS-Daten (inkl. `SystemUUID`) in die config auf der **SSD** eintragen und dabei bleiben. Danach die Einstellungen einmal neu setzen. |
| TouchKeys startet ohne Dock nicht von selbst | `~/Library/Scripts/touchkeys-auto.sh liste` ausführen, siehe [TouchKeys-Automatik](#touchkeys-automatik-nur-ohne-tastatur). |
| Kext Updater o. ä. warnt wegen `csr-active-config` / schreibgeschütztem Systemlaufwerk | Ignorieren („Nicht erneut anzeigen“). **Nicht** `csr-active-config` auf `FF0F0000` setzen und **nicht** `csrutil disable` / `csrutil authenticated-root disable` ausführen. Alle Kexts werden aus der EFI geladen, SIP muss an bleiben. |
| Kopfhörer bleiben stumm, Lautsprecher gehen | [ALCPlugFix](#kopfhöreranschluss-alcplugfix) installieren. Prüfen: `ioreg -l \| grep -E '"layout-id"\|"alc-verbs"'` und `sudo cat /var/log/alcplugfix.log`. |
| Nach einer Änderung startet nichts mehr | Deshalb immer eine funktionierende EFI auf einem USB-Stick aufheben und davon starten (F12). |

Bei Problemen: mit `config-installation.plist` starten (Verbose), ein Foto vom Bildschirm machen und ein Issue aufmachen.

## USB-Map

`UTBMap.kext` wurde mit [USBToolBox](https://github.com/USBToolBox/tool) für **dieses** Gerät (i7-8665U-Variante) erstellt. Eingetragen sind 10 von maximal 15 Ports: beide USB-C-Ports (Thunderbolt, je USB 2 und USB 3), der USB-A-Port (USB 2 und USB 3) sowie die internen Geräte (Tastatur-Dock/Touchpad, Front- und Rückkamera, Bluetooth, Fingerabdruck-/Smartcard-Chip, ein internes Full-Speed-Gerät).

Andere Varianten (z. B. **i5**, mit/ohne WWAN oder andere Ausstattung) können anders verdrahtet sein. Wenn bei dir ein Port nicht geht:
1. In der config unter Kernel → Add `UTBMap.kext` deaktivieren und `UTBDefault.kext` eintragen/aktivieren (so wie in `config-vesa-fallback.plist`).
2. Mit USBToolBox (macOS-Version) die Ports neu erfassen („Discover Ports“, jeden Port mit USB-2- **und** USB-3-Gerät testen, USB-C in beide Richtungen), dann „Build UTBMap.kext“.
3. Die neue `UTBMap.kext` einsetzen und wieder `UTBDefault.kext` gegen `UTBMap.kext` tauschen.

## Updates

- **Kleine macOS-Updates** (z. B. 15.x) kann man normal installieren.
- **Große Updates** (z. B. macOS 26): erst prüfen, ob OpenCore und alle Kexts (vor allem itlwm, VoodooI2C, AppleALC) schon dafür freigegeben sind.
- Kexts und OpenCore immer **zusammen** aktualisieren, vorher die EFI sichern und mit einem USB-Stick als Backup testen. Nach einem OpenCore-Update die config mit `ocvalidate` der passenden Version prüfen.
- **OpenCore Legacy Patcher nicht benutzen.** Er ist für alte echte Macs gedacht, deren Hardware Apple nicht mehr unterstützt. Die UHD 620 läuft unter Sequoia nativ, die Root-Patches von OCLP können das System beschädigen.
- **SIP und Authenticated Root nicht abschalten** (`csr-active-config` bleibt `00000000`). Die Warnung von Kext Updater wegen `csr-active-config` kann ignoriert werden.

## Credits

- [Acidanthera](https://github.com/acidanthera) – OpenCore, Lilu, WhateverGreen, AppleALC, VirtualSMC, CPUFriend, NVMeFix, BrcmPatchRAM/BlueToolFixup, VoodooPS2
- [OpenIntelWireless](https://github.com/OpenIntelWireless) – itlwm, IntelBluetoothFirmware/IntelBTPatcher, HeliPort
- [VoodooI2C](https://github.com/VoodooI2C/VoodooI2C) – Touchscreen/Stift
- [1Revenger1](https://github.com/1Revenger1/ECEnabler) – ECEnabler
- [USBToolBox](https://github.com/USBToolBox) – USB-Mapping
- [Dortania](https://dortania.github.io/OpenCore-Install-Guide/) – OpenCore Install Guide und vorgefertigte SSDTs
- [corpnewt](https://github.com/corpnewt) – GenSMBIOS, ProperTree
- [black-dragon74](https://github.com/black-dragon74/ALCPlugFix-Swift) – ALCPlugFix-Swift (auf Basis von goodwins ALCPlugFix)
- Referenz-EFIs, aus denen Ideen und Fixes übernommen wurden: DaZhuangNiu (Latitude 7200), CloverLeafBG (Latitude 7400), raccoon8888 (Latitude 7400), AppleBreak1 (Latitude 7210)

## Lizenzen

Dieses Repo enthält Software Dritter. Alle Bestandteile stehen unter ihren **eigenen Lizenzen** (z. B. OpenCore, Lilu, WhateverGreen, AppleALC und VirtualSMC unter BSD-3-Clause; andere Projekte wie VoodooI2C oder VoodooPS2 teils unter GPL). Die Lizenztexte findest du in den jeweiligen Original-Repositories. Für die Konfigurationsdateien und diese Anleitung gilt: frei verwendbar, ohne jede Garantie.

Dieses Projekt ist nicht mit Apple oder Dell verbunden. macOS ist eine Marke von Apple Inc.

---

## English

OpenCore EFI for the **Dell Latitude 7200 2-in-1** (i7-8665U, UHD 620, Intel Wi-Fi/BT, ALC3254, BIOS 1.39.0) running **macOS Sequoia 15.8.2** with **OpenCore 1.0.8** and SMBIOS **MacBookPro16,3**.

**Works:** accelerated graphics (Metal 3) incl. external display via USB-C/dock, Wi-Fi (itlwm + HeliPort), Bluetooth, sleep/wake, touchscreen, speakers, battery status, all USB ports (custom USB map), CPU power management (CPUFriend).
**Does not work:** AirDrop/Handoff/Sidecar/Continuity (needs a Broadcom card such as BCM94360NG or DW1820A), fingerprint reader, WWAN modem, SD card reader.

**Important – no serial numbers included.** `SystemSerialNumber`, `MLB`, `SystemUUID` and `ROM` are empty. Generate your own with [GenSMBIOS](https://github.com/corpnewt/GenSMBIOS) (model `MacBookPro16,3`), enter them in **every** config you use (PlatformInfo → Generic) with ProperTree or OCAuxiliaryTools, set `ROM` to your Wi-Fi MAC (12 hex chars) or 6 random bytes, and verify the serial is **not** valid on [checkcoverage.apple.com](https://checkcoverage.apple.com) before signing in with your Apple Account.

**Configs**
- `config.plist` – daily use, boots straight into macOS (no picker, no verbose). Hold **Esc** at boot for the picker.
- `config-installation.plist` – same, but with picker (10 s) and verbose. Rename it to `config.plist` on the USB stick for installation.
- `config-vesa-fallback.plist` – emergency: VESA graphics (no acceleration), generic USB (UTBDefault). Only if the installer hangs.

**Quick steps**
1. BIOS: Secure Boot off, SGX off, VT-d off, Legacy ROMs off, "Sign of Life Indication" all off, Wake on AC/Dock/LAN off, Thunderbolt security "No Security" + boot support on; optionally disable SD card, WWAN, NFC, fingerprint, rear camera, UEFI network stack.
2. Create the installer: `createinstallmedia` on macOS, or `macrecovery.py -b Mac-937A206F2EE63C01 -m 00000000000000000 download` from OpenCorePkg on Windows/Linux (FAT32/GPT stick).
3. Copy `EFI` to the stick, add your SMBIOS, use `config-installation.plist` as `config.plist`.
4. Install; at each reboot pick "macOS Installer", then "Macintosh HD".
5. Mount the SSD's EFI partition (`sudo diskutil mount disk0s1`), copy the EFI, use the normal `config.plist` (with your SMBIOS), reset NVRAM once (Esc → Reset NVRAM).
6. Install [HeliPort](https://github.com/OpenIntelWireless/HeliPort/releases) and add it to login items; hide the Wi-Fi icon in Control Center.
7. Sleep: run the `pmset` commands from the German section (`hibernatemode 0`, `standby 0`, `autopoweroff 0`, `powernap 0`, `proximitywake 0`, `tcpkeepalive 0`, remove `/var/vm/sleepimage`) **plus** `sudo pmset -a displaysleep 10 sleep 10`. Automatic idle sleep crashed when only the display turned off first and the system slept later; with display and system sleeping at the same time it works (lid/manual sleep always worked). `tcpkeepalive 0` limits Find My while asleep. Optional: `sudo pmset -a lidwake 0`.

**Headphone jack:** speakers work out of the box; the combo jack needs [ALCPlugFix-Swift](https://github.com/black-dragon74/ALCPlugFix-Swift) (values from [AppleBreak1's Latitude 7210 repo](https://github.com/AppleBreak1/Dell-Latitude-7210-2-in-1-Hackintosh)). All configs set `layout-id` = 77 and `alc-verbs` = `01000000` on `PciRoot(0x0)/Pci(0x1F,0x3)` (no `alcid` boot-arg). Run `Extras/ALCPlugFix/install.command` (right-click → Open); it downloads ALCPlugFix-Swift 1.5 from the official release (SHA-256 checked) and installs a LaunchDaemon sending `SET_PIN_WIDGET_CONTROL 0x20` to node `0x19` on plug-in, boot and wake. SIP stays on. Not yet tested on the 7200; if it fails try param `0x24` or `alcid=33/13/3`.

**Tablet mode (optional):** use the Accessibility Keyboard, or better TouchKeys from [TouchDeck](https://www.whiteoakmedia.io/tools/touchdeck) (only TouchKeys – **not** the bundled "Touch Up" driver; touch already works via VoodooI2C). `Extras/TouchKeys-Automatik` installs a LaunchAgent (`com.latitude7200.touchkeys-auto`) that starts TouchKeys (`/Applications/TouchKeys.app`) only when neither the keyboard dock (detected via the "Alps Touchpad" HID device) nor an external keyboard is connected. Install: right-click `installieren.command` → Open; debug: `~/Library/Scripts/touchkeys-auto.sh liste`; remove: `deinstallieren.command`.

**CPUFriend:** the data provider was generated for MacBookPro16,3 from Apple's original plist with LFM 800 MHz and EPP 0x90. Check with `kmutil showloaded | grep -i cpufriend` (two lines).

**Second device / cloning:** every device needs its own SMBIOS. Migrating via Time Machine to a fresh install works fine.

**Do not** use OpenCore Legacy Patcher and do not disable SIP/authenticated root; the `csr-active-config` warning from Kext Updater can be ignored.

**Troubleshooting:** installer hangs → `config-vesa-fallback.plist`; MSU 1130/seal error → `SecureBootModel` must be `Disabled` (already set); no dock display → plug the dock in before powering on; Control Center settings not saved → the Hardware UUID changes because `SystemUUID` is empty or changing (check `system_profiler SPHardwareDataType | grep UUID` and `ls ~/Library/Preferences/ByHost/`), enter your own SMBIOS and keep it. The boot keyboard layout is German (`prev-lang:kbd = de-DE:3`); change to `en-US:0` or remove it.

**USB map:** `UTBMap.kext` was built for the tested i7 unit; other variants (e.g. i5) may differ – re-map with USBToolBox if a port is missing.

No warranty. All bundled components remain under their own licenses (e.g. OpenCore and most Acidanthera kexts: BSD-3-Clause; some others GPL).
