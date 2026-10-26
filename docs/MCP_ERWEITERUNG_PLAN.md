# MCP: Ablage bearbeiten und Kontext begrenzen

Stand: 26. Oktober 2026. Verbindlicher Umfang dieser Erweiterung; Prüfstand unten.

## Ergebnis und Gründe

Bereiche, Ressourcensammlungen und Ordner über dieselben Repository-Funktionen wie
in der App anlegen. Titel und Projektdaten gezielt ändern. Kleine Textänderungen
ohne vollständiges Hin- und Herschicken des Texts ermöglichen. Antworten bleiben
begrenzt und zeigen ihre Fortsetzung ausdrücklich an.

## Vertrag

- `create_area`, `create_resource`: Titel, optional `text`, `request_id`;
  ausschließlich oberste Ebene in Bereiche beziehungsweise Ressourcen.
- `create_folder`: Titel, optional `text`, `request_id`, explizite Ablage über
  `parent_id` oder `section`. Keine gewöhnlichen Inhalte direkt unter Projekte.
- `update_entry`: UUID, `expected_revision`, `request_id`, optional Titel;
  `goal` und `due_date` ausschließlich für Projekte. Mindestens ein Änderungsfeld.
  Projektziel und Termin dürfen nicht geleert werden. Text bleibt unverändert.
  Binärdateien dürfen umbenannt werden; ihre Bytes bleiben erhalten.
- `edit_text`: UUID, Revision, kompletter Text-Hash, Request-ID, `operation`
  (`append` oder `replace`), `text`; bei `replace` zusätzlich nichtleeres
  `old_text`. Ersetzen verlangt genau ein Vorkommen, keine regulären Ausdrücke.
  Anhängen fügt exakt den übergebenen Text an, ohne automatische Trennzeichen.
  Neuer Gesamttext maximal 1 MiB UTF-8, sonst Abbruch ohne Änderung.
- Alle bisherigen Werkzeuge bleiben erhalten. Revisions-, Hash-, Archiv-,
  Freigabe-, Wiederholungs- und Editorschutz gelten auch für neue Werkzeuge.
- `search`: zusätzlich `section`, `parent_id`, `kind`; Elternfilter meint direkte
  Kinder wie `list_entries`. Keine implizite vollständige Baumabfrage.
- Listen: Standard 20, maximal 100 Einträge; `detail: compact|full`, Standard
  `compact`. Kompakt: Identität, Titel, Art, Ablage, Eltern-ID, Revision, Link;
  Aufgaben zusätzlich Projekt, Status, Kontexte, Minuten und Energie;
  Projekte zusätzlich Ziel/Termin. Vollständige Metadaten über `full`/`get_entry`.
- Schreibantworten: kompakte Metadaten des gespeicherten Ergebnisses und bei
  Text-/Metadatenänderungen Text-Hash; keine Beschreibungen oder fremden Einträge.
- `read_text`: Standard 4.000 UTF-16-Codeeinheiten, bestehendes Maximum 262.144;
  auf kurze Identität, Revision, Hash, Text und Abschnittsinformationen reduzieren.
  Abschnitte dürfen Surrogatpaare nicht zerlegen. Explizite Position innerhalb
  eines Surrogatpaares ablehnen. Lesefortsetzung über `next_offset`.
- Listen maximal 64 KiB JSON; wenn nötig weniger Treffer mit `next_cursor`.
  Ein einzelner übergroßer Treffer ergibt `too_large`, keine stille Kürzung.
  Textabschnitte maximal 64 KiB JSON, mit kleinerem Abschnitt und `next_offset`.
  Metadaten-/Schreibantworten bleiben unter dem bestehenden Bridge-Maximum.
  Cursorfingerabdruck enthält weiterhin vollständige Ergebnis-Metadaten, damit
  Änderungen auch bei kompakter Darstellung erkannt werden.
- `workspace_info` nennt API-Funktionsstand und die neuen Standard-/Budgetwerte.
  Bridgeformat 1, Schema 6, Sicherungsformat, Bundle und Datenpfad unverändert.
  Ältere Clients vertragen zusätzliche Werkzeuge; die kleineren Standardseiten
  verlangen weiterhin die bereits dokumentierte Cursor-/Abschnittsverarbeitung.
  Antwortfelder ändern sich: App, Server und Skill gemeinsam aktualisieren.

