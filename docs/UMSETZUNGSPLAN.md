# Arbeitsstand

Stand: 25. Oktober 2026 · Version 0.5.0+5.

## Fertig

Die bestätigte Symbolleisten-/Explorer-Vorlage ist in Flutter umgesetzt:
56/164-Pixel-Navigation, vollständiger Projekt-/Ordnerbaum, kompakte Kopfzeile,
Editor mit MD/TXT und Metadaten, gemeinsame Kontextaktionen, Import/Verschieben,
projektweise nächste Aktionen, „Nicht mehr relevant“ mit Wiederaufnahme,
Dateivorschauen und schwebende Suche. Menü unten führt zu Daten & Sicherung.
Papierkorb steht links unter den Aufgaben; Notizen und bearbeitbare MD/TXT haben einen Versionsverlauf.

[Bestätigte Anforderungen](UI_UMZUG.md) · [Abgeschlossener Umzugsplan](FLUTTER_UMZUG_PLAN.md).
Die [Mockup-Quelle](mockups/para-zieloberflaeche.html) bleibt die Gestaltungsreferenz.

## Prüfstand

- Codeprüfung ohne Beanstandungen; 44 Fach-/Widgettests erfolgreich.
- Zehn native Mac-Bedienprüfungen erfolgreich; TXT-/PDF-Ablauf zusätzlich am
  endgültigen Dateicode geprüft. Testdaten liegen in getrennten temporären Arbeitsbereichen.
- Release-Build erstellt; Oberfläche mit realen Flutter-Vergleichsbildern geprüft.
- Geprüft: Schema-1-/Schema-2-/Schema-3-Migration, dauerhafte Aufgabenabschlüsse und deren
  Wiederaufnahme, MD-/TXT-Speichern und Wiederöffnen, Revisions-/Hashkonflikte,
  Dateiumbenennung einschließlich älterer Anzeigenamen und stabile Links.
- Geprüft: nativer desktop_drop-Kanal mit echten lokalen Dateien, rekursiver Import,
  präzise Drop-Ziele, interner Maus-Drag von Dateien und Ordnern, andere Ablagen,
  gemeinsame Rechtsklick-/Drei-Punkte-Aktionen, Projektumwandlung und Archiv-Rückholung.
- Geprüft: 56/164-Pixel-Navigation ohne Verlust offener Änderungen, Suchabbruch,
  unscharfe Namen versus Inhaltssuche, Tastaturauswahl, Cmd+F auch nach PDF-Wechsel,
  echte PDF-Darstellung/-Textextraktion, Dateiinfos, Menü und 390-Pixel-Ansicht.
- Native Oberfläche mit Testdaten geprüft; Nutzerinhalte wurden nicht mit
  Beispieldaten ergänzt. Vor dem Versionswechsel wurde eine vollständige lokale
  Rückfallkopie des Arbeitsbereichs und der bisherigen App erstellt.
- Release 0.5 gestartet; Schema-Übernahme, unveränderte Dateiinhalte und bestehende
  Metadaten gegen die Rückfallkopie geprüft. Kleiner Versionsbutton und
  Öffnen/Schließen des Verlaufsfensters auch in der Release-App geprüft.
- Vergleichsbilder: [Papierkorb](pruefungen/para-0.5-trash.png),
  [Versionsverlauf](pruefungen/para-0.5-note-history.png).

## Daten und Grenzen

Schema 4 ergänzt Papierkorbgruppen und Textversionen; Migrationen aus Schema 1–3
erhalten bestehende Inhalte und Kennungen.

Schema 3 ergänzt den vorherigen Aufgabenstatus. UUIDs, Dateien, Notizen, Links
und Archivherkunft bleiben erhalten. Bei alten erledigten Aufgaben ohne bekannte
Historie ist der Wiederaufnahmestatus „Nächste Aktion“.

Text-/PDF-Suchumfang, Encoding- und Vorschaugrenzen stehen in [README.md](../README.md).
Autosave, Live Preview, Mehrfachauswahl und Rückgängig bleiben unbestätigte Vorschläge.
Linux/Android, Cloud-Sync und MCP sind noch nicht geprüft beziehungsweise umgesetzt.

## Papierkorb und Textversionen: umgesetzt

- [x] Schema 4: Papierkorbgruppen und Herkunft, Textversionen mit stabiler Reihenfolge.
- [x] „In Papierkorb“ in gemeinsamen Menüs; links direkt unter „Alle Aufgaben“.
- [x] Schreibgeschützte Vorschau, Ordner auf-/zuklappen, Wiederherstellung zum
  ursprünglichen Ort oder einem anderen zulässigen Ziel. UUIDs und Status bleiben.
- [x] Separat entfernte Kinder bleiben bei der Rückholung ihres Ordners im Papierkorb.
- [x] „Papierkorb leeren“ und einzelne endgültige Entfernung mit Bestätigung,
  Umfang und Rückverweisen. Keine automatische Leerung.
- [x] Textstände bei gespeicherten Änderungen an Notizen und bearbeitbaren MD/TXT,
  Vorschau und Wiederherstellung als neuer Textstand; aktuelle Metadaten bleiben.
- [x] Linkindex und vollständige Sicherung enthalten Papierkorbinhalte und Historie.
- [x] Migration, Wiederöffnen, Textkonflikte, unabhängige Sicherungsrückholung,
  fehlgeschlagene und unterbrochene endgültige Entfernung geprüft.
- [x] Native Bedienung: Textwiederherstellung, Schutz ungespeicherter Entwürfe,
  Links in den Papierkorb, Zielauswahl bei fehlendem Elternort, Abbruch und Leeren.

Textversionen entstehen bei gespeicherten Textänderungen; beim ersten Ändern eines
älteren Inhalts wird auch dessen bisheriger Stand gesichert. Es gibt keinen
rückwirkenden Verlauf und keine automatische Bereinigung. Endgültiges Entfernen
eines Inhalts entfernt auch dessen Verlauf; exportierte Sicherungen bleiben erhalten.

## Offen: Verlässlicher Alltagseinsatz

Verlustfreie Übernahme älterer Daten und getrennte Test-Arbeitsbereiche sind
verbindliche Anforderungen in [AGENTS.md](../AGENTS.md). Der konfigurierbare
Datenroot `PARA_DATA_DIR` und temporäre Test-Repositories sind bereits vorhanden;
der manuelle Entwicklungsstart ist in README.md beschrieben.

Noch offene Schutzfunktionen vor weiteren Komfortfunktionen:

1. Versionsverträglichkeit vor dem Öffnen prüfen; vollständige automatische
   Sicherung vor Datenmigrationen und nachvollziehbarer Rückfall auf die passende App-Version samt Sicherung.
2. Geführte Wiederherstellung mit Integritätsprüfung, unveränderter Rückfallkopie
   und regelmäßige versionierte Sicherungen; Wiederherstellung getrennt testen.
3. Prozessübergreifende Sperre des Arbeitsbereichs und Wiederanlauf nach
   unterbrochenen Datei-/Datenbankoperationen. Fehlerfälle wie voller Datenträger,
   fehlende Dateien und abgebrochene Migrationen gezielt prüfen.

Vorhandene Migrationstests und ein unabhängig wieder geöffneter Sicherungsexport
prüfen reguläre Abläufe. Sie ersetzen keine Prüfung der genannten Ausfälle.
Ein automatischer App-Updater bleibt ein zusätzlicher Vorschlag.
Sicherungsmanifeste enthalten bereits App- und Schemaversion.
