# MCP-Anbindung – Architektur und Vertrag

Stand: 27. Oktober 2026 · App 0.10.0, MCP 0.3.0, API-Funktionsstand 2.
Kern seit 0.7, automatische Ablage seit 0.7.1 und erweiterte Werkzeuge seit 0.8.1.
Tatsächliche Bedienung und Grenzen: [MCP.md](MCP.md); Prüfstand: [MCP_UMSETZUNG.md](MCP_UMSETZUNG.md).

## Ziel

Ein im Repository gepflegter lokaler MCP-Server macht freigegebene Inhalte der
P.A.R.A.-App für KI-Assistenten zugänglich: suchen, lesen und anschließend gezielt
Notizen und Aufgaben bearbeiten. Die laufende App bleibt alleinige Eigentümerin
des geöffneten Arbeitsbereichs. Kein zweiter Zugriff auf SQLite oder Nutzdateien.

## Architektur

`MCP-Client → stdio-Server in mcp/ → authentifizierte lokale App-Bridge → Anwendungsdienst → WorkspaceRepository`

- Eigenständiges TypeScript-Paket unter `mcp/`, offizielles MCP-SDK, feste
  Abhängigkeiten/Lockdatei. Startbar als gebautes Node-Programm; keine Flutter-
  oder Datenbankabhängigkeit im MCP-Prozess. SDK 2.4.0, stabile v2-Linie; Paket und Lockdatei legen die Version fest.
- stdio ist der externe MCP-Transport. Nur Protokollnachrichten auf stdout,
  bereinigte Diagnosen auf stderr. Keine entfernte MCP-Adresse in Version 1.
- Kleine versionierte JSON-Bridge innerhalb der Flutter-App, über HTTP ausschließlich
  auf 127.0.0.1. Eigener interner Vertrag, kein zweiter MCP-Server. Zufälliger Port,
  keine Bindung an LAN-Adressen. Requests mit Origin grundsätzlich ablehnen,
  Host und Bearer-Zugang prüfen; keine CORS-Freigabe.
- Release-Build besitzt die macOS-Berechtigung `network.server`.
  Signierte Release-App und externe Ordnerfreigabe getrennt prüfen. Keine zusätzliche Dateifreigabe für den Node-Prozess erforderlich.
- App muss geöffnet und der gewünschte Root geladen sein. Bei geschlossener App:
  verständlicher Fehler, kein automatischer Start, Ersatzroot oder Hintergrund-DB.
- `lib/services/mcp_access_service.dart` enthält Freigaben, Validierung und
  fachliche Befehle; `lib/services/mcp_bridge.dart` nur Transport/Lebenszyklus.
  Domain- und Repository-Regeln weiterverwenden; keine Fachlogik in TypeScript duplizieren.

## Verbindung und Freigaben

In Einstellungen eigener Bereich „KI-Anbindung“: standardmäßig aus. Nutzer gibt
den aktuellen Root ausdrücklich frei und wählt „Lesen“ oder „Lesen und Schreiben“.
Version 1 gibt jeweils den ganzen aktiven Bestand dieses Roots frei; keine
irreführenden Teilbaumrechte. Archive gesondert freigeben, Papierkorb und
Textversionen zunächst nicht über MCP verfügbar machen. Diese Grenzen gelten
auch für Suchtreffer, Titel, Zähler, Verweise und Rückverweise; geerbten
Archivstatus berücksichtigen, ebenso Vorfahrenpfade und Fehlerantworten.
Bereits im freigegebenen Text enthaltene Linkbeschriftungen bleiben sichtbar;
Inhaltstexte werden nicht automatisch umgeschrieben oder redigiert.

