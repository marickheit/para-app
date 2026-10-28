# Markdown-Lesebild nach Mock 1

Stand: 28. Oktober 2026 · 0.10.2+18. Erste Bildvariante implementiert.
[Ausgewähltes Mock und native Vergleichsbilder](mockups/editor-lesebild/README.md).

## Ziel und Umfang

- Bestehende Symbolleiste, Explorer und gemeinsame Tab-/Aktionszeile erhalten.
- Markdown standardmäßig zentrieren: 680 Pixel Textbreite, seitlich bis 32 Pixel
  Innenabstand, oben 48 Pixel. Schmale Fenster passen die Ränder an.
  „Volle Breite“ bleibt erreichbar; gespeicherte Breitenentscheidungen erhalten.
- Fließtext/Live-Eingabe 16 Pixel bei 1,55-facher Zeilenhöhe; H1 30 Pixel,
  H2 22 Pixel, klar abgestufte weitere Überschriften und großzügigere Absätze.
  Tabellen bleiben natürliche Inhaltsbreite mit begrenzten Spalten und Scrollen.
- Markdown erhält eine deckende neutrale Dokumentfläche, auch im dunklen Thema.
  TXT, Formulare und Binärvorschauen behalten ihre eigene Darstellung.
- Gültige YAML-Kopfdaten kompakt darstellen, sämtliche Originalfelder aufklappbar
  halten. Ein direkt folgender Dokumenttitel steht vor der Metadatenzeile.
  Live kann den vollständigen Kopfblock bearbeiten; Quelltext bleibt unverändert.
  Ungültige/mehrdeutige Kopfdaten weiterhin als normales Markdown anzeigen.
- Kein Rezeptsonderlayout, keine neuen Pflichtfelder, keine Änderung von UUIDs,
  Textspeicherung, Sitzungsversion, Schema oder Sicherungsformat.

## Durchführung

1. Einheitliche Dokumenttypografie und responsive Breite/Fläche implementieren.
2. Verlustfreie Frontmatter-Erkennung und Darstellung in Live/Lesen ergänzen;
   Originaloffsets, Sperren, Checkboxen und Undo erhalten.
3. Regressionen für Quellerhalt, Kopfdaten, schmale Ansichten und Editorbedienung
   prüfen. Analyse, Flutter-Suite und nativen Linux-Editortest ausführen.
4. Native Darstellung mit synthetischem Rezept in isoliertem temporärem Root
   prüfen; Release bauen. Produkt-, Bedien-, Architektur- und UI-Verträge abgleichen.

## Abnahme

Linux · 28. Oktober 2026 · 0.10.1+17:

- `flutter analyze --no-pub`: ohne Befund.
- `flutter test --no-pub`: alle 177 Tests erfolgreich, einschließlich YAML-/CRLF-/
  BOM-/Kommentarerhalt, ungültiger Köpfe, Checkboxoffsets, Sperren, Undo und
  Tastaturnavigation in Darstellungsreihenfolge. Bestehende Datenübernahme und
  unabhängige Sicherungsrückholung bleiben Bestandteil der erfolgreichen Suite.
- `integration_test/editor_readability_test.dart`: nativer Linux-Test erfolgreich;
  680-Pixel-Textspalte, deckende Fläche, beide Themen, drei Modi, vollständige
  Eigenschaften, schmale Ansicht und explizit gespeicherte volle Breite geprüft.
- `integration_test/markdown_editor_test.dart`: bestehender nativer Editorablauf
  mit Absatzabschluss, Checkboxen, Tabellen, Speichern, MCP-/Entwurfschutz und
  schmalem Tabkopf erfolgreich.
- `integration_test/file_tabs_test.dart`: alle fünf nativen Linuxfälle erfolgreich,
  einschließlich älterer Sitzung mit Rückfallkopie, Vorschauen, Entwurfschutz,
  Breitenumschaltung und UUID-Erhalt bei Archiv/Papierkorb.
