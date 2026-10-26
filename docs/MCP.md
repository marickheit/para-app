# KI-Anbindung über MCP

Stand: Version 0.7.1. MCP läuft lokal mit der geöffneten App auf macOS und Linux.
Der Server liegt im Repository unter `mcp/`. Er öffnet selbst keine Nutzdaten.

## Einrichten

Voraussetzung für den MCP-Server: Node.js ab Version 22 und npm.
Einmal im Repository ausführen:

```sh
npm ci --prefix mcp
npm run build --prefix mcp
```

1. App starten und den gewünschten Arbeitsbereich öffnen.
2. Einstellungen → **KI-Anbindung** öffnen.
3. Optional „Archiv mit freigeben“ wählen; es bleibt schreibgeschützt.
4. Bei **Zugriff** „Nur lesen“ oder „Lesen und Schreiben“ wählen. Das aktiviert
   die Verbindung sofort; die App verwaltet die Verbindungsdatei automatisch.
   „Aus“ und „Zugriff sofort widerrufen“ beenden den Zugang.
5. Den lokalen MCP-Client mit der [Beispielkonfiguration](../mcp/config/client.example.json)
   einrichten. Nur die absoluten Pfade zu Node und `mcp/dist/server.js` eintragen;
   ein Verbindungsdateipfad ist nicht mehr nötig.
6. MCP-Client verbinden. `workspace_info` zeigt Rechte und App-Version.

Die automatische Ablage liegt außerhalb des Arbeitsbereichs:

- Linux: `$XDG_STATE_HOME/para-mcp/para-mcp-connection.json`, sonst
  `~/.local/state/para-mcp/para-mcp-connection.json`. Ein relativer XDG-Wert wird ignoriert.
- macOS: `~/Library/Containers/dev.para.paraWorkspace/Data/Library/Application Support/para-mcp/para-mcp-connection.json`
  (App-Sandbox mit unveränderter Bundle-Kennung).

Der Server muss als derselbe Benutzer laufen. Bei einem eigenen `XDG_STATE_HOME`
auch diese Umgebungsvariable an den MCP-Server weiterreichen. Ein ausdrücklich
übergebenes zweites Serverargument verwendet weiterhin den bisherigen Dateipfad.
Vorhandene manuelle Freigaben werden nicht automatisch eingeschaltet oder kopiert;
bei Umstellung den Dateipfad aus der Client-Konfiguration entfernen und in der
neuen App erneut freigeben. Verbindungsformat 1 und Berechtigungspräferenz `mcp.v1`
bleiben kompatibel; keine Datenmigration.

Entwicklungsstarts mit `PARA_DATA_DIR` oder `PARA_CONFIG_DIR` verwenden keine
automatische Produktionsablage. Der native Integrationstest injiziert dafür
einen eigenen temporären Verbindungsordner.

Die Verbindungsdatei enthält einen geheimen Zugang. Die App erstellt den privaten
Ordner mit 0700 und schreibt die Datei atomar mit 0600. Nicht weitergeben oder
versionieren. Ein vorhandener Symlink oder eine unsicher zugängliche Datei wird
abgelehnt; die automatische Verbindung bleibt dann aus. Die Zugriffsrechte des lokalen
MCP-Ordners prüfen und nur eine eindeutig veraltete Verbindungsdatei entfernen.

Die Freigabe umfasst den gesamten aktiven Bestand des geöffneten Arbeitsbereichs,
nicht einzelne Ordner. Keine zusätzliche Bestätigung jeder Aktion in der App.
Der KI-Client kann gelesene Inhalte an seinen Anbieter übermitteln.

## Beenden, Wechseln und Widerrufen

Die App muss geöffnet bleiben. In den Einstellungen lässt sich der Zugang sofort
widerrufen. Beim Wechseln des Arbeitsbereichs endet er ebenfalls. Nach Neustart
oder erneuter Freigabe den MCP-Client neu verbinden: Ein laufender MCP-Prozess
bleibt an seine ursprüngliche App-Öffnung gebunden und übernimmt keine andere
Verbindungsdatei stillschweigend.

Die gewählte Berechtigungsstufe wird als Präferenz im Arbeitsbereich gespeichert;
sie aktiviert beim nächsten Start keinen Zugang. Kopien und zurückgeholte
Sicherungen öffnen keine Verbindung. Nach einem Absturz kann die inzwischen
ungültige Verbindungsdatei übrig bleiben; eine neue Freigabe ersetzt sie sicher.

## Verfügbare Werkzeuge

| Lesen | Zweck |
| --- | --- |
| `workspace_info` | Version, Verbindung und Rechte |
| `list_entries` | Inhalte nach Ablage, Elternobjekt und Art auflisten |
| `search` | Unscharfe Namen und vorhandenen Textindex mit kurzen Ausschnitten durchsuchen |
| `get_entry` | Metadaten und Revision eines Inhalts lesen |
| `read_text` | Gespeicherten Text, Revision und Text-Hash lesen |
| `list_tasks` | Status, Projekt, Kontexte, Zeit und Energie filtern |
| `list_contexts` | Kontextdefinitionen einschließlich inaktiver lesen |
| `get_links` | Eingehende oder ausgehende interne Verweise lesen |

| Schreiben | Zweck |
| --- | --- |
| `create_note`, `create_task` | Im aktiven Bestand anlegen |
| `update_text` | Text mit Revision und Hash ersetzen |
| `update_task` | Explizite Aufgabenfelder ändern |
| `set_task_state` | Aufgabenstatus mit Revisionsprüfung setzen |

