# KI-Anbindung über MCP

Stand: App 0.8.1, MCP-Paket 0.3.0, API-Funktionsstand 2. MCP läuft lokal mit der geöffneten App auf macOS und Linux.
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

## Codex-Skill

Der versionierbare Skill liegt unter [skills/para-workspace](../skills/para-workspace/SKILL.md).
Er beschreibt Suche, Lesen und gezielte Änderungen über MCP einschließlich
Projekt-/Aufgabenregeln, Revisionsschutz und Verbindungsfehlern. Er benötigt den
eingerichteten Server `para` und funktioniert auf macOS/Linux ohne Rechnerpfade
oder Zugangsschlüssel im Skill.

Im Repository-Root lokal installieren, sofern dort noch kein gleichnamiger Skill liegt:

```sh
mkdir -p "$HOME/.codex/skills"
ln -s "$PWD/skills/para-workspace" "$HOME/.codex/skills/para-workspace"
```

Der Verweis verwendet die Repositoryfassung direkt; den Checkout deshalb am
gleichen Ort behalten. Aufruf über `$para-workspace`, etwa „Suche meine Notiz
Urlaub“, oder automatische Auswahl bei passenden P.A.R.A.-Aufträgen. Falls der
Skill in einer laufenden Sitzung nicht erscheint, Codex neu starten.

Prüfung: Format und MCP-Abhängigkeitsmetadaten validiert; drei unabhängige
Subagenten haben die Anleitung in zwei Runden mit synthetischen Werkzeugantworten
für Lese-, Schreib- und Fehlerfälle durchgespielt. Gefundene Unklarheiten sind
korrigiert; in Runde zwei keine verbleibenden konkreten Befunde. Diese
Verhaltenssimulation ersetzt keinen Live-Test gegen einen Nutzerarbeitsbereich.
Die lokale Installation wurde zusätzlich über Codex `skills/list` außerhalb des
Repositories als aktivierter Benutzer-Skill samt MCP-Abhängigkeit erkannt.

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
| `workspace_info` | Version, Verbindung, Rechte, Werkzeugumfang und Antwortlimits |
| `list_entries` | Inhalte nach Ablage, Elternobjekt und Art auflisten |
| `search` | Namen/Textindex mit kurzen Ausschnitten; Kategorie, Art und direkte Eltern filtern |
| `get_entry` | Metadaten und Revision eines Inhalts lesen |
| `read_text` | Gespeicherten Text, Revision und Text-Hash lesen |
| `list_tasks` | Status, Projekt, Kontexte, Zeit und Energie filtern |
| `list_contexts` | Kontextdefinitionen einschließlich inaktiver lesen |
| `get_links` | Eingehende oder ausgehende interne Verweise lesen |

| Schreiben | Zweck |
| --- | --- |
| `create_note`, `create_task` | Im aktiven Bestand anlegen |
| `create_project` | Projekt mit Ergebnis und Termin unter Projekte anlegen |
| `create_area`, `create_resource` | Bereich beziehungsweise Ressourcensammlung auf oberster Ebene anlegen |
| `create_folder` | Ordner an einem ausdrücklich gewählten aktiven Ziel anlegen |
| `update_entry` | Titel/Dateiname ändern; bei Projekten zusätzlich Ergebnis und Termin |
| `edit_text` | Exakt anhängen oder eine eindeutige Textstelle ersetzen |
| `update_text` | Text mit Revision und Hash ersetzen |
| `update_task` | Explizite Aufgabenfelder ändern |
| `set_task_state` | Aufgabenstatus mit Revisionsprüfung setzen |

`create_project` benötigt `title`, ein konkretes Ergebnis als `goal`,
`due_date` als gültiges Kalenderdatum `YYYY-MM-DD` und `request_id`; `text` ist
optional. Projekte stehen immer auf oberster Ebene unter Projekte. `parent_id`,
`section` und Aufgabenstatus sind für dieses Werkzeug nicht erlaubt. Aufgaben im
neuen Projekt mit dessen zurückgegebener ID als `parent_id` anlegen. Fehlen Ergebnis
oder Termin, muss der Assistent nachfragen. Vorhandene Inhalte in Projekte
umwandeln bleibt eine App-Aktion.