- Native Bilder in Dunkel/Hell und schmal visuell geprüft und bei der Referenz
  abgelegt. Normale Markdown-Tabellen behalten ihre Inhalte einschließlich leerer
  Kopfzeilen; Mockdaten werden nicht als Dokumentumformung übernommen.
- Lokale Dokumentverweise und `git diff --check` geprüft.

Alle Tests verwenden getrennte temporäre Arbeitsbereiche. Keine Datenmigration;
Schema 6, Sitzung 2 und Sicherungsformat 3 unverändert. Frühere Abnahmen im
[Editorvertrag](MARKDOWN_EDITOR_UMSETZUNGSPLAN.md) behalten ihre Versionsbindung.
Native macOS-Abnahme bleibt offen.


## Linux-Release und Installation 0.10.1+17

- `flutter build linux --release --no-pub` erfolgreich, ohne Daten-/Konfigurations-
  Buildoverride. Version 0.10.1+17 am bestehenden Pfad
  `$HOME/.local/opt/para-workspace` installiert; alle 24 Paketdateien per SHA-256
  gegen den Release-Build geprüft.
- Vorheriges App-Bundle vollständig unter
  `$HOME/.local/opt/para-workspace-backup-before-0.10.1-20261028T074205Z`
  erhalten; Installationsbeleg außerhalb des Repositories unter
  `$HOME/.local/opt/para-workspace-installation.json`.
- Installierten Build mit isolierten temporären XDG-Verzeichnissen gestartet:
  Schema 6 erfolgreich angelegt. Regulären Arbeitsbereich nicht geöffnet,
  Startverweis unverändert. Keine Datenmigration und kein Eingriff in laufende
  Nutzerinstanzen. Neue Darstellung beim nächsten normalen App-Start verfügbar.
- Bei bereits gespeicherter voller Breite im Dateiaktionsmenü „Lesebreite“ wählen,
  um die zentrierte Darstellung zu verwenden.


## Listenabstand 0.10.2+18 · Linux · 28. Oktober 2026

- Aufzählungen und nummerierte Listen verwenden 4 statt 16 Pixel Abstand zwischen
  Einträgen; Zeilenhöhe 1,55 und Abschnittsabstände bleiben bestehen. In Live und
  Lesen identisch, einschließlich verschachtelter Listen. Quelltext unverändert.
- Die Leseansicht rendert Listen separat mit Originaloffsets und dokumentweiten
  Referenzen; übrige Textabschnitte behalten ihren bisherigen Renderer.
- Analyse ohne Befund, alle 179 Flutter-Tests erfolgreich. Neue Layoutregressionen
  prüfen kompakte Aufzählungen, nummerierte/verschachtelte Listen, Abschnittsabstand
  und Checkboxänderungen nach mehreren getrennten Listen einschließlich Undo.
- Native Linux-Nachprüfung: Lesebildtest mit gemessenem 28–30-Pixel-Zeilenraster
  der Zutatenliste sowie bestehender Editorablauf erfolgreich. Dunkel/Hell,
  schmale Ansicht, Speichern, Checkboxen, Tabellen und Entwurfschutz geprüft.
  Mehrzeilige nummerierte Schritte und Zutatenliste im
  [nativen Listenbild](mockups/editor-lesebild/native-lists.png) visuell geprüft.
- Dokumentation, lokale Verweise und `git diff --check` abgeglichen.
- Linux-Release 0.10.2+18 gebaut und am bestehenden App-Pfad installiert, alle
  24 Paketdateien per SHA-256 verglichen. Installierten Build mit temporären
  XDG-Verzeichnissen und Schema 6 gestartet; regulären Bestand nicht geöffnet,
  Startverweis unverändert. Voriges App-Bundle unter
  `$HOME/.local/opt/para-workspace-backup-before-0.10.2-20261028T075539Z` erhalten.
  Änderung beim nächsten normalen App-Start verfügbar; keine Datenmigration.
