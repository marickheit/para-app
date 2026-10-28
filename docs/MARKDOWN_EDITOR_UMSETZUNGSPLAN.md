# Markdown-Editor: Umsetzung und Prüfung

Status: gemeinsamer Editor für Notizen/MD und Containerbeschreibungen ab 0.11.0,
unter Linux einschließlich neuer Beschreibungsabläufe geprüft und installiert;
Lesebild 0.10.2+18 zuvor unter Linux geprüft und installiert;
aktuelle Nachweise im verlinkten Lesebildplan, frühere Installationsnachweise unten.
Stand: 28. Oktober 2026.
Aktueller [Lesebildplan nach Mock 1](EDITOR_LESBILD_PLAN.md).
Grundlage ist der abgestimmte [Entwurf](mockups/MARKDOWN_EDITOR.md) mit der
nachträglichen Präzisierung: keine grüne Blockmarkierung, Return schließt den
Absatz ab und rendert ihn, Shift+Return bleibt innerhalb des Absatzes.

## Bedienung

- Projekte, Bereiche, Ressourcensammlungen und Ordner nutzen ab 0.11.0 denselben
  Markdown-Editor mit Live/Quelltext/Lesen im bestehenden Formular. Name, Ergebnis
  und Datum bleiben separate Felder. Übersichten verwenden denselben Renderer
  mit schreibgeschützten Checkboxen. [Beschreibung und Nachweise](MARKDOWN_BESCHREIBUNGEN_PLAN.md).

- Fließtext, Live-Eingabe und Tabellenzellen: 16 Pixel bei 1,55-facher Zeilenhöhe.
  Quelltext: 15 Pixel Monospace bei gleicher Zeilenhöhe. Blockabstand 16 Pixel, innerhalb von Aufzählungen/nummerierten Listen 4 Pixel;
  H1 30 Pixel, H2 22 Pixel, weitere Überschriften abgestuft mit Zusatzabstand.
- Deckende neutrale Dokumentfläche; zentrierte Lesespalte mit 680 Pixel Text und
  bis zu 32 Pixel seitlichem Innenabstand, oben bei Dokumenten 48 Pixel,
  bei Beschreibungsformularen 24 Pixel vor dem Titel-/Feldbereich. Schmale Fenster passen
  die Ränder an. Neue Sitzungen starten in Lesebreite; gespeicherte Breitenwahl
  bleibt erhalten. „Volle Breite“ und „Lesebreite“ gelten gemeinsam für Textansichten.
- Gültige YAML-Map-Kopfdaten am Anfang kompakt anzeigen, unmittelbar folgenden
  H1-Titel davor darstellen. `type`/`tags` liefern eine Kurzzeile; alle Originalfelder
  sind aufklappbar, in Live als vollständiger Block bearbeitbar. Quelltext, Kommentare,
  unbekannte Felder und Originaloffsets erhalten; ungültige Köpfe bleiben Markdown.
- Drei Modi: Live (Standard), Quelltext, Lesen. Moduswechsel erhält denselben
  ungespeicherten Text; explizites Speichern und Wechselschutz bleiben.
- Live zeigt inaktive Markdown-Blöcke gerendert, den aktiven Textblock als
  bearbeitbare Syntax ohne farbige Fläche oder Rand. Return teilt einen normalen
  Absatz am Cursor mit Markdown-Absatzgrenze; der alte Teil wird gerendert und
  der neue Teil erhält den Cursor. Shift+Return fügt einen Markdown-Hardbreak im Absatz ein.
  Mehrzeilige Codeblöcke bleiben beim Zeilenumbruch zusammen. Listen führen
  ihren Marker weiter; ein leeres Listenelement beendet die Liste.
- Quelltext bearbeitet das gesamte Original. Lesen erlaubt Textauswahl, Links
  und tatsächlich gerenderte Markdown-Checkboxen; Archiv/Papierkorb bleiben vollständig gesperrt.
- Eine kompakte gemeinsame Datei-Kopfzeile mit Dateiname, Moduswahl, Aa-Menü,
  Tabellenbutton und Speichern. Keine dauerhafte zusätzliche Formatleiste oder
  Status-Fußzeile. Zusatzaktionen (Lesebreite, Verlauf, Infos, Dateiaktionen)
  bleiben erreichbar. Titel bearbeitbarer Notizen bleibt zugänglich. Aktionen
  werden direkt in den vorhandenen Dateitabstreifen integriert; kein zweiter
  Dokumentkopf darunter. Schmale Fenster dürfen die gemeinsame Zeile umbrechen.
- Aa: Überschrift, Fett, Kursiv, Listen/Checklisten, Code, externer Link, vorhandene
  interne Verknüpfung, Syntaxhilfe sowie Undo/Redo mit Tastenkürzeln.
- Tabellen in Live und Lesen linksbündig in Inhaltsbreite; Spalten 72–320 Pixel
  einschließlich Zellabstand. Lange Texte umbrechen, breite Tabellen horizontal
  mit Scrollbalken bewegen. Keine gespeicherten manuellen Spaltenbreiten.
