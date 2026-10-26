# Lokale Sicherung und Wiederherstellung

## Eine Sicherung erstellen

1. Offene Änderungen speichern.
2. Unten links Menü → Daten & Sicherung öffnen (oder den lokalen Statuspunkt anklicken).
3. „Sicherung erstellen“ wählen und einen Zielordner außerhalb des Arbeitsbereichs auswählen.
4. Die Bestätigung abwarten. Die App erstellt darin einen Ordner mit dem Präfix
   `PARA-Sicherung-` und einem eindeutigen Namen.

Dieser Ordner enthält `workspace.sqlite`, `notes/`, `files/`, `ingest/` und
`backup.json` (Sicherungsformat 3).
Papierkorbinhalte sind vollständig enthalten; Textversionen liegen in der Datenbank.
Das Manifest nennt Sicherungsformat, Schema- und App-Version.
Die Datenbank wird als konsistentes SQLite-Abbild exportiert. Für eine vollständige
Wiederherstellung müssen Datenbank, Notizen, Dateien und Import-Zwischenstände
zusammenbleiben.

## Eine Sicherung wiederherstellen

Die Wiederherstellung erfolgt derzeit manuell:

1. In „Daten & Sicherung“ den tatsächlich gewählten Arbeitsbereichspfad anzeigen
   lassen; der Ordner muss nicht `workspace` heißen.
2. Offene Änderungen speichern und die App vollständig beenden.
3. Den bisherigen Root umbenennen und als vollständige Rückfallkopie behalten.
4. Den gewünschten `PARA-Sicherung-…`-Ordner an den bisherigen Root-Pfad kopieren,
   mit dessen ursprünglichem Ordnernamen. Datenbank, `notes/`, `files/` und bei
   Format 3 `ingest/` müssen direkt darin liegen; nicht nur einzelne Dateien kopieren.
5. Die App erneut starten und die Inhalte prüfen.

Alternativ eine vollständige Kopie der Sicherung unter „Arbeitsbereich öffnen …“
auswählen. Das Sicherungsoriginal und den bisherigen Bestand unverändert behalten.
Ältere Sicherungsformate 1/2 ohne Importjournal bleiben übernehmbar.

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

Der Arbeitsbereich liegt außerhalb des App-Pakets: standardmäßig im
Anwendungsdatenordner oder am ausdrücklich gewählten Root-Pfad.
Beim Ersetzen der App sollen Bundle-Kennung und Datenpfad gleich bleiben;
dadurch wird derselbe Arbeitsbereich weiterverwendet. Datenbankänderungen werden
beim Öffnen migriert. Migrationen aus Schema 1–5 nach Schema 6 sind getestet.

Vor einer nötigen Datenmigration wird automatisch eine vollständige Rückfallkopie
unter `.migration-backups/Schema-…` im jeweiligen Root angelegt. Datenbank, Notizen,
Dateien und darin gespeicherte Einstellungen bleiben im alten Format erhalten.
Erst nach erfolgreicher Sicherung beginnt die transaktionale Schemaänderung.
Regelmäßige automatische Sicherungen, eine geführte Auswahl alter Sicherungsstände
und ein automatischer App-Updater fehlen derzeit.
Vor einem Versionswechsel deshalb eine vollständige Sicherung exportieren und
die bisherige App-Version aufbewahren. Ein Rückfall auf eine ältere App benötigt
den dazu passenden Datenstand; ein neuerer Arbeitsbereich ist nicht automatisch
mit älteren App-Versionen verträglich.

Eine endgültige Entfernung im Arbeitsbereich entfernt auch den dortigen Textverlauf,
aber keine Kopien aus bereits vorhandenen Sicherungen. Eine Sicherung aus Version 0.5
benötigt eine App mit Unterstützung für Schema 4 oder neuer; Sicherungen aus 0.6
benötigen Unterstützung für Schema 5.

## Arbeitsbereichseinstellungen und Sitzungszustand

Der wählbare Root enthält in 0.6 Inhalte und Arbeitsbereichseinstellungen zusammen.
Vollständige Sicherungen schließen Kontexte, Farben und gespeicherte Sitzungsdaten
in `workspace.sqlite` ein. Der lokale Verweis auf den zuletzt geöffneten Root und
macOS-Ordnerrechte werden am Zielrechner neu gesetzt. Über „Arbeitsbereich öffnen …“
lässt sich ein vollständiger Sicherungsordner als eigener Arbeitsbereich laden.
Vor einem weiteren Bearbeiten vorzugsweise eine Kopie des Sicherungsordners öffnen,
damit der Sicherungsstand selbst unverändert bleibt. [Arbeitsbereiche](ARBEITSBEREICHE.md).

## KI-Anbindung

