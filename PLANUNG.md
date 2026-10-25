# P.A.R.A. – Produktstand

Stand: 25. Oktober 2026 · lokale Mac-App 0.6.

## Ziel und Grundregeln

- Persönlicher Arbeitsplatz für Dateien, Markdown-Notizen und GTD-Aufgaben.
- Zuerst lokal auf macOS; später Linux, Android, Cloud-Sync und MCP.
- Ein Inhalt hat einen Hauptablageort. Stabile Links verbinden weitere Inhalte.
- Bestehende Nutzerdaten bleiben bei Änderungen erhalten: neue Versionen müssen
  ältere Daten direkt lesen oder verlustfrei migrieren. Entwicklungs-/Testdaten
  liegen getrennt vom regulären Arbeitsbereich; siehe [AGENTS.md](AGENTS.md).
- Projekte haben ein konkretes Ergebnis und ein Fälligkeitsdatum und stehen
  aktiv nur auf oberster Ebene. „Irgendwann / Vielleicht“ enthält Ideen und
  zurückgestellte Aufgaben, keine Projekte. Ideen/Aufgaben können Projekte werden.

## Funktionen und Bedienung

- **Oberfläche:** Bestätigte Symbolleisten-/Explorer-Vorlage in Flutter umgesetzt.
  Links Symbole oder Symbole mit Namen, daneben der vollständige Datei-/Ordnerbaum,
  rechts direkt der Editor. Eine gemeinsame kompakte Kopfzeile wechselt Inhalte/Aufgaben.
- **Ablage:** Inbox, Projekte, Bereiche, Ressourcen und Archiv. Ordner per Klick
  auf-/zuklappen. Plus und Kontextmenü legen Inhalte am angezeigten Ziel an.
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
- **Übernahme älterer Daten:** Schema 5 migriert Formate 1–4 nach vollständiger
  automatischer Rückfallkopie. Neuere unbekannte Formate ablehnen, aktuellen
  Mehrprozess-Zugriff sperren; unvollständige Übernahmen nicht aktivieren.

## Offen / später

- Projektprüfung und Wochenrückblick bleiben nicht ausgewählte GTD-Vorschläge.
- Live Preview/Autosave, Rückgängig, Mehrfachauswahl und weitere Textformate sind
  unbestätigte Vorschläge, keine bereits umgesetzten Funktionen.
- Wiederkehrende Aufgaben, externe Dateiverweise.
- Große Backups, selektive Verfügbarkeit, Cloud-Anbieter, Konfliktauflösung, MCP.
- Linux-/Android-Build und native Bedienung auf diesen Systemen noch nicht geprüft.

[Bedienung](README.md) · [UI-Anforderungen](docs/UI_UMZUG.md) ·
[Umsetzungsplan und Prüfungen](docs/UMSETZUNGSPLAN.md) ·
[Architektur](docs/ARCHITEKTUR.md) · [Sicherung](docs/SICHERUNG.md)
