# Lokale Architektur

## Zuständigkeiten

- `lib/domain/workspace.dart`: Inhaltsmodell, Projekt-/Aufgabenbegriffe,
  Linkformat und Repository-Schnittstelle. Keine Flutter-Abhängigkeit.
- `lib/data/`: SQLite-Schema, Markdown-Dateien, Dateiimport, Such- und
  Linkindizes, Sicherung. Mutationen werden innerhalb einer Repository-Instanz
  nacheinander ausgeführt.
- `lib/services/`: gemeinsamer Dateiimport, begrenzte UTF-8-Auswertung und
  injizierte PDF-Textextraktion. `lib/domain/search.dart` bewertet unscharfe Namen
  und Inhaltstreffer ohne Flutter-Abhängigkeit.
- `lib/ui/`: Navigation, Dialoge und Editor. Die Oberfläche verwendet die
  Repository-Schnittstelle; SQLite ist kein Bestandteil der UI-Verträge.

`mcp/` enthält den lokalen TypeScript-stdio-Server. Er ruft die authentifizierte,
versionierte Loopback-Bridge der laufenden App auf und öffnet selbst keine
Nutzdateien oder Datenbank. `mcp_access_service.dart` prüft Freigaben und führt
Werkzeuge innerhalb `WorkspaceRepository.exclusive` aus. Die Warteschlange ist
für verschachtelte Repository-Aufrufe innerhalb derselben Operation wiedereintrittsfähig.
Konsistente Snapshots bündeln Text, Hash und Revision; der Editor übernimmt den
tatsächlich gespeicherten Snapshot. `mcp_editor_guard.dart` koordiniert
Editorentwürfe, Laden/Speichern und MCP-Änderungen. Seitencursor sind an das
jeweilige Ergebnis und die App-Öffnung gebunden.
`create_project` nutzt die bestehende Repository-Anlage mit Ergebnis und gültigem
Kalenderdatum; Ziel ist fest die oberste Projektebene. App und MCP prüfen die
Pflichtangaben unabhängig. Keine Änderung an Schema 5 oder Sicherungsformat.

Die Freigabepräferenz `mcp.v1` liegt versioniert in `workspace_settings` und
aktiviert keinen Zugang. Token, Port und Öffnungskennung sind flüchtig; die
lokale 0600-Verbindungsdatei liegt automatisch in einem privaten 0700-Ordner
außerhalb des Roots. Linux nutzt XDG State, macOS den stabilen App-Container;
App und stdio-Server verwenden denselben Plattformstandard. Explizite alte
Dateipfade bleiben im Server unterstützt. Native Schreiber veröffentlichen die
Datei atomar und lehnen Symlinks, fremde Eigentümer und unsichere Bestandsdateien ab. Rootwechsel widerruft
Verbindungen vor der Übernahme und wartet laufende Schreiboperationen ab.
[Bedienung und Grenzen](MCP.md).

## Daten

Der reguläre Arbeitsbereich liegt im Anwendungsdatenordner, außerhalb des
App-Pakets. `PARA_DATA_DIR` kann beim Bauen einen anderen vollständigen Datenroot
festlegen; automatisierte Tests übergeben eigene temporäre Verzeichnisse direkt
an das Repository. Die Auswahl eines anderen Roots ist keine Datenmigration.
Manuelle Entwicklungsstarts verwenden ebenfalls einen getrennten Root;
Startbeispiel und macOS-Zugriffsgrenzen stehen in [README.md](../README.md).

Arbeitsbereichsmodell in 0.6: Alle Inhalte und Arbeitsbereichseinstellungen liegen in
einem wählbaren Root. Nur Startverweis auf den zuletzt geöffneten Arbeitsbereich
und geräteabhängige Ordnerberechtigungen bleiben außerhalb. Sitzungszustand, Auswahl, Persistenz über Neustarts
und Einstellungsübernahme sind implementiert;
siehe [Arbeitsbereichskonzept](ARBEITSBEREICHE.md).

Jeder Inhalt besitzt eine UUID, Art, Hauptablageort, Zeitstempel und Revision.
Ordner können verschachtelt werden; zyklische Verschiebungen werden abgelehnt.
Projekte benötigen Ergebnis und kalendarisches Fälligkeitsdatum. Ideen sind ein
separater Inhaltstyp; ein Projekt hat keinen Irgendwann-Status.