- Tabellenanlage über 8×6-Raster: Maus/Fokus markiert Größe, Klick fügt ein.
  Erste Zeile ist Kopfzeile. Zelltext direkt bearbeiten; lokale Buttons fügen
  darunter/rechts ein oder löschen ausgewählte Datenzeile/Spalte. Kopfzeile und
  mindestens eine Spalte bleiben; Löschen ist rückgängig machbar.

## Architektur und Datenerhalt

- Der bestehende `_body`-Controller bleibt die maßgebliche vollständige Quelle.
  Live- und Zellfelder schreiben synchron bei jeder Eingabe dorthin. Speichern,
  MCP-Schutz, Hash-/Revisionskonflikte, Versionen und ungespeicherte Wechsel nutzen
  unverändert denselben Repositorypfad.
- Neue kleine Markdown-Module: verlustfreie Quellbereiche für Blöcke, gezielte
  Checkboxänderungen und konservative Tabellenbearbeitung; separates Editorwidget
  mit lokalem Modus, Fokus und textbezogener Undo/Redo-Historie.
- Bloßes Öffnen im Live-Modus hält einen Vorschautab nicht fest. Erst echte
  Bearbeitung/Fokus oder Änderung meldet Editing. Modus-/Scrollzustand nur flüchtig
  wie bisher; Sessionformat 2, Schema 6, Links und Sicherungsformat 3 bleiben gleich.
- Unberührte Texte einschließlich Leerzeilen, CRLF, Links, Code, Einrückung und
  unbekannter Syntax unverändert lassen. Tabellenänderungen ersetzen nur die
  betroffene Tabelle und erhalten Ausrichtungen sowie escapte Pipes/Code-Pipes.
  Nicht sicher unterstützte Tabellen bleiben über Quelltext bearbeitbar.
  Mehrzeilig eingefügter Zelltext wird zu einer Textzeile mit Leerzeichen;
  Tabellenzellen rendern ausschließlich Inline-Markdown.
- Dokumentweite Referenzdefinitionen beim Blockrendern berücksichtigen. Gerenderte
  Benachbarte gerenderte Blöcke gemeinsam auswählbar machen; aktive Eingabefelder
  bleiben für native Tastaturaktionen in einem eigenen Auswahlbereich. Cmd/Ctrl+A im Live-Textfeld öffnet denselben
  Text im Quelltextmodus mit Gesamtauswahl für dokumentübergreifende Bearbeitung;
  kein verlustbehaftetes Zusammenführen einzelner Textfelder.
- Alle Mutationen prüfen den aktuellen Sperrzustand auch in bereits geöffneten
  Menüs. Undo/Redo erhält Text und Quellauswahl über Moduswechsel und Speichern;
  ein echter Dokumentreload setzt die Historie zurück. IME-Komposition nicht teilen.
- Markdown-Rendering verwendet weiterhin vorhandene Pakete; keine externen Bilder
  laden. Tabellenzellen unterstützen Standard-Markdown-Text, keine Formeln oder
  Excel-Dateien. TXT/Binärvorschauen und Metadatenformulare bleiben erhalten.

## Frühere Durchführung und Abnahme 0.10.0

1. Plan unabhängig durch Subagenten auf Architektur, Bedienung und Datenerhalt
   prüfen; Befunde vor Umsetzung einarbeiten.
2. Quellmodell und Tabellenoperationen mit repräsentativen Syntaxfällen prüfen;
   Live-Widget und kompakte Integration implementieren.
3. Widgetprüfungen für Return/Shift+Return, Auswahl, Moduswechsel, Checkboxen,
   Tabellenraster/-aktionen, Undo/Redo, Archiv/Papierkorb und MCP-/Wechselschutz.
   Bestehende Editor-/Dateitabtests an die neue Bedienung anpassen.
4. Implementierung unabhängig durch Subagenten reviewen, Befunde beheben und
   betroffene Prüfungen erneut ausführen. Flutter-Analyse, Tests und Linux-Release.
5. Native Linux-Abnahme ausschließlich mit temporärem Datenroot. Dokumentation
   repositoryweit synchronisieren; macOS-Prüfung als offen kennzeichnen.
6. Version 0.10.0 lokal am vorhandenen Linux-Installationsort installieren.
   Bundlekennung, Startverweis und regulären Datenroot beibehalten. Installation
   erst nach bestandenen Prüfungen; laufende Nutzerinstanz nicht gewaltsam beenden.

Planreview: zwei unabhängige Subagenten haben Architektur und Datenerhalt geprüft.
Ihre Bedingungen (Tabstreifen statt zweitem Kopf, Quelloffsets, Referenzkontext,
Auswahlvertrag, synchrone Entwürfe und Sperr-/Undo-Prüfungen) sind eingearbeitet.
Auch Implementierung und Nachkorrekturen wurden unabhängig durch zwei
Subagenten geprüft; abschließend keine verbleibenden Blocker.

## Grenzen

- Komplexe lose oder verschachtelte Tasklisten erhalten nur dort einen schaltbaren
  Haken, wo der vorhandene Markdown-Renderer tatsächlich eine Checkbox erzeugt.
  Code-/HTML-Beispiele sind niemals schaltbare Aufgaben. Quelltext bleibt verfügbar.
