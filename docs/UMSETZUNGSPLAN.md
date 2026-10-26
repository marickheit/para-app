# Arbeitsstand

Stand: 26. Oktober 2026 · Version 0.7.3+10.

## Implementiert

- Auswahl, Übersicht und Anlegen 0.7.3: Kategorien ohne automatische Auswahl,
  graues Anlageziel, Containerklick wählt/klappt auf, erneuter Klick wählt ab/zu.
  Übersicht mit Beschreibung und Aktionen; Plus und Cmd/Ctrl+N mit denselben
  Regeln. Weitere Haupttypen bleiben erreichbar, explizite Zielpfade/-auswahl in
  Anlegedialogen und Import. [Umsetzung und Abnahme](ANLEGEN_UMSETZUNGSPLAN.md).

- Flutter-Grundlayout mit Symbolleiste, Explorer, Editor und Suche.
- Dateien/Notizen bearbeiten, importieren, verschieben und verknüpfen; unterstützte
  Vorschauen, Archiv, Papierkorb und Textverlauf gemäß README.md.
- GTD-Listen mit projektweisen nächsten Aktionen und getrenntem Aufgabenabschluss.
- Mehrere Kontexte, optionale Minuten und Energie; Chips und kombinierbare Filter.
- Kontextverwaltung, wählbare Arbeitsbereiche, vollständiges Kopieren und gespeicherte Ansicht.
- Schema 5: vollständige Rückfallkopie vor Migrationen aus 1–4, Root-Sperre und
  Ablehnung unbekannter neuerer Datenformate.
- Lokaler MCP-Server im Repository: sofortige Zugriffsauswahl und automatische
  sichere Verbindungsablage auf macOS/Linux, acht Lese- und
  sechs Schreib-Werkzeuge über die laufende App. Revisions-/Hashschutz,
  Schutz offener Editorentwürfe und Widerruf beim Rootwechsel.

[Bedienung](../README.md) · [MCP-Einrichtung](MCP.md) ·
[MCP-Architekturplan](MCP_PLAN.md) · [MCP-Umsetzung und Prüfungen](MCP_UMSETZUNG.md) ·
[Arbeitsbereiche](ARBEITSBEREICHE.md) · [Aufgabenangaben](GTD_AUSBAU.md).

## Prüfstand

- Auswahl/Übersicht/Anlegen 0.7.3: Analyse ohne Befund und alle 82 Flutter-Tests
  erfolgreich. Zehn neue native Linux-Abläufe sowie alle zwölf auf Linux
  anwendbaren bisherigen Bedienabläufe erfolgreich. Der macOS-spezifische
  Ordnerrechte-/Bookmark-Test wird auf Linux ausdrücklich übersprungen;
  erneute native macOS-Prüfung offen. Projektübersicht visuell geprüft.
  Ausschließlich temporäre synthetische Arbeitsbereiche. Details im
  [Anlege-Umsetzungsplan](ANLEGEN_UMSETZUNGSPLAN.md). Linux-Release gebaut und
  lokal als 0.7.3 installiert, alle kopierten Dateien gegen den Build geprüft.
  Rückfallkopie der vorherigen App vorhanden; laufende App nicht beendet.

- Projektanlage 0.7.2 gemäß [Plan](MCP_PROJEKTE_PLAN.md): `create_project`
  in App, MCP und Skill. Ergebnis/Termin Pflicht, feste oberste Projektebene.
  Analyse ohne Befund, alle 82 Flutter-Tests und sechs Node-Tests erfolgreich.
  Native Linux-Testapp mit echtem stdio-Client: alle 14 Werkzeuge erfolgreich,
  einschließlich Projektanlage und zugeordneter Aufgaben. Daten ausschließlich
  in temporären Testroots. Linux-Release gebaut, App 0.7.2 und MCP 0.2.0 lokal
  mit Rückfallkopien installiert; installierten Server erneut mit allen 14
  Werkzeugen geprüft. Skill-Verweis aktuell, Format validiert.
  Neuer nativer macOS-Test weiterhin offen.

- MCP 0.7.1: Analyse und alle 80 Flutter-Tests sowie sechs Node-Tests erfolgreich.
  Nativer Linux-Test prüft automatische Ablage, Zugriffsauswahl, 0700/0600,
  Symlink-/Dateischutz, Widerruf und alle 13 Werkzeuge über automatische
  Servererkennung. Nutzdaten ausschließlich in temporären Testroots.
  Auch der tatsächlich installierte MCP-Server mit allen 13 Werkzeugen geprüft.
  Neuer nativer macOS-Sandbox-Test steht noch aus.

- Linux x64 auf Omarchy: Release-Build mit Flutter 3.47.8 / Dart 3.13.7
  erfolgreich; alle 80 Flutter-Tests erfolgreich. SDK-gebundene Pakete im Lockfile
  angepasst, PDF-Engine auf 0.4.7 für die aktuelle Dart-Kompilierung aktualisiert.
  Nativer Linux-Integrationstest für Projektinhalte, stabile Links, Aufgabenwechsel,
  Speichern und Wiederöffnen erfolgreich, ausschließlich mit temporären Testdaten.
  Build-Ergebnis: `build/linux/x64/release/bundle/`; vollständige native
  Linux-Bedienprüfung weiterhin offen.
- Codeprüfung ohne Befund; alle 80 Flutter-Tests erfolgreich,
  einschließlich alter Schemas, unabhängiger Sicherungsrückholung, UUIDs,
  Texten, Dateien, Links, Status, Archiv, Papierkorb, Textversionen und Einstellungen.
- Bisheriger macOS-Prüfstand aus 0.7.0: echte stdio-Verbindung mit SDK-Client und temporärem Repository; alle
  13 Werkzeuge zusätzlich über eine signierte native macOS-Release-Testapp geprüft.
  Externer Root über nativen Ordnerdialog ausgewählt, unsichere Verbindungsdateien
  abgelehnt. Details im [MCP-Prüfstand](MCP_UMSETZUNG.md).
- Alle 13 bisherigen nativen macOS-Bedienabläufe für 0.7.0 geprüft.
- Architektur-/Sicherheitsreviews für den bisherigen Umfang aus 0.7.0 ohne Blocker.
- Alle Entwicklungs- und Testläufe verwenden getrennte synthetische Daten.
  Kein regulärer Nutzerarbeitsbereich wurde für diese Umsetzung geöffnet.

## Weitere offene Arbeit

- Regelmäßige automatische Sicherungen, geführte Auswahl älterer Sicherungsstände,
  allgemeiner Wiederanlauf für Datei-/Datenbankänderungen und App-Updater.
- Wochenrückblick, Projektprüfung, Wiederholungen und externe Dateiverweise sind
  weitere Vorschläge und nicht Teil dieser Umsetzung.
- Autosave, Live Preview, Mehrfachauswahl und Rückgängig bleiben offen.
- Vollständige Linux-Bedienprüfung, Android und Cloud-Sync bleiben offen.
- MCP-Erweiterungen: vorhandene Inhalte in Projekte umwandeln, Verschieben, Dateiimport,
  Archiv-/Papierkorbaktionen, dauerhafte oder eingeschränkte Teilfreigaben.

[Sicherung](SICHERUNG.md) · [Architektur](ARCHITEKTUR.md) ·
[UI-Anforderungen](UI_UMZUG.md).