Notiztexte und Beschreibungen sind `notes/<UUID>.md`. SQLite enthält ihre
Metadaten und eine abgeleitete Kopie für die Suche. Importierte Dateien liegen
unter `files/<UUID>/<Dateiname>`. Datei-Umbenennung ändert den Namen innerhalb
dieses UUID-Ordners; reine Textspeicherung erhält bestehende Anzeigenamen und Endungen. Die Datenbank enthält keine Datei-BLOBs.
UUID-Dateinamen halten Speicherpfade unabhängig von sichtbaren Titeln.

Textdateien werden zunächst temporär geschrieben und dann umbenannt. Der Editor
prüft Revision und Text-Hash vor dem Speichern und verweigert das Überschreiben
veralteter oder extern geänderter Texte. Fehlende Markdown-Dateien werden als
Fehler angezeigt. Externe Bearbeitung während der Benutzung wird nicht live
überwacht; beim erneuten Öffnen der App werden Such- und Linkindizes neu aufgebaut.

Das Arbeitsverzeichnis ist derzeit für einen laufenden App-Prozess vorgesehen.
Ein exklusiver Dateilock (`.para.lock`) und eine zusätzliche Sperre im Prozess
verhindern paralleles Öffnen durch diese App-Version. Das ist kein Sync-Protokoll;
ältere App-Versionen oder fremde Programme beachten diese Sperre nicht automatisch.

## Aufgabenangaben und Einstellungen

Schema 5 ergänzt `context_ids` (Liste stabiler Kontextkennungen), `estimated_minutes`
und `energy` an Inhalten sowie `task_contexts` und `workspace_settings`. Freie
bisherige Kontexttexte werden als ganze Werte übernommen, auch an archivierten
und entfernten Inhalten. Die Textspalte `context` bleibt als abgeleitete Beschriftung
für Suche und ältere Repository-Aufrufe erhalten. Umbenennen aktualisiert sie,
ohne Zuordnungen oder Kontextkennungen zu ersetzen.

Kontexte haben Namen, Farbe, Position und aktiv/inaktiv. Deaktivieren erhält
vorhandene Zuordnungen; neue Zuordnungen zu inaktiven Kontexten werden abgelehnt.
Text-/Metadatenänderungen verwenden weiterhin Revisions-/Hashschutz. Ein gezieltes
Bearbeiten der Aufgabenangaben kann Zeit und Energie leeren; ältere Speicheraufrufe
überschreiben diese neuen Felder nicht implizit.

`workspace_settings` speichert `session.v1` mit Ansicht, Auswahl, Navigation,
Ordnerzustand und Aufgabenfilter. UI-Änderungen werden verzögert gespeichert;
vor Arbeitsbereichswechsel und regulärem Beenden wird ausstehender Zustand geschrieben.
Ungespeicherte Editorentwürfe werden nicht als Sitzung serialisiert.

## Aufgabenabschluss

Schema 3 ergänzt `previous_task_state`; `cancelled` ist neben `done` ein eigener
Abschlussstatus. Der vorherige offene Status bleibt beim Abschluss erhalten, auch
bei einem Wechsel zwischen Abschlussarten. Wiederaufnahme stellt ihn wieder her.
Alte Abschlüsse ohne Historie verwenden als UI-Rückfall „Nächste Aktion“.

## Archiv und Umwandlung

Schema-Version 2 ergänzt Archivierungszeit und gespeicherte Herkunft. Bestehende
Archive werden migriert; ihr bisheriger Änderungszeitpunkt dient als Archivdatum.
Die Herkunft enthält das lokale Kalenderjahr und einen Schnappschuss der
übergeordneten Ablage. Umbenennen oder Verschieben aktiver Vorfahren verändert
dadurch nicht nachträglich die archivierte Herkunft.

Die Archivoberfläche baut daraus virtuelle Ordner mit stabilen Schlüsseln auf.
Dateien werden nicht in zusätzliche Jahresordner kopiert. Wiederherstellen
erhält die UUID; einzelne Inhalte aus archivierten Vorfahren können an einen
neuen aktiven Ablageort zurückgeholt werden.

Ideen und zurückgestellte Aufgaben lassen sich in Projekte umwandeln. Die
Operation verlangt Ergebnis und Datum, ändert die Metadaten, erhält aber UUID,
Markdown-Datei und eingehende sowie ausgehende Links.

## Import und direkte Bedienung