- Live arbeitet mit Markdown-Blöcken; dokumentübergreifendes Bearbeiten erfolgt im
  Quelltext. Cmd/Ctrl+A im aktiven Textblock wechselt dorthin mit Gesamtauswahl.
- Tabellen sind Markdown-Tabellen mit einzeiligen Zellen, keine Tabellenkalkulation.
  Unsichere Pipe-/Codespankonstrukte werden vollständig erhalten und als Quelltext
  bearbeitet. Keine Formeln, verbundenen Zellen oder Excel-Dateibearbeitung.
- Undo/Redo ist flüchtig (bis 100 Einträge mit ungefähr 8 MiB Textbudget; mindestens
  ein vorheriger Stand auch bei größerem Text). Gespeicherte Textversionen bleiben
  der dauerhafte Verlauf. Kein Autosave oder ungespeicherter Neustart-Entwurf.

## Prüfnachweise 0.10.0+16 · Linux · 27. Oktober 2026

- `flutter analyze --no-pub`: ohne Befund.
- `flutter test --no-pub`: alle 168 Tests erfolgreich, darunter 14 Quellmodell-
  und 21 Editor-Widgettests. Bestehende Schemaübernahme und unabhängige
  Sicherungsrückholung weiterhin erfolgreich; keine Formatänderung.
- Neue native `integration_test/markdown_editor_test.dart`: Live-Absatzabschluss,
  Lesen/Checkboxen, explizites Speichern, Rasteranlage, direkte Zell-/Struktur-
  änderungen, gemeinsamer Tabkopf, Entwurfs-/MCP-Schutz und schmale Ansicht erfolgreich.
- Bisherige native Linux-Prüfungen: fünf Dateitabfälle, zehn Anlagefälle und
  zwölf Workspacefälle erfolgreich; ein macOS-spezifischer Fall auf Linux
  übersprungen. Die Kopfzeilenprüfung nach Höhenkorrektur gezielt erneut
  erfolgreich. Suiten einzeln gestartet, da Flutter im kombinierten Lauf nach
  dem ersten Testprogramm keine weitere Debug-Verbindung aufbaute.
- Reviews mit Regressionen für verschachtelte/lose Checkboxen, Quelloffsets,
  schnelle Zelländerungen vor einem Frame, Zell-Paste, Tabellen-Undo/Navigation,
  Absatz-Auswahl, Inline-/Referenzlinks, IME und aktuelle Sperren abgeschlossen.
  Tastaturtest für visuell umgebrochene Absätze ergänzt; Eingabefelder liegen
  außerhalb der gerenderten Auswahlbereiche.
- Native macOS-Abnahme des neuen Editors ist offen.

## Frühere Nachprüfung der kompakten Abstände · Linux · 27. Oktober 2026

- Damaliger Stand: 1,2-fache Zeilenhöhe und 6 Pixel Blockabstand;
  seit 0.10.1 durch das oben beschriebene Lesebild ersetzt.
- Analyse ohne Befund; alle 168 Flutter-Tests und sieben MCP-Tests erfolgreich.
- Nativer Markdown-Editortest mit temporärem Root erneut erfolgreich;
  Live-/Tabellen-/Raster-/Schmalansicht anhand der Testbilder geprüft.
- Linux-Release neu gebaut und installiert; alle 25 Paketdateien per SHA-256
  mit dem Build verglichen. Installierter Build startet mit isolierten XDG-
  Verzeichnissen und erzeugt dort Schema 6.

## Nachprüfung Inhaltsbreite · Linux · 27. Oktober 2026

- Analyse ohne Befund; alle 170 Flutter-Tests erfolgreich, darunter zwei neue
  Layouttests für Live und Lesen: kompakte Tabellen, begrenzte Spalten,
  Textumbruch, horizontales Scrollen und direkte Zellbearbeitung.
- Nativer Linux-Editortest einschließlich kompakter Tabellenbreite erfolgreich;
  die native Darstellung anhand des Testbilds geprüft.
- Release neu gebaut und installiert, 25 Paketdateien per SHA-256 verglichen.
  Installierten Build mit isolierten XDG-Verzeichnissen und Schema 6 gestartet.

## Frühere lokale Installation 0.10.0+16

- Linux-Release 0.10.0+16 ohne `PARA_DATA_DIR`-/`PARA_CONFIG_DIR`-Buildoverride
  unter `$HOME/.local/opt/para-workspace` installiert. Vorhandener Starter und
  App-Kennung unverändert; die neue Darstellung gilt beim nächsten App-Start.
- Vorheriges App-Bundle vollständig unter
  `$HOME/.local/opt/para-workspace-backup-before-content-tables-20261027T084811Z`
  erhalten. Installationsbeleg mit Paketprüfsummen liegt außerhalb des
  Repositories in `$HOME/.local/opt/para-workspace-installation.json`.
- Installierten Build ausschließlich mit temporären XDG-Verzeichnissen gestartet.
  Regulären Nutzerbestand weder geöffnet noch migriert; Startverweis unverändert.
  Keine Datenformatänderung und keine neue Datenmigration erforderlich.
