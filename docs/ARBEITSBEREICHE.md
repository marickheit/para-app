# Vollständige Arbeitsbereiche

Stand 0.10.0: Arbeitsbereiche lassen sich über Einstellungen öffnen, neu anlegen und
kopieren. Inhalte, Einstellungen und Sitzungszustand werden gemeinsam geladen;
die Auswahl bleibt über Neustarts erhalten.

## Ein Ordner enthält den Arbeitsbereich

Im gewählten Root liegen alle fachlichen Daten und Einstellungen:

- Datenbank, Aufgaben, Projekte, Ablagestruktur und interne Verknüpfungen.
- Notiztexte, importierte Dateien, Archiv, Papierkorb und Textversionen.
- Kontexte mit Namen/Farben und die weiteren Arbeitsbereichseinstellungen.

Die gespeicherte Sitzung enthält ab 0.9.0 dauerhafte Dateitabs/Reihenfolge,
zuletzt geöffneten Inhalt, Navigationszustand, Aufgabenfilter,
Explorer-Breite/-Sichtbarkeit und Textlesebreite. Vorschautabs werden nicht wiederhergestellt. Ungespeicherte Entwürfe
automatisch wiederherzustellen ist damit noch nicht ausgewählt; vor einem
Arbeitsbereichswechsel greift Speichern/Verwerfen/Abbrechen.

Die Speicheraufteilung umfasst `workspace.sqlite`, `notes/`, `files/` und seit
Schema 6 `ingest/` für Import-Zwischenstände. Ältere Bestände bleiben übernehmbar. Kontextdefinitionen und versionierte Sitzungsdaten liegen ebenfalls
in `workspace.sqlite` (aktuell Schema 6; Einstellungstabelle seit Schema 5). Vorhandene Arbeitsbereiche ohne diese
Angaben erhalten kompatible Voreinstellungen; vorhandene Daten nicht ersetzen.
Sitzungsformat 2 übernimmt Format 1 nach vollständigem Rückfallexport innerhalb
des Roots unter `.migration-backups/`. Der alte Einstellungswert bleibt erhalten.
Unbekannte neuere/beschädigte Sitzungen bleiben unangetastet; ihre automatische
Speicherung wird gesperrt. Inhalte bleiben lesbar und bearbeitbar.

Abgeleitete Format-1-Suchcachemarken liegen ebenfalls in der Datenbank.
Seit 0.9.1 werden vorhandene Treffer sofort verwendet und geänderte Inhalte nach
Öffnung im Hintergrund abgeglichen. Fehlende/veraltete Marken lösen keine
Inhaltsmigration aus. Externe Eingangsordner samt Original-Rückholbereich liegen
außerhalb der Arbeitsbereichssicherung; lokale Quellenrechte werden nicht mitkopiert.

## Öffnen und über Neustarts merken

Aktion: Einstellungen → Daten & Sicherung → „Arbeitsbereich öffnen …“.
Der Nutzer wählt einen vollständigen Arbeitsbereichsordner. Nach Prüfung lädt die
App dessen Inhalte und Einstellungen gemeinsam. Vorherige und neue Bestände
werden nicht automatisch zusammengeführt. Die Auswahl wird erst nach erfolgreichem
Öffnen dauerhaft als aktueller Arbeitsbereich gespeichert.

Beim nächsten App-Start wird derselbe Arbeitsbereich wieder geöffnet. Fehlt das Laufwerk
oder die Berechtigung, „Arbeitsbereich nicht verfügbar“ mit Erneut versuchen bzw.
Ordner auswählen anbieten. Niemals an dieser Stelle still einen leeren Bestand anlegen.

Eine kleine lokale Startkonfiguration liegt außerhalb des wechselbaren Roots:
Sie merkt ausschließlich die zuletzt geöffnete Ordneradresse und die dafür nötige
geräteabhängige macOS-Ordnerberechtigung (Bookmark). Fachliche Einstellungen bleiben
im Arbeitsbereich. Dadurch kann die App den Root vor dem Laden seiner Einstellungen
finden. Auf einem anderen Rechner wird der Ordner einmal neu ausgewählt/freigegeben.

`PARA_DATA_DIR` hat für Entwicklungsstarts Vorrang und darf den regulär zuletzt
gewählten Root nicht verändern. Test-Arbeitsbereiche und ihre Einstellungen
bleiben vollständig vom Nutzerbestand getrennt.

## Neu anlegen, kopieren und öffnen unterscheiden

- „Arbeitsbereich öffnen …“ lädt einen vorhandenen Bestand an Ort und Stelle.
- Ein neuer leerer Arbeitsbereich braucht eine ausdrückliche Anlageaktion.
- Beim Übernehmen an einen neuen Ort vollständig kopieren und prüfen; das Original
  zunächst als Rückfallbestand behalten. Ein Umzug übernimmt auch Einstellungen.
- Unbekannte neuere Formate ablehnen; ältere Daten bei Bedarf erst nach vollständiger
  Rückfallkopie verlustfrei migrieren. Fehlende Dateien verständlich melden.
- Immer nur einen Arbeitsbereich gleichzeitig aktiv öffnen. Gleichzeitige Nutzung
  desselben Bestands durch mehrere Prozesse wird über eine Ordnersperre abgefangen.

## Sicherung und Prüfumfang

Vollständige Sicherungen enthalten auch Arbeitsbereichseinstellungen und
gespeicherte Sitzungsdaten. Die geräteabhängige Startadresse/Ordnerfreigabe
ist keine Voraussetzung zum Öffnen einer Sicherung an einem anderen Ort. Eine
vollständige Ordnerkopie nur bei geschlossener App erstellen; bei laufender App den
konsistenten Sicherungsexport verwenden. Eine portable Ablage ist noch kein Sync.

Geprüft mit getrennten Arbeitsbereichen: Wechsel zwischen zwei Arbeitsbereichen mit unterschiedlichen
Inhalten/Einstellungen, Neustart, erneute Ordnerfreigabe, fehlendes Laufwerk,
Abbruch und ungespeicherte Änderungen, Übernahme älterer Daten, neuere unbekannte
Formate, unterbrochene Übernahme und unabhängige Rückholung einer Sicherung.

[Umsetzungsplan](UMSETZUNGSPLAN.md) · [Sicherung](SICHERUNG.md) ·
[GTD-Einstellungen](GTD_AUSBAU.md)

Die lokale Startkonfiguration ist `workspace-location.json` im Anwendungsdatenordner
und enthält Formatversion 1, Root-Pfad und optional die macOS-Ordnerfreigabe.
Vor Migration älterer Daten legt die App `.migration-backups/Schema-…` im Root an.
Eine beim Kopieren unterbrochene Zielübernahme ist durch `.para-transfer` markiert
und wird nicht als fertiger Arbeitsbereich geöffnet. Die Quelle bleibt verfügbar.