Dateiauswahl und Drag-and-drop verwenden denselben Import-Service. Kleine
UTF-8-Markdown-Dateien werden zu Notizen. Sonstige Dateien werden gestreamt;
Ordner werden rekursiv übernommen. Symlinks innerhalb importierter Ordner werden
nicht verfolgt. Quelldateien bleiben unverändert.

Ein nativer Drop-Empfänger verteilt Dateien auf registrierte Ziele. So wird ein
Drop auf einen Unterordner nicht zusätzlich vom umgebenden Projekt importiert.
Scroll-Clipping wird berücksichtigt. macOS-Dateizugriff über Bookmarks bleibt
bis zum Abschluss des Imports geöffnet. Interne Drags verschieben vorhandene
Objekte über dieselbe Repository-Schnittstelle.

Ein gemeinsames Aktionsmodell erzeugt Drei-Punkte- und Rechtsklick-Menüs,
einschließlich Anlage/Import in Containern und Aufgabenabschluss. Der native
macOS-Find-Menüpunkt leitet an `para.workspace/menu` weiter; die globale Suche
ist dadurch auch über das Systemmenü erreichbar.

PDF-Vorschau/-Text verwendet pdfrx/PDFium, SVG flutter_svg und die Oberfläche
Lucide-Symbole. Die Anwendung lädt dafür keine entfernten Dokumente. PDF-Text
wird begrenzt ausgewertet; UTF-8-TXT/MD und CSV werden ebenfalls indiziert.
Die Kopie in SQLite ist ein abgeleiteter Index, die lokale Datei bleibt maßgeblich.

## Papierkorb und Textversionen

Schema 4 ergänzt `trash_batch_id`, `trash_location`, `trash_archived` und die Tabelle `note_versions`.
Das vorhandene `deleted_at` trennt Papierkorbinhalte von normalen Abfragen.
Jeder Papierkorbvorgang markiert nur den aktuell nicht entfernten Teilbaum mit
einer eigenen Gruppe. Wiederherstellen eines Teilbaums berücksichtigt nur diese
Gruppe; vorher separat entfernte Nachkommen bleiben im Papierkorb. Der bisherige
Elternverweis bleibt bestehen. Eigene Archivmarkierungen bleiben von geerbtem
Archivstatus getrennt; bei Rückholung an einen anderen Ort wird der frühere
Archivstatus nötigenfalls auf der zurückgeholten Wurzel gesetzt.
Bei unzugänglichem Elternobjekt ist ein neues
zulässiges Ziel nötig. UUIDs, Bytes, Aufgaben- und Archivstatus bleiben erhalten.

Endgültiges Entfernen eines Containers umfasst alle noch entfernten Nachkommen,
auch aus früheren Vorgängen. Dateien werden mit Manifest in ein temporäres
`.purging-<UUID>`-Verzeichnis verschoben, bevor die Datenbank sie samt Links und
Textversionen entfernt. Beim Wiederanlauf werden Bytes bei noch bestehenden
Datensätzen zurückgelegt; nach erfolgreichem Datenbankabschluss werden Restbytes
aufgeräumt. Das ist eine Wiederanlaufhilfe für endgültige Entfernung, kein allgemeines
Absturzjournal für sämtliche Schreiboperationen.

Textversionen enthalten Kennung, Inhaltskennung, damaligen Titel, UTF-8-Text,
SHA-256 und Zeitstempel. Eine fortlaufende Sequenz hält auch unmittelbar aufeinander
folgende Speicherungen in richtiger Reihenfolge. Notizen bekommen einen Anfangsstand;
bei älteren Notizen und bearbeitbaren MD/TXT wird der beobachtete alte Text vor
seiner ersten Ersetzung gesichert. Erfolgreiche Textänderungen ergänzen einen Stand,
reine Metadatenänderungen und identischer Text erzeugen keine Duplikate.
Wiederherstellen verwendet denselben Revisions-/Hashschutz wie Speichern und ändert
nur den Text. Historie bleibt auch im Archiv/Papierkorb lesbar, dort nicht rückspielbar.
Es gibt keine automatische Bereinigung; Datenbank und Sicherungen wachsen mit den Textständen.

## Links

