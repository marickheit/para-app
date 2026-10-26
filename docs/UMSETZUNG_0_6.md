# Umsetzung 0.6: Arbeitsbereiche und Aufgabenangaben

Versionsgebundener Nachweis für 0.6, implementiert und geprüft. Aktuelle Bedienung
und Grenzen stehen in [README](../README.md), die aktuelle Abnahme im
[Arbeitsstand](UMSETZUNGSPLAN.md). Die damaligen Prüfzahlen gelten nur für 0.6.

## Verbindlicher Umfang

- Vollständiger Arbeitsbereich: Daten, Einstellungen und gespeicherte Navigation
  im Root. Nur zuletzt geöffneter Pfad und macOS-Ordnerfreigabe außerhalb speichern.
- Einstellungen: vorhandenen Arbeitsbereich öffnen, neuen leeren anlegen und
  aktuellen Bestand in einen leeren Zielordner kopieren. Bestehende Ordner nicht
  überschreiben; Quelle und Rückfallmöglichkeit erhalten. Auswahl nach Erfolg
  speichern und nach Neustart erneut öffnen.
- Vor dem Wechsel ungespeicherte Änderungen behandeln. Nicht verfügbare, gesperrte
  oder neuere unbekannte Arbeitsbereiche melden; niemals still leer neu starten.
- Mehrere gleichberechtigte Kontexte pro Aufgabe, im Arbeitsbereich verwaltbar:
  Name, Farbe, Reihenfolge, aktiv/inaktiv. Umbenennen erhält Zuordnungen.
- Optionale aktive Bearbeitungszeit: 5/15/30/60/120 Minuten oder eigene Minuten.
  Energie: keine Angabe, niedrig, mittel, hoch. Keine Pflichtfelder.
- Kleine farbige, abgerundete Chips unter dem Aufgabentitel, mit Zeilenumbruch;
  Kontextnamen, Uhr/Zeit und Energie. Nur gesetzte Werte anzeigen.
- Aufgabenfilter: Kontexte (mindestens einer/alle), maximale Zeit, maximale Energie,
  fehlende Angaben optional einbeziehen. Projektgruppierung erhalten.
- Bestehende Daten einschließlich freier Kontexttexte, Links, Papierkorb und
  Textverlauf verlustfrei übernehmen. Einstellungen und Sitzungsstand mitsichern.

## Schritte und Prüfungen

- [x] Schema und Repository erweitern; ältere Daten migrieren, freie Kontexte
  unverändert zuordnen und dauerhafte Einstellungen im Root speichern.
- [x] Arbeitsbereiche vor Öffnung prüfen, für Migrationen vollständig sichern,
  Mehrprozess-Zugriff sperren und sichere Übernahme/Neuanlage implementieren.
- [x] Startauswahl und macOS-Ordnerberechtigung persistent machen; Test-Overrides
  vollständig vom regulären Startverweis trennen.
- [x] Einstellungen für Arbeitsbereich und Kontexte sowie Aufgabenfelder, Chips
  und Filter integrieren; gespeicherte Navigation/Filter wiederherstellen.
- [x] Migration 1–4, unabhängige Sicherungsrückholung, Kontextverwaltung, Filter,
  Wechsel/Neustart und Fehler-/Abbruchfälle mit getrennten Daten prüfen.
- [x] Native Mac-Bedienung, kleine Fenster und Darstellung prüfen; Release bauen,
  aktuelle Dokumentation und konkrete Review-Hinweise bereitstellen.

Ergebnis: 59 Fach-/Widgettests, 13 native Mac-Prüfungen und Codeprüfung erfolgreich.
Der echte macOS-Ordnerdialog und die Wiederaufnahme eines externen Arbeitsbereichs
nach vollständigem Beenden wurden zusätzlich manuell geprüft.
[Review-Anleitung](REVIEW_0_6.md) · [Prüfstand](UMSETZUNGSPLAN.md).

Wochenrückblick, Projektprüfung, Wiederholungen, Autosave und Wiederherstellung
ungespeicherter Entwürfe gehören nicht zu dieser Umsetzung.