Die App erstellt pro Verbindung ein kryptografisch zufälliges Geheimnis und eine
Verbindungskennung. Endpunkt/Geheimnis in einer lokalen Datei mit restriktiven
Rechten (0600), außerhalb von Repository, Arbeitsbereich und Sicherungszielen.
Die App verwaltet den privaten 0700-Ordner auf macOS/Linux automatisch;
kein Ordnerdialog. Plattformpfade und explizite ältere Pfadargumente beschreibt
[MCP.md](MCP.md). Der Bridge-Client akzeptiert nur
`http://127.0.0.1:<Port>` und folgt keinen Redirects. Eine
Beispielkonfiguration enthält nur deren Platzhalterpfad. Keine Geheimnisse in
Logs, Kommandozeilen oder exportierten Sicherungen. Die Datei atomar schreiben, Symlinks und unsichere Rechte ablehnen; lokale,
nicht synchronisierte Ablage verwenden und deren macOS-Ordnerfreigabe testen.
Token gelten nur für die aktuelle App-Öffnung. Nach Neustart Verbindung erneut
ausdrücklich freigeben und neue Datei schreiben; alte Token bleiben ungültig.
Gespeicherte Rechte sind nur eine Präferenz, keine automatische Aktivierung.
Die Datei ist ein lokaler
Verbindungsnachweis, keine fachliche Einstellung. Dauerhafte Freigabeentscheidung
gehört in den Root; die erstmalige Anlage dieser Einstellung braucht einen
versionierten Einstellungsvertrag und Kompatibilitätstests.

Root-Identität ist in Version 1 eine zufällige, nur im Speicher gültige Kennung
pro erfolgreich geöffnetem Repository, kombiniert mit einer Öffnungsgeneration;
keine neue persistente Workspace-ID. Kopien und Sicherungen übernehmen keine
gültigen Verbindungen. Die Bridge bindet jeden Aufruf an diese Kennungen.
Rootwechsel, Sperren, Abschalten oder Widerruf entwerten laufende Verbindungen;
kein stilles Umschalten auf einen anderen Root. Neue Verbindung ausdrücklich
freigeben. Vor Rootwechsel laufende Schreibbefehle abschließen, weitere sperren.
Die App zeigt verbundenen Zugang, Berechtigungen und letzte Aktion; sofortiger
Widerruf möglich; Token sofort entwerten und Verbindungsdatei nach Möglichkeit
löschen. Inhalte können durch den verwendeten KI-Client an dessen
Anbieter gelangen; dies vor Freigabe klar anzeigen.

## Werkzeuge

Projektanlage seit 0.7.2 gemäß [Vertrag](MCP_PROJEKTE_PLAN.md); die Erweiterung
um Ablage-/Metadaten-/Textoperationen seit 0.8.1 steht in
[MCP_ERWEITERUNG_PLAN.md](MCP_ERWEITERUNG_PLAN.md).

Inhaltsantworten enthalten strukturierte JSON-Daten mit UUID, Art, Titel, Ablage, Revision,
Status und `para://entry/<UUID>`; Suche liefert begrenzte Ausschnitte,
`read_text` gezielt angeforderten Text. Datum als
Kalenderdatum für Projekttermine; Zeitstempel mit Zeitzone. Keine internen Pfade.

| Stufe | Werkzeuge | Vertrag |
| --- | --- | --- |
| 1: Lesen | `workspace_info`, `list_entries`, `search`, `get_entry`, `read_text`, `list_tasks`, `list_contexts`, `get_links` | Pagination, begrenzte Textausschnitte, Filter und vorhandene Suchgrenzen; Archiv nur mit Freigabe und explizitem Filter |
| 2: Schreiben | `create_project`, `create_area`, `create_resource`, `create_folder`, `create_note`, `create_task`, `update_entry`, `edit_text`, `update_text`, `update_task`, `set_task_state` | Einzeloperationen mit expliziten Feldern; vorhandene Werte nicht durch fehlende Parameter leeren |
| später | Vorhandene Inhalte in Projekte umwandeln, Verschieben, Archivieren, Papierkorb, Wiederherstellen, Dateiimport | Separat entwerfen und freigeben; noch kein Umfang der ersten Version |

Kein SQL, beliebiger Dateipfad, Shellzugriff, Öffnen externer URLs, endgültiges
Löschen, Backup-Rückspielen oder Rootwechsel als Tool. Binäranhänge zunächst nur
Metadaten; keine OCR oder neue Inhaltsextraktion. MCP-Resources und Prompts sind
für den ersten nutzbaren Stand nicht nötig.

`list_tasks` verwendet dieselben Status-, Projekt-, Kontext-, Zeit- und
Energiefilter wie die UI. Kontextdefinitionen lesbar, zunächst nicht editierbar.
Projekte bleiben Vorhaben mit Ergebnis und Datum, nie „Irgendwann“. Archivierte
Inhalte bleiben schreibgeschützt. Suchindex, Verweise und Textversionen werden
bei Änderungen über die bestehenden App-Dienste aktualisiert.

