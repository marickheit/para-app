# P.A.R.A. – Produktstand

Stand: 26. Oktober 2026 · lokale App 0.9.2 für macOS und Linux.

## Ziel und Grundregeln

- Persönlicher Arbeitsplatz für Dateien, Markdown-Notizen und GTD-Aufgaben.
- Lokal auf macOS und Linux mit lokalem MCP-Anschluss; Android und Cloud-Sync später.
- Ein Inhalt hat einen Hauptablageort. Stabile Links verbinden weitere Inhalte.
- Bestehende Nutzerdaten bleiben bei Änderungen erhalten: neue Versionen müssen
  ältere Daten direkt lesen oder verlustfrei migrieren. Entwicklungs-/Testdaten
  liegen getrennt vom regulären Arbeitsbereich; siehe [AGENTS.md](AGENTS.md).
- Projekte haben ein konkretes Ergebnis und ein Fälligkeitsdatum und stehen
  aktiv nur auf oberster Ebene. „Irgendwann / Vielleicht“ enthält Ideen und
  zurückgestellte Aufgaben, keine Projekte. Ideen/Aufgaben können Projekte werden.

## Funktionen und Bedienung

- **Oberfläche:** A mit Dateitabs und breiter Dateifläche umgesetzt; optionaler
  Fokusmodus B blendet nur den Explorer aus. Explorer per Kante in der Breite
  verstellbar, Textlesebreite auf Wunsch. Vorschautabs, dauerhafte Tabs,
  Speicherschutz und gespeicherte Sitzung. [Bedienung und Prüfungen](docs/DATEI_TABS_UMSETZUNGSPLAN.md).
  Links Symbole oder Symbole mit Namen, daneben der vollständige Datei-/Ordnerbaum,
  rechts Containerübersicht oder Editor. Eine gemeinsame kompakte Kopfzeile
  wechselt Übersicht, Inhalte und Aufgaben. Containerklick wählt sichtbar aus;
  erneuter Klick wählt ab. Nur der Pfeil daneben klappt den Baum auf oder zu.
- **Ablage:** Inbox, Projekte, Bereiche, Ressourcen und Archiv. Ordner über den Pfeil
  auf-/zuklappen. Kategorien öffnen ohne automatische Auswahl. Plus und Strg/Cmd+N
  bieten dieselbe Typauswahl: ohne Container nur Haupttypen der Kategorie, mit
  Auswahl Inhalte im grau markierten Ziel. Kontextmenüs gelten für ihren Container;
  Dialoge zeigen den Zielpfad und erlauben bei normalen Inhalten einen Zielwechsel.
- **Editor:** Markdown-Notizen und kleine UTF-8-TXT-/Markdown-Dateien bearbeiten,
  Vorschau und explizites Speichern; Schutz ungespeicherter Änderungen. Dateiinfos
  stehen hinter einem kleinen Info-Symbol. Umbenennen erhält UUIDs und Links.
- **Vorschau:** PDF, Rasterbilder, SVG und CSV. Andere Dateien als Kopie speichern
  oder mit der Standard-App öffnen. CSV-Vorschau und Inhaltssuche haben Grenzen,
  siehe [Bedienung](README.md). Keine Office-/Binärbearbeitung.
- **Import und Verschieben:** Dateiauswahl, Ordnerauswahl und Drag-and-drop in
  Inbox, Projekte, Bereiche, Ressourcen und deren Ordner. Import als lokale Kopie,
  vorhandene Inhalte intern per Ziehen oder „Verschieben …“ bewegen. Kleine
  UTF-8-Markdown-Importe werden Notizen; große Dateien werden gestreamt.
- **Eingangsordner:** Frei wählbare lokale Quelle, automatische bytegetreue
  Übernahme mit verschachtelten/leeren Ordnern in die Inbox. Nur bei laufender App,
  Nachholen beim Start, Pause und Fehleranzeige. Dauerhaftes Importjournal,
  geprüfte Zwischenkopien und Originale im externen Rückholbereich ohne automatische
  Löschung. Kopien/Sicherungsrückholungen aktivieren keine externe Quelle.
- **Aufgaben:** Noch zu klären, Nächste Aktion, Warten auf, Irgendwann / Vielleicht,
  Erledigt und Nicht mehr relevant. Letztere zwei sind getrennte Abschlusszustände;
  Wiederaufnahme verwendet den vorherigen Arbeitsstatus. Globale nächste Aktionen
  sind nach Projekt gruppiert, Aufgaben ohne Projekt stehen separat.
- **Aktionen:** Rechtsklick und Drei-Punkte-Menü bieten dieselben passenden
  Aktionen, auch bei Irgendwann. Projektumwandlung verlangt Ergebnis/Termin und
  erhält Text und Links. Menü unten enthält Daten & Sicherung.
