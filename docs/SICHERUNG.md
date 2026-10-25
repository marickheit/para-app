# Lokale Sicherung und Wiederherstellung

## Eine Sicherung erstellen

1. Offene Änderungen speichern.
2. Unten links Menü → Daten & Sicherung öffnen (oder den lokalen Statuspunkt anklicken).
3. „Sicherung erstellen“ wählen und einen Zielordner außerhalb des Arbeitsbereichs auswählen.
4. Die Bestätigung abwarten. Die App erstellt darin einen Ordner mit dem Präfix
   `PARA-Sicherung-` und einem eindeutigen Namen.

Dieser Ordner enthält `workspace.sqlite`, `notes/`, `files/` und `backup.json`.
Papierkorbinhalte sind vollständig enthalten; Textversionen liegen in der Datenbank.
Das Manifest nennt Sicherungsformat, Schema- und App-Version.
Die Datenbank wird als konsistentes SQLite-Abbild exportiert. Für eine vollständige
Wiederherstellung müssen Datenbank, Notizen und Dateien zusammenbleiben.

## Eine Sicherung wiederherstellen

Die Wiederherstellung erfolgt derzeit manuell:

1. In der App „Daten & Sicherung“ öffnen und den Datenordner anzeigen lassen.
2. Die App vollständig beenden.
3. Den bisherigen Ordner `workspace` umbenennen und als Rückfallkopie behalten.
4. Den gewünschten `PARA-Sicherung-…`-Ordner an dieselbe Stelle kopieren und die
   Kopie `workspace` nennen. Darin liegen direkt `workspace.sqlite`, `notes/`
   und `files/`.
5. Die App erneut starten und die Inhalte prüfen.

Die bisherige Rückfallkopie und das Original der Sicherung bleiben dabei erhalten.
Die Sicherung wird automatisiert geprüft, indem sie unabhängig als Arbeitsbereich
geöffnet und auf Texte, Dateien sowie Verknüpfungen kontrolliert wird.

## Updates und aktuelle Grenzen

Verbindliche Entwicklungsregel: Neue Versionen übernehmen ältere Arbeitsbereiche
und Sicherungen direkt oder über eine verlustfreie Migration/Konvertierung.
Identitäten und interne Links sowie Papierkorb und Textversionen bleiben erhalten.
Vor Änderungen am echten Bestand ist eine vollständige Rückfallkopie erforderlich;
Konvertierungen werden zuerst an getrennten Testdaten geprüft. Diese Regeln sind
in [AGENTS.md](../AGENTS.md) festgehalten.

Der Arbeitsbereich liegt außerhalb des App-Pakets im Anwendungsdatenordner.
Beim Ersetzen der App sollen Bundle-Kennung und Datenpfad gleich bleiben;
dadurch wird derselbe Arbeitsbereich weiterverwendet. Datenbankänderungen werden
beim Öffnen migriert. Migrationen aus Schema 1, 2 und 3 sind getestet.

Eine automatische Sicherung vor Migrationen, regelmäßige automatische Sicherungen,
eine geführte Wiederherstellung und ein automatischer App-Updater fehlen derzeit.
Vor einem Versionswechsel deshalb eine vollständige Sicherung exportieren und
die bisherige App-Version aufbewahren. Ein Rückfall auf eine ältere App benötigt
den dazu passenden Datenstand; ein neuerer Arbeitsbereich ist nicht automatisch
mit älteren App-Versionen verträglich.

Eine endgültige Entfernung im Arbeitsbereich entfernt auch den dortigen Textverlauf,
aber keine Kopien aus bereits vorhandenen Sicherungen. Eine Sicherung aus Version 0.5
benötigt eine App mit Unterstützung für Schema 4 oder neuer.