Interne Markdown-Links verwenden `[Titel](para://entry/<UUID>)`.
Das Ziel wird über die UUID aufgelöst. Umbenennen und Verschieben verändern
seine Identität nicht. Die sichtbare Beschriftung bestehender Markdown-Links wird
nicht automatisch umgeschrieben. Rückverweise zeigen aktuelle Zieltitel an.
Papierkorbziele bleiben im Linkindex und sind mit Hinweis erreichbar; endgültig
entfernte Ziele werden als nicht verfügbar behandelt. Code und bloßer Text werden beim Aufbau des Linkindex nicht als Links behandelt.

Externe Web- und Mail-Links werden bei einem Klick an die Standard-Anwendung
übergeben. Die Markdown-Vorschau lädt externe Bilder nicht automatisch.

## Sicherung

Eine SQLite-Sicherung wird über `VACUUM INTO` erstellt. Notizen und Dateien
einschließlich Papierkorb werden dazu kopiert, während weitere App-Schreibvorgänge warten.
Das SQLite-Abbild enthält alle Textversionen; das Manifest nennt Schema- und App-Version. Eine Sicherung
wird erst nach vollständigem Kopieren unter ihrem endgültigen Ordnernamen sichtbar.
Große Dateien werden gestreamt beziehungsweise als Dateien kopiert.
Die Sicherung enthält keine Zugangsdaten; es gibt noch keine Cloud-Anmeldung.

## Aktuelle Grenzen

Cloud-Sync, Konfliktauflösung zwischen Geräten, Benachrichtigungen und
wiederkehrende Aufgaben folgen später. PDF, Rasterbilder, SVG, Markdown/Text und CSV haben die in README.md beschriebenen
Vorschauen. Für andere Formate bleibt die Standard-App oder ein lokaler Export.
Die Sicherung ist ein lokaler Export mit dokumentierter manueller Wiederherstellung.

## Verbindliche Kompatibilitätsregeln

Neue App-Versionen müssen ältere Arbeitsbereiche und Sicherungen direkt lesen
oder verlustfrei konvertieren. Jede Änderung des maßgeblichen Datenformats braucht
Versionierung, Übernahmepfad, Prüfungen älterer Daten und aktualisierte Dokumentation.
Identitäten, Linkziele, Dateiinhalte, Aufgabenstatus, Archiv, Papierkorb und
Textverlauf bleiben erhalten. Nur abgeleitete Indizes dürfen verworfen und neu
aufgebaut werden. Unbekannte neuere Datenstände dürfen nicht durch Zurücksetzen
behandelt werden. Diese Vorgaben stehen in [AGENTS.md](../AGENTS.md).

Implementierter Stand: Schema 6 mit getesteten Migrationen von 1–5. Vor der
Migration prüft `workspace_storage.dart` Version, Datenbank und Dateipfade, sperrt
den Root und erstellt eine konsistente vollständige Rückfallkopie. Migrationen
laufen in einer Datenbanktransaktion. Nicht unterstützte neuere Versionen werden
vor ihrer Öffnung abgelehnt. `workspace_manager.dart` aktiviert eine neue Auswahl
erst nach erfolgreichem Öffnen und atomarem Schreiben des lokalen Startverweises.
Beim Kopieren werden Dateien gegen den Sicherungsschnappschuss per SHA-256 geprüft.

Regelmäßige automatische Sicherungen, geführte Auswahl früherer Sicherungsstände
und ein allgemeines Absturzjournal für alle Datei-/Datenbankänderungen bleiben offen.

## Auswahl und Anlageziele

Seit 0.7.3 bestimmen `_rootId`, `_selectedId` und der Elterncontainer einer
geöffneten Datei das sichtbare Anlageziel. Kein separat gemerktes Ordnerziel.
Kategorie-Wechsel setzt die Auswahl zurück; Container öffnen zunächst die
Übersicht und klappen auf. Erneuter Klick schließt den Container und öffnet den
Elterncontainer oder die Kategorieübersicht. Der Editor-Wechselschutz gilt auch
für diese Übergänge. Die bestehenden session.v1-Felder speichern die Auswahl
weiterhin; keine Schema-/Speicherformatänderung.