- **Suche:** Schwebendes Fenster über Lupe oder Cmd/Ctrl+F; unscharfe Namen und
  Inhalte unterstützter Dateien, Notizen und Aufgabenkontexte. Cmd/Ctrl+K bleibt
  als bisheriges Kürzel, Cmd/Ctrl+O wechselt nur nach Namen. Keine OCR.
- **Startzeit:** Vorhandenen Suchindex sofort verwenden; Änderungen und neue PDFs
  im Hintergrund indexieren. Unveränderte Dateien nicht erneut auslesen. Offene
  Suche aktualisiert Treffer und zeigt laufende Arbeit/Fehler.
- **Archiv und Sicherung:** Jahr → Herkunft → ursprüngliche Ordner. Einzelne
  Inhalte lassen sich an einen aktiven Zielort zurückholen; Projektabschluss
  archiviert das Projekt. Vollständiger lokaler Sicherungsexport einschließlich
  Papierkorb und Textversionen.
- **Papierkorb:** Links unter „Alle Aufgaben“. „In Papierkorb“ erhält Inhalte,
  UUIDs, Links und Status; Wiederherstellung zum ursprünglichen oder gewählten Ort.
  Endgültiges Entfernen und „Papierkorb leeren“ erst nach Bestätigung, keine automatische Leerung.
- **Textversionen:** Gespeicherte Textänderungen an Notizen und bearbeitbaren MD/TXT
  bleiben im Verlauf. Alte Texte lassen sich als neuer Stand zurückholen, jüngere
  Texte bleiben erhalten. Vorhandene ältere Stände werden nicht rückwirkend rekonstruiert.

- **Arbeitsbereiche und Einstellungen:** Vollständigen Root über Einstellungen öffnen,
  neu anlegen oder vollständig kopieren. Quelle beim Kopieren erhalten. Auswahl und
  macOS-Ordnerfreigabe über Neustarts merken; nur Startverweis liegt außerhalb des Roots.
  Navigation, geöffneter Inhalt und Filter liegen im Arbeitsbereich.
- **Aufgabenangaben:** Mehrere gleichberechtigte Kontexte, optionale Bearbeitungszeit
  und Energie. Kleine farbige Chips unter dem Titel, kombinierbare Listenfilter.
  Kontextnamen, Farben, Reihenfolge und Aktivierung in Einstellungen verwalten;
  bestehende freie Kontexttexte verlustfrei übernehmen.
- **Übernahme älterer Daten:** Schema 6 migriert Formate 1–5 nach vollständiger
  automatischer Rückfallkopie. Neuere unbekannte Formate ablehnen, aktuellen
  Mehrprozess-Zugriff sperren; unvollständige Übernahmen nicht aktivieren.

- **MCP:** Lokaler stdio-Server unter `mcp/`, sofortige Zugriffsauswahl in Einstellungen
  und automatische sichere Verbindungsablage auf macOS/Linux; Suche,
  Lesen, Projekte/Bereiche/Ressourcensammlungen/Ordner anlegen, Titel/Projektdaten
  bearbeiten und gezielte Text-/Aufgabenänderungen über die laufende App.
  19 Werkzeuge, kompakte Listen und begrenzte Textabschnitte mit Fortsetzung. Rechte,
  Konflikt- und Editorschutz; kein Zugriff auf Papierkorb oder endgültiges Löschen.
  [Einrichtung und Grenzen](docs/MCP.md).

## Offen / später

- Geteilte Ansichten wie C erst später bei Bedarf. Tabgruppen und mehrere
  gleichzeitig ungespeicherte Editoren bleiben ebenfalls außerhalb dieser Iteration.
- Projektprüfung und Wochenrückblick bleiben nicht ausgewählte GTD-Vorschläge.
- Live Preview/Autosave, Rückgängig, Mehrfachauswahl und weitere Textformate sind
  unbestätigte Vorschläge, keine bereits umgesetzten Funktionen.
- Wiederkehrende Aufgaben, externe Dateiverweise.
- Große Backups, selektive Verfügbarkeit, Cloud-Anbieter, Konfliktauflösung.
- Linux-x64-Release-Build geprüft; vollständige native Linux-Bedienung und
  Android-Build noch offen.

[Bedienung](README.md) · [UI-Anforderungen](docs/UI_UMZUG.md) ·
[Umsetzungsplan und Prüfungen](docs/UMSETZUNGSPLAN.md) ·
[Architektur](docs/ARCHITEKTUR.md) · [Sicherung](docs/SICHERUNG.md)
