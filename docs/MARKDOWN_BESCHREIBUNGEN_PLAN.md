# Markdown-Beschreibungen

Stand: 28. Oktober 2026 · 0.11.0+19. Implementierter Umfang: Projekte, Bereiche,
Ressourcensammlungen und Ordner erhalten denselben Markdown-Editor wie Notizen.

## Bedienung und Umsetzung

1. Beschreibungen in der Übersicht mit dem bestehenden Markdown-Renderer und
   dessen Lesetypografie anzeigen: Überschriften, Listen mit 4 Pixel Abstand,
   Tabellen, interne/externe Links und Textauswahl. Übersicht ist reine Vorschau:
   Checkboxen dort nicht ändern; dafür die Beschreibung öffnen.
2. Im vorhandenen Containerformular den Beschreibungsbereich auf Live (Standard),
   Quelltext und Lesen umstellen. Dieselben Format-/Tabellenaktionen, Undo/Redo
   und explizites Speichern nutzen. Name, Ergebnis und Termin bleiben eigene Felder.
   Eine kompakte Kopfzeile; kleine Fenster umbrechen die Aktionen.
3. Dokumentkopf/Dateitabs von Markdown-Fähigkeit trennen: Container werden keine
   Dateitabs. TXT, Aufgaben- und Ideenformulare behalten ihre Bedienung.
   Archiv/Papierkorb sind vollständig schreibgeschützt. Übersicht und Editor
   verwenden denselben Linkpfad mit Speicherschutz bei Inhaltswechseln.
4. Den bestehenden kanonischen Textcontroller, Repository-/MCP-Schutz und
   Speicherpfad weiterverwenden. Keine neuen Dateien oder Pflichtfelder,
   keine Normalisierung bestehender Texte. UUIDs, Revisionen, Hashkonflikte,
   Links und Sicherungen bleiben erhalten. Schema 6/Sitzung 2/Sicherung 3 unverändert.
   Gespeicherte Textversionen für Container nicht zusätzlich freischalten.
5. Regressionen für alle vier Containertypen, Quellerhalt, Speichern/Wechselschutz,
   aktuelle Sperren/MCP sowie native Übersicht/Bearbeitung prüfen. Native Prüfung
   ausschließlich mit temporärem synthetischem Root, macOS gesondert offen halten.
6. Bedienung, Produktstand, Architektur, UI-/Editor-/Anlageverträge und betroffene
   MCP-/Skill-Beschreibungen abgleichen; Analyse, Tests, Linux-Release und lokale
   Verweise prüfen. Installation mit App-Rückfallkopie; anschließend committen/pushen.

## Abnahme

0.11.0+19 · Linux · 28. Oktober 2026:

- `flutter analyze --no-pub`: ohne Befund.
- `flutter test --no-pub`: alle 184 Tests erfolgreich. Neue Widgetregressionen
  prüfen alle vier Containertypen, unveränderte CRLF-Texte beim Öffnen, drei Modi,
  explizites Speichern, getrennte Projektfelder, Checkboxen, Wechselschutz und
  MCP-Entwurfsperren. Vorschau prüft Links, schreibgeschützte Checkboxen und
  Aktualisierung nach einem neuen Textstand.
- `integration_test/markdown_descriptions_test.dart`: nativer Linux-Ablauf für
  Projekt, Bereich, Ressourcensammlung und Ordner erfolgreich. Gerenderte
  Übersicht, interne Links, Live/Quelltext/Lesen, Entwurfs-/Linkwechselschutz,
  Speichern, Tabellenzellen, unveränderte UUIDs/Projektfelder sowie Archiv- und
  Papierkorbsperren geprüft. Regulärer Ordnerklick bleibt Inhaltsnavigation;
  separater Beschreibungszugang und Umbenennaktion vorhanden.
- `integration_test/creation_test.dart`: alle zehn bisherigen nativen Linuxfälle
  erfolgreich, einschließlich Auswahl/Abwahl, Containerübersicht, Anlageziele,
  Entwurfschutz, Wiederöffnung und Ordner-Aufgaben.
- Breite und schmale native Darstellung mit synthetischen Daten visuell geprüft;
  [Vergleichsbilder](mockups/markdown-beschreibungen/README.md).
- `npm test --prefix mcp`: alle sieben Tests erfolgreich. Ein erster Lauf in der
  Dateisandbox endete durch eine interne Node-26-Assertion; der uneingeschränkte
  lokale Bridge-Test lief vollständig erfolgreich.
- Tests verwenden ausschließlich temporäre Arbeitsbereiche. Schema 6, Sitzung 2,
  Sicherung 3, MCP-Paket 0.3.0 und API 2 bleiben gleich. Native macOS-Abnahme offen.

Früherer Editorstand:
[Lesebild 0.10.1/0.10.2](EDITOR_LESBILD_PLAN.md).


## Linux-Release und Installation

- `flutter build linux --release --no-pub` erfolgreich; 0.11.0+19 ohne feste
  Testpfade am bestehenden Ort `$HOME/.local/opt/para-workspace` installiert.
  Alle 24 Paketdateien per SHA-256 mit dem Release-Build verglichen.
- Voriges App-Bundle unter
  `$HOME/.local/opt/para-workspace-backup-before-0.11.0-20261028T081526Z` erhalten.
  Installationsbeleg unter `$HOME/.local/opt/para-workspace-installation.json`,
  außerhalb des Repositories.
- Installierten Build mit temporären XDG-Verzeichnissen gestartet, Schema 6
  erfolgreich angelegt. Regulären Root nicht geöffnet oder migriert, Startverweis
  unverändert. Neue Bedienung beim nächsten normalen App-Start verfügbar.
- Lokale Dokumentverweise und `git diff --check` ohne Befund.
