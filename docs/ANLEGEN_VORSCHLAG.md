# Anlegen: umgesetzter Umfang und verbleibender Vorschlag

Stand: 27. Oktober 2026 · App 0.10.0. Die Überarbeitung der Auswahl-/Anlageziele
ist seit 0.7.3 umgesetzt. Verbindlich sind [Bedienung](../README.md) und
[Umsetzung/Prüfungen](ANLEGEN_UMSETZUNGSPLAN.md).

Ohne Auswahl bieten Projekte/Bereiche/Ressourcen die jeweilige Hauptanlage;
mit Auswahl lokale Inhaltstypen und eine getrennte weitere Hauptanlage.
Container haben eine Übersicht, Dialoge zeigen den Zielpfad und normale Inhalte
erlauben einen Zielwechsel. Geöffnete Dateien verwenden ihren Elterncontainer
als sichtbares Anlageziel.

Seit 0.9.2 wählen Name/Zeile aktive Container aus oder ab, ohne den Baumzustand
zu verändern. Nur der separate Pfeil klappt auf/zu; dabei bleiben Auswahl und
Editor erhalten. Archiv und Papierkorb trennen Pfeil und Inhaltsöffnung ebenfalls.

Die MCP-Anlage von Bereichen, Ressourcensammlungen und Ordnern ist implementiert;
siehe [MCP](MCP.md). „Neu daneben …“ an einzelnen Dateien bleibt ein unbestätigter
Vorschlag. Die vorhandenen Kontextaktionen an Containern sind umgesetzt.
