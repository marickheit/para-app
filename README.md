# P.A.R.A. Workspace

Lokale Flutter-App 0.6 für Dateien, Markdown-Notizen und GTD-Aufgaben auf macOS.
Linux-/Android-Gerüste sind vorhanden; ihre Builds und Bedienung sind noch nicht geprüft.

[Quellcode auf GitHub](https://github.com/marickheit/para-app)

## Benutzen

- **Navigation:** Oben links die Symbolleiste um Namen erweitern oder einklappen.
  Inbox, Projekte, Bereiche, Ressourcen und Archiv öffnen den jeweiligen Explorer.
  „Alle Aufgaben“ öffnet die GTD-Ansichten, darunter steht der Papierkorb. Cmd/Ctrl+\ blendet die ganze Navigation
  ein/aus; schmale Fenster öffnen sie über den Kopfzeilenbutton.
- **Explorer:** Projekte haben ein Flaggensymbol, Ordner ein Ordnersymbol.
  Ordner per Zeilenklick auf-/zuklappen; Notizen und Dateien direkt im Baum öffnen.
  Die gemeinsame Kopfzeile wechselt im Projekt zwischen Inhalten und Aufgaben.
  Ein Klick auf den Projektkopf öffnet Ergebnis, Termin und die Bearbeitung der Details.
- **Anlegen:** Plus zeigt die verfügbaren Inhaltstypen sowie Datei-/Ordnerimport.
  „Neu in: …“ nennt das Ziel. Rechtsklick auf einen Container legt darin Inhalte an.
  Cmd/Ctrl+N erstellt eine Markdown-Notiz; „Neue Textdatei …“ erstellt eine TXT-Datei.
- **Bearbeiten:** Im Dateikopf „Bearbeiten“ wählen. Markdown hat Quelltext und
  Vorschau; TXT wird als Text angezeigt. Speichern über Button oder Cmd/Ctrl+S.
  Beim Wechsel bleiben ungespeicherte Änderungen durch Speichern/Verwerfen/Abbrechen geschützt.
- **Dateiinfos:** Das kleine Info-Symbol zeigt Typ, Größe, Änderungsdatum,
  Ablageort und Suchunterstützung. Unterstützte Dateien werden rechts angezeigt.
  Bei anderen Formaten „Datei speichern …“ oder „Mit Standard-App öffnen“ verwenden.
- **Import:** Dateien oder ganze Ordner auswählen oder aus Finder/Dateimanager
  auf eine aktive Inbox, ein Projekt, einen Bereich, Ressourcen oder einen Ordner
  ziehen. Kopien bleiben im Arbeitsbereich; die Originale werden nicht geändert.
  Für ein Projekt gezielt dessen Zeile wählen, nicht die gesamte Projekt-Kategorie.
- **Verschieben:** Vorhandene Dateien/Ordner im Explorer ziehen oder per Rechtsklick/
  Drei-Punkte-Menü „Verschieben …“ wählen. Ziele können in anderen aktiven Ablagen
  liegen. Ordner nehmen ihre Inhalte mit; UUIDs und Links bleiben erhalten.
- **Aufgabenangaben:** Mehrere Kontexte je Aufgabe über „Auswählen …“ zuordnen.
  Zeitbedarf optional: 5/15/30/60/120 Minuten oder eigene positive Minuten.
  Energie optional: Niedrig/Mittel/Hoch; „Keine Angabe“ bleibt ein eigener leerer Wert.
  Kleine farbige Chips unter dem Aufgabentitel zeigen nur gesetzte Angaben.
- **Aufgabenfilter:** Der Filterbutton neben der Listenüberschrift wählt Kontexte
  (mindestens einer/alle), maximale Zeit und Energie. „Ohne Angaben einbeziehen“
  ist standardmäßig an. Aktive Filter zeigen die Trefferzahl und lassen sich
  zurücksetzen; die Projektgruppierung und Aufgabenstatus bleiben erhalten.
- **Kontexte verwalten:** Menü → Einstellungen → Aufgaben / Kontexte. Namen/Farben
  bearbeiten, neue Kontexte anlegen, mit Pfeilen sortieren oder deaktivieren.
  Umbenennen erhält Zuordnungen; deaktivierte Kontexte bleiben an vorhandenen
  Aufgaben sichtbar und filterbar. Endgültiges Entfernen von Kontextdefinitionen
  ist nicht angeboten. Alte freie Kontexttexte werden als ganze Werte übernommen.
- **Aufgaben:** Globale „Nächste Aktionen“ sind nach Projekt gruppiert, einschließlich
  Aufgaben in Unterordnern. Ohne Projekt separat. Rechtsklick/drei Punkte erlauben
  Erledigen, „Nicht mehr relevant“ und Wiederaufnehmen. Letzteres erhält den vorherigen
  Arbeitsstatus; bei alten erledigten Aufgaben ohne Historie gilt „Nächste Aktion“.
- **Irgendwann / Vielleicht:** Ideen und zurückgestellte Aufgaben haben dieselben
  passenden Aktionen, einschließlich „In Projekt umwandeln …“. Ergebnis und Datum
  sind dafür Pflicht; Text und Links bleiben erhalten.
- **Suche:** Lupe oder Cmd+F / Strg+F öffnet ein schwebendes Suchfenster; Cmd/Strg+K
  bleibt als Alternative erhalten. Unscharfe Namen sowie Notiz-/Dateitext und Kontext
  werden durchsucht. Pfeiltasten wählen, Enter öffnet, Esc schließt.
  Cmd/Ctrl+O sucht Dateien, Notizen und Ordner ausschließlich nach Namen.
- **Verknüpfen:** Im Markdown-Editor über das Link-Symbol einen Inhalt auswählen.
  Links und Rückverweise bleiben beim Umbenennen/Verschieben gültig.
- **Archiv:** Jahr und Herkunft aufklappen, anschließend ursprüngliche Ordner.
  Archivierte Inhalte sind schreibgeschützt. Rechtsklick „Wiederherstellen“ holt
  einzelne Inhalte an einen aktiven Zielort zurück. Projektabschluss archiviert das Projekt.
- **Papierkorb:** Rechtsklick oder drei Punkte → „In Papierkorb“ für Dateien,
  Notizen, Aufgaben, Ordner und Projekte. Links unter den Aufgaben öffnen. Inhalte
  sind dort schreibgeschützt und fehlen in der normalen Suche und den Aufgabenlisten.
  Interne Links öffnen weiterhin das Ziel mit Papierkorbhinweis und „Wiederherstellen“.
  Ordner nehmen ihre enthaltenen Inhalte mit; bereits separat entfernte Kinder bleiben
  bei ihrer Wiederherstellung im Papierkorb. Fehlt der bisherige Ablageort, ein anderes
  Ziel wählen. „Papierkorb leeren“ oben und „Endgültig entfernen …“ im Kontextmenü
  zeigen eine Bestätigung mit Umfang und Rückverweisen. Keine automatische Leerung.
- **Textversionen:** Das Uhr-/Verlaufssymbol im Notiz- oder Textdateikopf öffnet
  gespeicherte Textstände mit Zeitstempel und Vorschau. Eine andere Version wählen
  und „Text wiederherstellen“ bestätigen; der jüngere Text bleibt im Verlauf.
  Name, Ablage und weitere Metadaten bleiben erhalten. Ungespeicherte Änderungen
  vorher speichern, verwerfen oder abbrechen. Im Archiv/Papierkorb Verlauf nur ansehen.
  Alte Inhalte erhalten beim ersten geänderten Speichern ihren bisherigen Stand;
  neue Notizen ab Anlage. Noch ältere Texte und ungespeicherte Entwürfe werden nicht
  rekonstruiert. Kein automatisches Ausdünnen; endgültiges Entfernen des Inhalts
  entfernt auch seinen Verlauf. Textversionen ersetzen keine vollständige Sicherung.
- **Arbeitsbereich:** Menü → Daten & Sicherung (oder Cmd+, auf dem Mac) öffnet
  Einstellungen mit dem aktuellen Root. „Arbeitsbereich öffnen …“ lädt einen
  vorhandenen Ordner samt Einstellungen. „An einen anderen Ort kopieren …“ kopiert
  vollständig in einen leeren Zielordner, prüft die Kopie und öffnet sie; die Quelle
  bleibt erhalten. „Neuen Arbeitsbereich anlegen …“ benötigt ebenfalls einen leeren
  Zielordner. Bestände werden nicht zusammengeführt. Vor dem Wechsel offene Texte
  speichern, verwerfen oder abbrechen. Die Auswahl bleibt über Neustarts erhalten.
- **Gespeicherte Ansicht:** Geöffneter Inhalt, Navigation, Projekt-/Ordnerzustand und
  Aufgabenfilter werden im jeweiligen Root gespeichert. Ungespeicherte Texte werden
  weiterhin über den vorhandenen Speicher-/Wechselschutz behandelt.
- **Sicherung:** Menü unten → Daten & Sicherung; alternativ den lokalen Statuspunkt
  anklicken. Der Datenpfad und der Sicherungsexport stehen dort bereit.

## Unterstützte Dateiformate und Grenzen

- Kleine UTF-8-Markdown-Importe bis 16 MiB werden bearbeitbare Notizen.
- Kopierte TXT-/Markdown-Dateien bis 16 MiB sind direkt bearbeitbar. Binärinhalt,
  Nullbytes, andere Codierungen und größere Textdateien bleiben gewöhnliche Anhänge.
- Rasterbilder (PNG/JPEG/GIF/WebP/BMP), SVG und PDF haben Vorschau. Geschützte oder
  beschädigte PDFs gegebenenfalls mit der Standard-App öffnen.
- CSV: Vorschau bis 200 Zeilen / 20 Spalten, einschließlich zitierter Felder;
  keine Tabellenbearbeitung. Textsuche in UTF-8-CSV bis 16 MiB.
- PDF-Suche: auslesbarer Text, erste 100 Seiten und höchstens 2 MiB Text bei Dateien
  bis 100 MiB. Keine Bildtexterkennung/OCR. Andere Dateien bleiben nach Namen suchbar.
- Der Suchindex wird beim Öffnen wieder aufgebaut und beim Speichern/Import aktualisiert.
- Keine automatische Cloud-Synchronisierung, Wiederholungen oder Erinnerungen.

## Lokal entwickeln

Voraussetzung: Flutter, Xcode und die macOS-Plattformwerkzeuge.

```sh
flutter pub get
flutter pub run build_runner build
flutter run -d macos --dart-define=PARA_DATA_DIR="$HOME/Library/Containers/dev.para.paraWorkspace/Data/tmp/para-dev"
```

Eigenständig startbare App bauen:

```sh
flutter build macos --release
```

Ergebnis: `build/macos/Build/Products/Release/PARA.app`.
Notiztexte liegen unter `notes/`, importierte Dateien unter `files/`;
`workspace.sqlite` speichert Struktur und Metadaten. Den tatsächlichen Datenpfad
zeigt „Daten & Sicherung“. [Datensicherung](docs/SICHERUNG.md).

## Prüfen

```sh
flutter analyze
flutter test
flutter test -d macos integration_test/workspace_test.dart
```

Nach Änderungen an Drift-Tabellen die Bindings erneut erzeugen.
Automatisierte Prüfungen verwenden getrennte temporäre Arbeitsbereiche und
verändern keine Nutzerdaten. Für manuelle Entwicklung ebenfalls einen eigenen
Datenordner wählen, beispielsweise im beschreibbaren macOS-App-Container:

```sh
flutter run -d macos --dart-define=PARA_DATA_DIR="$HOME/Library/Containers/dev.para.paraWorkspace/Data/tmp/para-dev"
```

`PARA_DATA_DIR` bestimmt den vollständigen Arbeitsbereich mit Datenbank, Notizen
und Dateien. Er wird beim Start angelegt; der Pfad muss für die App beschreibbar
sein. Unter macOS gelten dabei die App-Zugriffsrechte. Der Wert wird beim Bauen
festgelegt; zum Ändern neu starten/bauen. Ohne diesen Wert verwendet die App den
regulären Anwendungsdatenordner. Der tatsächliche Pfad steht in „Daten & Sicherung“.
Ein anderer Datenordner kopiert oder konvertiert vorhandene Daten nicht automatisch.
Den temporären Entwicklungsordner nicht für die dauerhafte eigene Ablage verwenden.

Ohne festen Test-Datenpfad ist der Root über Einstellungen wählbar. Mit
`PARA_DATA_DIR` sind Ordnerwechsel deaktiviert und der regulär gemerkte Root bleibt
unverändert. Für eine isolierte Review mit funktionsfähiger Ordnerauswahl kann
`PARA_CONFIG_DIR` einen eigenen Startkonfigurationsordner festlegen. Dessen
Standard-Arbeitsbereich liegt dann ebenfalls in diesem getrennten Ordner.
Das Werkzeug `tool/create_review_workspace.dart` legt ausschließlich in einem
leeren Zielordner synthetische Beispieldaten und den passenden Startverweis an.

Der [Arbeitsbereich](docs/ARBEITSBEREICHE.md) enthält Inhalte, Kontexte/Farben und
Sitzungszustand in `workspace.sqlite`, Notizen unter `notes/`, Anhänge unter `files/`.
Außerhalb liegen nur Startadresse und macOS-Ordnerfreigabe in
`workspace-location.json` im Anwendungsdatenordner. Ist der zuletzt gewählte Root
nicht verfügbar, bietet die App Wiederholen oder eine erneute Ordnerauswahl an.
Sie legt dort keinen stillen Ersatzbestand an.

## Datenkompatibilität

Bestehende Daten sollen bei der Weiterentwicklung erhalten bleiben. Neue
Versionen müssen ältere Arbeitsbereiche direkt lesen oder verlustfrei migrieren;
das gilt auch für Links, Papierkorb und Textverlauf. Die verbindlichen
Entwicklungsregeln stehen in [AGENTS.md](AGENTS.md).

Aktuell: Schema 5, getestete Migrationen aus Schema 1–4 und vollständiger
Sicherungsexport. Vor einer nötigen Datenmigration erstellt die App automatisch
eine vollständige Rückfallkopie unter `.migration-backups/` im jeweiligen Root.
Unbekannte neuere Datenformate und paralleles Öffnen werden abgefangen.
Regelmäßige automatische Sicherungen und eine geführte Auswahl von Sicherungsständen
fehlen noch. Ein Rückfall auf eine alte App benötigt deren passenden Datenstand. [Details](docs/SICHERUNG.md).

Git versioniert Quellcode, Dokumentation und synthetische Prüfdaten. Lokale
Arbeitsbereiche, Sicherungen und Build-Ergebnisse sind ausgeschlossen.

[Produktstand](PLANUNG.md) · [UI-Anforderungen](docs/UI_UMZUG.md) ·
[Umsetzungsplan](docs/UMSETZUNGSPLAN.md) · [Architektur](docs/ARCHITEKTUR.md)