Ausgelassene Aufgabenfelder bleiben erhalten. `null` leert Zeit beziehungsweise
Energie, `context_ids: []` leert Kontexte. Statuswerte: `inbox`, `next`, `waiting`,
`someday`, `done`, `cancelled`; Energie: `low`, `medium`, `high`.
`list_tasks` liefert `project_id` auch für Aufgaben in Projektunterordnern.
Ohne gesetztes Projekt stehen Aufgaben separat. Kontext-/Zeit-/Energiefilter
behandeln fehlende Angaben wie die App (`include_unspecified` standardmäßig an).

Bei vorhandenem Inhalt muss der Assistent die aktuelle `expected_revision`
angeben; bei Text zusätzlich `expected_body_hash` aus `read_text`.
Ungespeicherte, ladende oder speichernde Editoren blockieren Änderungen an diesem
Inhalt. Veraltete Angaben überschreiben nichts; erneut lesen und Änderung neu
bewerten. Notiz- und unterstützter Dateitext verwendet denselben Textverlauf wie
Speichern in der App. Aufgabenbeschreibungen haben weiterhin keinen eigenen
Textverlauf; der vorhandene App-Umfang bleibt maßgeblich.

## Grenzen und Fehler

- Papierkorb und Textversionen werden nicht angeboten. Archivzugriff verlangt
  sowohl App-Freigabe als auch `include_archive: true` im Aufruf. Diese Grenzen
  gelten auch für Treffer, Metadaten und Verweise. Bereits im lesbaren Text
  enthaltene Linkbeschriftungen bleiben sichtbar.
- Kein Dateiimport/-export, beliebiger Dateipfad, SQL, Shell, Rootwechsel,
  Verschieben, Archivieren, endgültiges Löschen oder Rückspielen von Sicherungen.
  Binäranhänge liefern nur Metadaten; Textsuche verwendet die Grenzen aus README.
- Listen: höchstens 100 Objekte pro Seite. Seitencursor bei Änderung des jeweiligen
  Ergebnisses ungültig; dann neu beginnen. Suche erhält die Trefferrelevanz.
- Textabschnitt: standardmäßig 65.536, höchstens 262.144 UTF-16-Codeeinheiten;
  `next_offset` führt zum nächsten Abschnitt. Textänderung höchstens 1 MiB UTF-8;
  größerer Text wird abgelehnt, nie still abgeschnitten. Gesamtanfrage/-antwort
  etwa 2 MiB; höchstens acht gleichzeitige Bridge-Anfragen.
- Jeder Schreibaufruf braucht eine eindeutige `request_id`. Identische Wiederholung
  liefert für 30 Minuten ab Annahme in derselben Verbindung das ursprüngliche
  Ergebnis; parallele Duplikate warten auf denselben Vorgang. Maximal 1.000
  Vorgänge, laufende verfallen nicht. Abweichende Nutzlast mit gleicher ID scheitert.
  Nach Ablauf, Neustart oder Verbindungsabbruch nicht automatisch wiederholen.
- Nach Übermittlung eines Schreibauftrags kann ein Abbruch/Timeout ein unbekanntes
  Ergebnis bedeuten. In der App nachsehen; ein Abbruch garantiert kein Rückgängigmachen.
  Widerruf verhindert noch wartende Änderungen und lässt bereits laufende
  Speichervorgänge geordnet abschließen.
- `read_only`, `editor_busy`, `conflict`, `stale_cursor`, `revoked`,
  `opening_changed`, `not_found` und `too_large` benennen behandelbare Fehler.
  `outcome_unknown`: Ergebnis in der App prüfen. Bei `connection_file` neu
  freigeben; bei `connection_rejected` Freigabe prüfen und MCP-Prozess neu starten.

## Prüfen und Architektur

```sh
npm ci --prefix mcp
npm test --prefix mcp
flutter analyze
flutter test
```

Die Flutter-Suite enthält einen echten Node-MCP-Client gegen eine echte
Repository-Instanz in einem temporären Root; vorher das MCP-Paket bauen.
Ein nativer Integrationstest steht unter `integration_test/mcp_native_test.dart`.
Er prüft die Zugriffsauswahl, sichere Ablage und Widerruf ausschließlich mit
eigenen temporären Daten, gibt `MCP_NATIVE_READY` mit
seinem Verbindungsdateipfad aus und wartet auf den externen Treiber:

```sh
node mcp/test/app-smoke.mjs /absoluter/testpfad/para-mcp-connection.json
```

Nach Erfolg im selben Testordner eine leere Datei
`para-mcp-connection.json.done` anlegen. Der native Test prüft gespeicherte Daten,
Widerruf und Dateibereinigung. Keine Geheimnisse ausgeben.

Die native Änderung dieser Version ist auf Linux geprüft. Ein erneuter nativer
macOS-Test mit Sandbox steht noch aus.

Intern: stdio → TypeScript-SDK → authentifizierte HTTP-Bridge ausschließlich auf
127.0.0.1 → App-Dienst → Repository. Bridge-Vertrag und `mcp.v1`-Präferenz sind
Version 1; Inhaltsformat bleibt Schema 5. Die lokale Verbindungsdatei liegt
außerhalb des Roots und ist kein Bestandteil von Sicherungen.

[Umsetzungsstand und Prüfungen](MCP_UMSETZUNG.md) · [Plan](MCP_PLAN.md)