`create_area` und `create_resource` benötigen `title` und `request_id`, optional
`text`. Ihre Kategorie ist fest; Eltern-ID, Aufgabenstatus und Projektangaben
sind nicht erlaubt. `create_folder` benötigt zusätzlich `parent_id` oder
`section`; gewöhnliche Inhalte dürfen nicht direkt unter Projekte liegen.

`update_entry` benötigt ID, Revision und Request-ID sowie mindestens eines von
`title`, `goal`, `due_date`. Ergebnis und Termin sind ausschließlich bei Projekten
erlaubt und dürfen nicht geleert werden. Beschreibungen bleiben erhalten;
Dateien lassen sich einschließlich Binäranhängen bytegleich umbenennen.

`edit_text` benötigt ID, Revision, vollständigen Text-Hash, Request-ID,
`operation` und `text`. `append` hängt exakt an, ohne automatischen Zeilenumbruch.
`replace` benötigt zusätzlich ein nichtleeres `old_text`, das im aktuellen Text
genau einmal vorkommen muss (auch überlappende Treffer zählen). Andernfalls
`text_mismatch` ohne Änderung. Gesamttext nach Änderung höchstens 1 MiB UTF-8.
Ein aktueller Textabschnitt liefert bereits den Hash des vollständigen Texts;
für gezielte Änderungen ist kein vollständiger Texttransfer nötig. Vollständige
Textersetzungen über `update_text` erfordern weiterhin vollständiges Lesen.

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
- Listen: standardmäßig 20, höchstens 100 Objekte; `detail: compact` ist Standard,
  `detail: full` liefert alle Metadaten. Kompakt enthält Identität, Titel, Typ,
  Ablage, Eltern-ID, Revision und Link, bei Projekten Ziel/Termin und bei Aufgaben
  Projekt/Status/Kontexte/Minuten/Energie. Suche ergänzt kurze Ausschnitte.
  Ergebnisnutzlast maximal 64 KiB JSON, bei Bedarf weniger Treffer mit `next_cursor`.
  Ein einzelner übergroßer Treffer ergibt `too_large`, keine stille Kürzung.
  Seitencursor werden auch bei Änderungen ausgeblendeter Metadaten ungültig;
  dann neu beginnen. Suche erhält die Trefferrelevanz. Elternfilter sind direkt.
- Textabschnitt: standardmäßig 4.000, höchstens 262.144 UTF-16-Codeeinheiten und
  maximal 64 KiB JSON einschließlich Escape-Zeichen; `next_offset` führt weiter.
  Unicode-Surrogatpaare bleiben zusammen (ein einzelnes Emoji kann eine
  Ein-Zeichen-Anforderung überschreiten). Positionen mitten im Paar sind ungültig.
  Antwort enthält ID, Revision, vollständigen Hash, Text und Abschnittsangaben.
  Textänderung höchstens 1 MiB UTF-8;
  größerer Text wird abgelehnt, nie still abgeschnitten. Gesamtanfrage/-antwort
  etwa 2 MiB; höchstens acht gleichzeitige Bridge-Anfragen. Das 64-KiB-Budget
  gilt vor der MCP-Darstellung als Text und `structuredContent`; ob der Client
  beide Fassungen in den Modellkontext lädt, bestimmt der Client.
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
  `opening_changed`, `not_found`, `text_mismatch` und `too_large` benennen behandelbare Fehler.
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
Version 1; Inhaltsformat bleibt Schema 6. API-Funktionsstand 2
ändert kompakte Antwortfelder und Standardgrößen: App, Server und Skill gemeinsam
aktualisieren; bestehende Clients müssen Cursor und Textfortsetzungen beachten.
Schreibantworten enthalten kompakte Metadaten und bei Änderungen den Text-Hash,
keine Beschreibungstexte. MCP kann übertragenen Gesprächskontext nicht entfernen.
Die lokale Verbindungsdatei liegt
außerhalb des Roots und ist kein Bestandteil von Sicherungen.

[Umsetzungsstand und Prüfungen](MCP_UMSETZUNG.md) · [Plan](MCP_PLAN.md)