## Umsetzung

1. Entwurf unabhängig auf Datenverlust, Konflikte, Antwortbudgets und
   Client-Kompatibilität prüfen; konkrete Befunde vor Umsetzung berücksichtigen.
2. Dart-App-Dienst und Validierung erweitern; gemeinsame Repository-Warteschlange
   und `saveSnapshot` erhalten. Keine neue Datenhaltung oder Migration.
3. TypeScript-Schemas, gemeinsame Tool-Fixture und echten stdio-Prüftreiber
   synchronisieren. Alle Schreibwerkzeuge einschließlich Projektanlage im
   Bridge-Client korrekt als Schreiben behandeln (unklarer Ausgang bei Timeout).
   Serverversion erhöhen, keine SDK-Aktualisierung erforderlich.
4. Skill und Agentenbeschreibung aktualisieren: kurz suchen, Details nachladen,
   Volltext nur bei Bedarf, gezielte Textänderung mit sicherem Hash verwenden.
   Keine Ersetzung aus unvollständig gelesenem Text rekonstruieren.
5. Isolierte Tests: feste Ablagen, Unterordner, Umbenennen/Projektdaten mit
   Text-/Linkerhalt; ungültige Felder, Nur-Lesen/Archiv/Papierkorb, Editor,
   Konflikte, doppelte Requests; append/replace einschließlich Mehrdeutigkeit,
   Größenlimit und Textversionen; Budget/Pagination/Unicode/Suchfilter/Cursor.
   Wiederöffnen und unabhängige Sicherungsrückholung der neuen Inhalte prüfen.
6. Analyse, vollständige Flutter-/Node-Tests, echter stdio-Client, Linux-Release
   und nativer isolierter MCP-Test. Unabhängiges Code-/Skill-Review; konkrete
   Befunde korrigieren und gezielt nachprüfen, bis keine Blocker verbleiben.
7. Dokumentation auf Ergebnis aktualisieren, Commit und Push. Lokale App und
   MCP mit Rückfallkopien aktualisieren, Skill-Verweis und Clientpfad prüfen.
   Eine laufende Nutzer-App nicht ungefragt beenden; neue Version wird beim
   nächsten Start wirksam. Neuer macOS-Nativnachweis ist auf Linux nicht möglich.

## Abgrenzung

Verschieben, Projektabschluss/Umwandlung, Archiv-/Papierkorbaktionen,
Kontextverwaltung, Dateiimport und Teilfreigaben bleiben spätere Vorschläge.
Keine zusätzlichen Werkzeuge pro Kategorie zum Lesen; vorhandene Filter reichen.
Kein generisches Shell-/SQL-Werkzeug. MCP kann bereits übertragenen Gesprächsinhalt
nicht entfernen. Strukturierte und Textantwort bleiben für Client-Kompatibilität;
ob ein Client beides in den Modellkontext lädt, muss dort geprüft werden.

## Prüfstand

Implementiert: fünf neue Werkzeuge, API-Funktionsstand 2, MCP 0.3.0 und App
0.8.1+12. Unabhängiges Entwurfsreview und Code-Nachreview ohne verbleibende Blocker;
Unicode-Surrogatbefund korrigiert und durch Regressionen abgesichert. Skill mit
vier synthetischen Nutzerabläufen unabhängig geprüft, Metadatenabruf präzisiert.

111 Flutter-Tests (elf neue Erweiterungstests) und sieben Node-Tests erfolgreich.
Echter stdio-Client prüft alle 19 Werkzeuge gegen temporäres Repository und native
Linux-Testapp. Wiederöffnen, unabhängige Sicherungsrückholung, Binärbytes,
Textversionen, Konflikte, Wiederholungen, JSON-Budgets und Unicode geprüft.
Analyse ohne Befund, Linux-Release gebaut und lokal mit vollständigen
Rückfallkopien von App/MCP installiert. Kopierte Builddateien per SHA-256 geprüft.
Installierter MCP-Server nochmals gegen native Testapp mit allen 19 Werkzeugen
geprüft; Skill-Verweis unverändert gültig. Laufende Nutzer-App nicht beendet.
macOS-Nativnachweis für diese Erweiterung bleibt auf Linux offen.
