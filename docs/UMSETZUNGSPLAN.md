# Arbeitsstand

Stand: 25. Oktober 2026 · Version 0.6.0+6, nach Review freigegeben.

## Implementiert

- Bestätigtes Flutter-Grundlayout mit Symbolleiste, Explorer, Editor und Suche.
- Dateien/Notizen bearbeiten, importieren, verschieben und verknüpfen; unterstützte
  Vorschauen, Archiv, Papierkorb und Textverlauf gemäß README.md.
- GTD-Listen mit projektweisen nächsten Aktionen und getrenntem Aufgabenabschluss.
- Mehrere gleichberechtigte Kontexte, optionale Minuten und Energie je Aufgabe;
  kleine farbige Chips und kombinierbare Filter mit Projektgruppierung.
- Kontextverwaltung im Arbeitsbereich: Name, Farbe, Sortierung, aktiv/inaktiv.
  Vorhandene freie Kontexttexte werden verlustfrei übernommen.
- Arbeitsbereiche in Einstellungen öffnen, leer anlegen und vollständig kopieren.
  Quelle bleibt beim Kopieren erhalten; Ziel wird geprüft. Auswahl über Neustarts
  merken, macOS-Ordnerrechte erhalten, fehlende Roots ohne stillen Ersatz melden.
- Inhalte, Kontexte und gespeicherte Navigation/Filter liegen im Root. Nur lokaler
  Startverweis und Ordnerrechte liegen außerhalb. Test-Overrides bleiben getrennt.
- Schema 5: Vor älteren Datenformaten vollständige Rückfallkopie, transaktionale
  Migration aus 1–4, Sperre paralleler App-Öffnungen und Ablehnung neuerer Formate.

[Umsetzungsumfang und Prüfschritte](UMSETZUNG_0_6.md) ·
[Arbeitsbereiche](ARBEITSBEREICHE.md) · [Aufgabenangaben](GTD_AUSBAU.md).

## Prüfstand

- 59 Fach-/Widgettests erfolgreich, Codeprüfung ohne Beanstandungen.
- 13 native Mac-Bedienprüfungen erfolgreich: bisherige Editor-/Datei-/Archiv-/
  Papierkorbfunktionen und neue Aufgabenangaben, Filter und Kontextverwaltung.
- Geprüft: alte Schemas 1–4, vollständige Sicherung/Rückholung mit Links,
  Papierkorb, Textversionen, Kontextdefinitionen und gespeicherten Einstellungen.
- Geprüft: Kopieren/Öffnen/Neuanlage, getrennte Inhalte und Einstellungen,
  Neustart mit gewähltem Root und Ansicht, Wiederaufnahme nach fehlendem Ordner,
  Abbruch, belegte/verschachtelte Ziele und unveränderte bisherige Auswahl bei Fehlern.
- Geprüft: neue/unbekannte Datenformate ablehnen, zweite App-Öffnung sperren,
  Fehler beim Schreiben der lokalen Startkonfiguration, unvollständige Übernahme.
- Geprüft: nativer macOS-Ordnerkanal und ungültige Freigabedaten. Reale Vergleichsbilder
  aus getrennten Arbeitsbereichen; reguläre Nutzerdaten nicht für Tests verwenden.
- Zusätzlich manuell geprüft: Cmd+, öffnet Einstellungen; echter Ordnerdialog,
  Kopie in externen Ordner und erneutes Laden nach vollständigem App-Neustart ohne
  erneute Freigabe. Danach wieder den dauerhaften Review-Arbeitsbereich geöffnet.
- Vergleich des regulären Bestands: alle 17 zuvor erfassten Dateien und die
  ursprüngliche Startauswahl unverändert; ursprünglicher Bestand weiterhin Schema 4.

Vergleichsbilder: [Aufgaben-Chips](pruefungen/para-0.6-task-chips.png),
[Kontextverwaltung](pruefungen/para-0.6-context-settings.png),
[Arbeitsbereichseinstellungen](pruefungen/para-0.6-workspace-settings.png).

## Zur Review

Eine gesonderte Review-Version verwendet `PARA_CONFIG_DIR` mit synthetischen Daten.
Ihre Ordnerauswahl und Einstellungen bleiben beim Neustart erhalten; reguläre
Nutzerdaten und deren Startauswahl werden dadurch nicht verwendet oder verändert.
Die bisherige App ist als lokale Rückfallkopie aufbewahrt.

Zu prüfen: Chips und Aufgabenbearbeitung, Filter einschließlich fehlender Angaben,
Kontextfarben/-namen/-reihenfolge sowie Öffnen/Kopieren/Neuanlage eines Arbeitsbereichs.
Das genaue Erscheinungsbild kann im Review angepasst werden.
[Review-Anleitung](REVIEW_0_6.md).

## Weitere offene Arbeit

- Regelmäßige automatische Sicherungen, geführte Auswahl älterer Sicherungsstände,
  allgemeiner Wiederanlauf für sämtliche Datei-/Datenbankänderungen, App-Updater.
- Wochenrückblick, Projektprüfung, Wiederholungen und externe Dateiverweise sind
  weitere Vorschläge und nicht Teil dieser Umsetzung.
- Autosave, Live Preview, Mehrfachauswahl und Rückgängig bleiben offen.
- Linux/Android, Cloud-Sync und MCP sind nicht als funktionsfähig geprüft.

[Bedienung und Formatgrenzen](../README.md) · [Architektur](ARCHITEKTUR.md) ·
[Sicherung](SICHERUNG.md) · [UI-Anforderungen](UI_UMZUG.md).
