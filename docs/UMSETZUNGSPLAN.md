# Arbeitsstand

Stand: 26. Oktober 2026 · Version 0.7.0+7.

## Implementiert

- Flutter-Grundlayout mit Symbolleiste, Explorer, Editor und Suche.
- Dateien/Notizen bearbeiten, importieren, verschieben und verknüpfen; unterstützte
  Vorschauen, Archiv, Papierkorb und Textverlauf gemäß README.md.
- GTD-Listen mit projektweisen nächsten Aktionen und getrenntem Aufgabenabschluss.
- Mehrere Kontexte, optionale Minuten und Energie; Chips und kombinierbare Filter.
- Kontextverwaltung, wählbare Arbeitsbereiche, vollständiges Kopieren und gespeicherte Ansicht.
- Schema 5: vollständige Rückfallkopie vor Migrationen aus 1–4, Root-Sperre und
  Ablehnung unbekannter neuerer Datenformate.
- Lokaler MCP-Server im Repository: Freigabe in Einstellungen, acht Lese- und
  fünf Schreib-Werkzeuge über die laufende App. Revisions-/Hashschutz,
  Schutz offener Editorentwürfe und Widerruf beim Rootwechsel.

[Bedienung](../README.md) · [MCP-Einrichtung](MCP.md) ·
[MCP-Architekturplan](MCP_PLAN.md) · [MCP-Umsetzung und Prüfungen](MCP_UMSETZUNG.md) ·
[Arbeitsbereiche](ARBEITSBEREICHE.md) · [Aufgabenangaben](GTD_AUSBAU.md).

## Prüfstand

- Codeprüfung ohne Befund; alle 78 Flutter-Tests erfolgreich,
  einschließlich alter Schemas, unabhängiger Sicherungsrückholung, UUIDs,
  Texten, Dateien, Links, Status, Archiv, Papierkorb, Textversionen und Einstellungen.
- MCP: echte stdio-Verbindung mit SDK-Client und temporärem Repository; alle
  13 Werkzeuge zusätzlich über eine signierte native macOS-Release-Testapp geprüft.
  Externer Root über nativen Ordnerdialog ausgewählt, unsichere Verbindungsdateien
  abgelehnt. Details im [MCP-Prüfstand](MCP_UMSETZUNG.md).
- Alle 13 bisherigen nativen Bedienabläufe nach der Erweiterung geprüft.
- Unabhängige Architektur-/Sicherheitsreviews nach Korrekturen ohne Blocker.
- Alle Entwicklungs- und Testläufe verwenden getrennte synthetische Daten.
  Kein regulärer Nutzerarbeitsbereich wurde für diese Umsetzung geöffnet.

## Weitere offene Arbeit

- Regelmäßige automatische Sicherungen, geführte Auswahl älterer Sicherungsstände,
  allgemeiner Wiederanlauf für Datei-/Datenbankänderungen und App-Updater.
- Wochenrückblick, Projektprüfung, Wiederholungen und externe Dateiverweise sind
  weitere Vorschläge und nicht Teil dieser Umsetzung.
- Autosave, Live Preview, Mehrfachauswahl und Rückgängig bleiben offen.
- Linux/Android und Cloud-Sync sind nicht als funktionsfähig geprüft.
- MCP-Erweiterungen: Projekte anlegen/umwandeln, Verschieben, Dateiimport,
  Archiv-/Papierkorbaktionen, dauerhafte oder eingeschränkte Teilfreigaben.

[Sicherung](SICHERUNG.md) · [Architektur](ARCHITEKTUR.md) ·
[UI-Anforderungen](UI_UMZUG.md).