Plus und Cmd/Ctrl+N verwenden gemeinsame Typ-/Zielregeln. Projekt, Bereich,
Ressourcensammlung und Idee haben feste Ablagen. Gewöhnliche Inhalte verwenden
ein explizites Zielobjekt aus Kategorie und optionaler Eltern-ID; ein bewusst
leerer Elternwert ersetzt ein vorher ausgewähltes Ordnerziel vollständig.
Kontextaktionen übergeben das angeklickte Ziel. Inhalt-/TXT-Dialog und Import
zeigen den vollständigen Pfad und können gültige aktive Ziele auswählen.
Projektwurzel ist kein Ziel für gewöhnliche Inhalte. Bereits vorhandene freie
Wurzelinhalte in Bereiche/Ressourcen bleiben zulässig. Lokale Neuanlage ist im
Archiv/Papierkorb und in abgeschlossenen Aufgabenlisten deaktiviert.

## Automatischer Eingang

`InboxIngestService` ist an eine Repository-Instanz gebunden. Er verwaltet eine
lokale Quellenfreigabe, eine Quellensperre und begrenzte, rekursive Kontrollscans;
Root-Dateisystemereignisse stoßen zusätzliche Scans an. Tiefe Änderungen werden
auch ohne Ereignis erkannt, spätestens beim nächsten Kontrollscan. Kein rekursiver
Linux-Watcher pro Unterordner erforderlich. Der Manager hält den Dienst vor einem
Rootwechsel an, wartet laufende Übernahmen ab und beendet ihn vor Repositoryschluss.
Import und Export laufen in derselben exklusiven Repository-Warteschlange.

Schema 6 ergänzt `ingest_jobs` mit versioniertem Payload (Format 1). Jobs enthalten
stabile Inhalts-UUIDs, relative Pfade, Elternbeziehungen, Quellensignaturen und
Prüfsummen. Unter `ingest/<job-UUID>/` liegen bytegetreue Zwischenkopien. Nach Prüfung
werden Inhaltsdatensätze und Journalzustand gemeinsam veröffentlicht. Ein gescheiterter
Datenbankabschluss lässt den Job unveröffentlicht; vorhandene Zielkennungen werden
nicht überschrieben. Der Suchindex ist abgeleitet und wird nach Veröffentlichung
aktualisiert beziehungsweise beim nächsten Öffnen neu aufgebaut.

Native Linux-/macOS-Funktionen verwenden Dateiidentitäten und kopieren im Hintergrund
mit `O_NOFOLLOW`, exklusiver Zielanlage und `fsync`. Der während des Lesens
gebildete SHA-256 wird gegen die erneut gelesene Zwischenkopie geprüft. Quellverschiebungen überschreiben
keine vorhandenen Ziele. Originale bleiben unter dem privaten `.para-ingest/completed/`
der Quelle erhalten; vor/nach dem Verschieben wird der Baum erneut verglichen.
Die Ruhephase ist eine Heuristik, kein Beweis, dass ein Erzeuger fertig ist.
Der automatische Eingang löscht keine Originale endgültig.

Fachliche Zuordnung `ingest.sources.v1` liegt im Root. In der Startkonfiguration
liegen daneben nur die geräteabhängigen Ordnerfreigaben in
`ingest-directory-grants.json`, gebunden an kanonischen Root, Quelle und Bindungs-ID.
Format-3-Sicherungen nehmen Zwischenkopien mit und invalidieren im Abbild die
Quellenbindung. Verifizierte interne Zwischenstände können unabhängig fertiggestellt
werden; externe Quellenbereinigung setzt eine gültige aktuelle lokale Bindung voraus.

## MCP-Ablage und kompakte Antworten (0.8.1)

API-Funktionsstand 2 ergänzt Bereichs-, Ressourcen- und Ordneranlage sowie
Metadatenänderung und exaktes Anhängen/eindeutiges Ersetzen von Textstellen.
Alle Schreibpfade verwenden die exklusive Repository-Warteschlange,
`saveSnapshot`, Wiederholungserkennung und Editorschutz. Binärdateien können
bytegleich umbenannt werden. Projektpflichten und feste Hauptablagen bleiben.
Kein neues Datenformat; Schema 6 und Bridgeformat 1 bleiben erhalten.

Listen projizieren erst nach vollständigem Cursorfingerabdruck auf kompakte
Metadaten. Standard 20 Treffer, vollständige Felder auf Abruf. Textabschnitte
standardmäßig 4.000 UTF-16-Codeeinheiten; Text und Listen jeweils maximal 64 KiB
serialisiertes JSON mit Fortsetzung. Unicode-Paare bleiben zusammen. Schreibbelege
enthalten keine Beschreibungstexte. App, Server und Skill gemeinsam aktualisieren.