Ab Version 0.7 enthalten Sicherungen auch die Berechtigungspräferenz `mcp.v1`
im Root. Sie aktiviert nach Rückholung keinen Zugang. Die geheime
Verbindungsdatei darf ausschließlich außerhalb von Arbeitsbereichen und
Sicherungen liegen und wird nicht mit exportiert. Kopien und Rückholungen
benötigen eine neue ausdrückliche Freigabe in der App. Seit 0.7.1 verwaltet die
App den privaten Verbindungsordner auf macOS/Linux automatisch; er gehört
weiterhin nicht zum Datenroot oder Sicherungsexport. MCP selbst ändert weder
UUIDs noch das Sicherungsformat; die Eingangsordner-Erweiterung verwendet Schema 6.

## Eingangsordner ab 0.8.0

Schema 6 ergänzt ein dauerhaftes Importjournal. Vor Migration aus Schema 1–5
wird weiterhin eine vollständige Rückfallkopie angelegt. Ein Rückfall auf 0.7.x
benötigt die alte App und ihre zugehörige Schema-5-Sicherung; die alte App darf
nicht mit dem bereits übernommenen Schema-6-Bestand verwendet werden.

Sicherungsformat 3 enthält neben Datenbank, Notizen, Dateien und Textversionen
auch `ingest/` mit Formatkennung 1 und vorhandenen Import-Zwischenkopien. Der
Export wartet auf laufende Importoperationen und nimmt einen konsistenten Stand.
Alte Sicherungen der Formate 1/2 bleiben lesbar. Unbekannte neuere Formate werden
abgelehnt. Bei Rückholung werden geprüfte Zwischenkopien ohne Originalquelle
veröffentlicht; unvollständige Kopien bleiben erhalten und werden nicht als
fertige Inhalte ausgegeben. Keine externe Quelle wird dabei umbenannt oder gelöscht.

Aktivierung/Zuordnung liegen als `ingest.sources.v1` im Root; lokale Ordnerrechte
bleiben außerhalb. Der Sicherungsexport deaktiviert die externe Quelle im
Sicherungsabbild und erneuert dessen Bindung, damit auch eine Rückholung an dieselbe
Adresse keine alte Freigabe übernimmt. Quelle am Ziel explizit erneut auswählen.
Der externe Eingangsordner samt `.para-ingest/completed/` gehört nicht zum Export;
dessen Originale separat sichern, falls sie zusätzlich aufbewahrt werden sollen.

MCP-Erweiterung 0.8.1 verwendet dieselben Repository-Speicherfunktionen und Schema 6;
keine zusätzliche Migration. Bereiche, Ressourcensammlungen und Ordner sowie deren
Texte/Links werden wie per App angelegte Inhalte gesichert. Gezielte Textänderungen
verwenden den bestehenden Textverlauf, soweit der jeweilige Inhalt ihn unterstützt.

## Dateitabs und Sitzungsübernahme ab 0.9.0

Sitzungsformat 2 (`session.v2`) speichert dauerhafte Dateitabs, Explorer-Breite,
Fokus- und Lesebreite gemeinsam mit der bisherigen Ansicht im Root. Schema 6 und
Sicherungsformat 3 bleiben erhalten. Vor Übernahme von `session.v1` legt die App
einen vollständigen konsistenten Export unter `.migration-backups/PARA-Sicherung-…`
im Root an. Dieser interne Übernahmepfad ist die einzige Ausnahme vom externen
Zielordner für normale Sicherungsexporte. Der alte Sitzungswert bleibt erhalten;
fehlgeschlagene oder unbekannte Formate werden nicht überschrieben.

Die Rückfallkopie enthält auch Texte, Anhänge, Papierkorb, Links und Textversionen.
Rückholung durch Kopieren und unabhängiges Öffnen geprüft; normale Exporte enthalten
auch die neue Sitzung. Bereits vorhandene `.migration-backups` werden nicht erneut
in Exporte hineinkopiert. Vorschautabs und ungespeicherte Entwürfe sind keine
Sicherungsinhalte. Rückfall mit passender alter App und deren Sicherungsstand.

## Suchcache ab 0.9.1

Schema 6, Sicherungsformat 3 und maßgebliche Nutzerdaten bleiben unverändert.
Die neue App übernimmt ältere Bestände ohne Schema-Konvertierung; fehlende
Format-1-Suchcachemarken werden im Hintergrund ergänzt. Sicherungen enthalten
Suchtext, Links und Cachemarken in der Datenbank. Andere Dateimetadaten nach
Rückholung lösen einen erneuten Abgleich aus. Beschädigte/veraltete Cachemarken
ersetzen keine Inhalte und dürfen neu aufgebaut werden. Währenddessen bleiben
die bisherigen Treffer/Links verfügbar. Unabhängige Rückholung wird zusammen
mit UUIDs, Texten, Anhängen, Archiv, Papierkorb und Textversionen geprüft.