## Schreibschutz und Fehler

- Lesen und Schreiben werden getrennt freigegeben. Die Schreibstufe benötigt
  bestandene Konflikt-, Wiederholungs- und Editorprüfungen.
- Text, Hash und Metadaten einschließlich Revision über einen gemeinsamen, gegen
  die Schreibwarteschlange konsistenten Repository-Snapshot lesen. Mutationen
  geben genau ihren gespeicherten Snapshot zurück. Keine getrennten Nachlesevorgänge,
  die einen neueren Hash mit älterem sichtbarem Text kombinieren. Pagination-Cursor
  an eine Bestandsrevision binden, stabil nach Sortierschlüssel plus UUID ordnen und bei Änderungen als veraltet ablehnen.
- Jede Änderung an bestehendem Inhalt braucht `expected_revision`; Text zusätzlich
  den beim Lesen erhaltenen Hash. Prüfung und Mutation müssen innerhalb derselben
  Repository-Schreibwarteschlange erfolgen. Die MCP-Aufgabenbefehle verwenden dafür den konsistenten Speicherpfad
  innerhalb `exclusive()`. Bestehende UI-Aufrufe bleiben erhalten. Eine
  Vorprüfung außerhalb der Warteschlange reicht nicht.
- Bei offenem ungespeichertem Editorentwurf Änderung dieses Inhalts ablehnen;
  keine automatische Speicherung oder Verwerfung. Dafür expliziten Editorstatus
  an den Anwendungsdienst melden. Auch Laden/Speichern mit einer inhaltsspezifischen
  Bearbeitungssperre koordinieren; den tatsächlichen Mutationserfolg statt eines
  später nachgelesenen Zustands übernehmen. Verspätete Leseantworten dürfen keine
  inzwischen begonnenen Eingaben ersetzen (Ladegeneration und Entwurfsprüfung).
  Saubere geöffnete Editoren aktualisieren.
- Schreibbefehle erhalten eine Request-ID. Wiederholung derselben ID und Nutzlast
  liefert innerhalb derselben App-Öffnung das ursprüngliche Ergebnis; abweichende
  Nutzlast ablehnen. ID vor Ausführung atomar reservieren; gleichzeitige Duplikate
  warten auf dasselbe Ergebnis. Cache an Verbindung, Öffnungsgeneration und ID
  binden, maximal 1.000 Einträge für 30 Minuten; bei voller Kapazität neue
  Schreibaufrufe vor Ausführung ablehnen. Nach Ablauf keine automatische
  Schreibwiederholung. Nach Prozessabbruch mit unbekanntem Ergebnis keine automatische
  Wiederholung. Dauerhafte Genau-einmal-Ausführung wird nicht behauptet.
- Freigabe unmittelbar vor Ausführung nochmals prüfen. Abbruch vor Ausführung
  verhindert Änderung; nach Commit liefert ein Abbruch keine Rollback-Garantie.
- Klare Fehler: App nicht erreichbar, Zugriff verweigert/widerrufen, Root gewechselt,
  Inhalt fehlt, Revision veraltet, ungespeicherter Entwurf, schreibgeschützt,
  ungültige Eingabe, Größenlimit und unbekanntes Ausführungsergebnis.
- Inhaltstexte sind Daten, keine Steueranweisungen. Tool-Annotationen beschreiben
  Lese-/Schreibwirkung, ersetzen aber nie serverseitige Zugriffsprüfung.
- Listen: Standard 20, höchstens 100 Objekte; standardmäßig kompakte Metadaten,
  vollständige Felder über `detail: full`/`get_entry`. Textabschnitte standardmäßig
  4.000, höchstens 262.144 UTF-16-Codeeinheiten. Listen und Texte maximal 64 KiB
  JSON, mit Cursor beziehungsweise `next_offset` fortsetzen. Unicode-Paare nicht
  zerlegen. Gesamttext einer Änderung höchstens 1 MiB UTF-8, etwa 2 MiB für
  Bridge-Request/-Gesamtantwort und höchstens acht parallele Anfragen. Keine stille
  Kürzung oder Rekonstruktion einer Textersetzung aus unvollständigen Ausschnitten.

