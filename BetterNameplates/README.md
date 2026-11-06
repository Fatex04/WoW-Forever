# BetterNameplates für WoW Forever

Version 1.3.0 · Interface 16001 (Camelot)

BNP verwendet die originalen **Classic-Namensplaketten** von Forever. Namen,
HP-Zahlen und Level bleiben native Beschriftungen und erhalten eine größere
Schrift mit Kontur und dunklem Schatten. Die Classic-Umrandung, Levelposition,
Schwierigkeitsfarben, Totenköpfe, Auswahl und Gesundheitsupdates bleiben erhalten.

Der Adapter unterstützt Forevers neue verschachtelte Healthbar-Struktur.
Doppelte Inline-Namen und Modern-Platten werden nicht erzeugt. BNP liest oder
formatiert keine eingeschränkten HP-, Namens- oder Leveltexte. Wenn Threatdaten
nicht verfügbar sind, bleibt nur BNPs eigenes Threat-Schild verborgen.

Öffnen mit `/bnp` oder `/betternameplates`. Skalierung sowie Namen-, HP- und
Level-Schriftgrößen sind getrennt einstellbar; die Vorschau zeigt Classic-Artwork.
Die vorhandenen BNP-Einstellungen bleiben erhalten. BetterBlizzPlates-Variablen
werden in der Forever-Version nicht umgeschrieben.

Den Ordner `BetterNameplates` nach `_forever_/Interface/AddOns` kopieren. Die
Basis-, Camelot- und Forever-Manifeste laden dieselbe Forever-Version. Die
unveränderte Classic-Era-Ausgabe liegt im ursprünglichen BNP-Repository.

Regressionen: `python tests/forever_native.py` (Python + lupa, Lua 5.1; verwendet
die gemeinsame Widget-Fixture im benachbarten DragonflightUI-Verzeichnis).