## Ablage im Repository

- `mcp/`: Paket, Server, Bridge-Client, Schemas, Tests, README und
  `config/client.example.json` ohne Zugangsdaten.
- `lib/services/mcp_access_service.dart`, `mcp_bridge.dart`: App-Anbindung.
- Gemeinsame JSON-Vertragsfixtures unter `test/fixtures/mcp/`; Dart und TypeScript
  prüfen denselben Vertrag. Keine Nutzerdaten als Fixtures.
- `docs/MCP.md`: Einrichtung, Freigaben, Werkzeugvertrag, Grenzen und Fehlerhilfe.
  Dieser Architekturvertrag und die Fachpläne müssen mit der Implementierung und
  der Bedienungsanleitung synchron bleiben.
- README, Architektur, Sicherung und Umsetzungsplan im jeweiligen Umsetzungsschritt
  aktualisieren. Kein Commit von Builds, Credentials oder lokalen Arbeitsbereichen.

## Umsetzung und Abnahme

1. **Technischer Nachweis:** stdio → Bridge → echte Repository-Abfrage mit
   temporärem Root. Signierte macOS-Release-App, Sandbox, Tokenprüfung,
   Rootwechsel und externer Root funktionieren. Erst danach Architektur festziehen.
2. **Lesender Stand:** Verbindungseinstellungen und alle Lese-Tools, Filter,
   Pagination, Suchgrenzen und Fehlermeldungen; Installation aus frischem Checkout
   und kompletter Verbindungsaufbau mit einem echten lokalen MCP-Client prüfen.
3. **Schreibender Stand:** Konfliktschutz atomar ergänzen, Editorentwürfe schützen,
   Notizen/Aufgaben anlegen und bearbeiten, Status setzen, Wiederholungen prüfen.
4. **Freigabe:** `flutter analyze`, relevante Flutter-Tests, Paketprüfung und
   TypeScript-Tests; vollständiger MCP-End-to-End-Test über stdio. Manueller
   Release-Test: UI und Assistent gleichzeitig, Neustart, Widerruf und Rootwechsel.

Tests ausschließlich in temporären synthetischen Arbeitsbereichen. Negativtests:
falsches/fehlendes Token, Browser-Origin, unzulässiger Host, fehlende Rechte,
manipulierter Endpunkt/Redirect, Symlink-Datei, unzulässiger Credential-Ablageort,
Freigabe nach Sicherungsrückholung, Metadatenlecks über Links/Suche/Fehler,
Archiv/Papierkorb, große Payloads, ungültige IDs, Pfadversuche, alte Revisionen,
gleichzeitige UI-/MCP-Änderungen, insbesondere Speichern mit verzögerter Rückgabe
und Eingabe während eines verzögerten Editor-Ladens, veraltete Seitencursor, doppelte Requests, Verbindungsabbruch und App-Ende.

Kein neues Inhalts-/Sicherungsformat für MCP vorgesehen. Alte Schemas 1–5 weiterhin
über die App mit vollständiger Rückfallkopie übernehmen; unabhängige Sicherung
inklusive UUIDs, Links, Bytes, Status, Archiv, Papierkorb, Textversionen und
Root-Einstellungen öffnen und vergleichen. Falls die Umsetzung doch ein
Datenformat ändert, sind Versionskennung, verlustfreie Migration und unabhängige
Rückholung zwingender Bestandteil derselben Änderung.

## Quellen

- [Offizielle MCP-SDKs](https://modelcontextprotocol.io/docs/sdk): TypeScript-SDK als Basis.
- [MCP-Transporte](https://modelcontextprotocol.io/specification/2025-11-25/basic/transports): stdio und Trennung von Protokollausgabe und Diagnosen.
- [MCP-Tools](https://modelcontextprotocol.io/specification/2025-11-25/server/tools): Tool-Verträge, strukturierte Antworten und Nutzerkontrolle.

Diese Hintergrundquellen begründen die MCP-Seite; die interne App-Bridge und
Freigaberegeln sind implementierte Projektverträge. Verwendete SDK-Versionen sind
in `mcp/package.json` und Lockdatei festgelegt. Bei SDK-/Protokolländerungen die
Verträge und Kompatibilitätsprüfungen im selben Arbeitsgang aktualisieren.
