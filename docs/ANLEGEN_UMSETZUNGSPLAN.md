# Auswahl, Übersicht und Anlegen

Stand: 26. Oktober 2026. Auswahl/Anlage ab 0.7.3; getrennte Baumbedienung in 0.9.2.

## Verbindliche Bedienung

- Kategorie öffnen zeigt zunächst deren Übersicht ohne automatische Auswahl.
- Klick auf Name/Zeile von Projekt/Bereich/Ressourcensammlung wählt sichtbar aus
  und zeigt die Übersicht mit Beschreibung, Inhalten und Projektaktionen.
  Erneuter Klick wählt ab. Ordner verhalten sich entsprechend; beim Abwählen
  eines Unterordners wird sein Elterncontainer ausgewählt. Der Baumzustand bleibt
  dabei erhalten. Nur der separate Pfeil klappt auf/zu, ohne Auswahlwechsel oder
  Editor-Wechseldialog; auch im Archiv und Papierkorb.
- Geöffnete Dateien markieren ihren Elterncontainer als Anlageziel.
- Ohne Auswahl bieten Projekte/Bereiche/Ressourcen nur die jeweilige Hauptanlage.
  Mit Auswahl bieten Plus und Strg/Cmd+N eine Typauswahl am sichtbaren Ziel sowie
  eine getrennte Aktion für ein weiteres Projekt/einen Bereich/eine Sammlung.
- Kontextaktionen gelten genau für den angeklickten Container. Jeder Anlegedialog
  nennt den vollständigen Zielpfad; normale Inhalte können das Ziel ändern.
- Inbox bietet Notiz, Aufgabe, Idee, Ordner, Textdatei und Import. Archiv und
  Papierkorb erlauben keine lokale Anlage, auch nicht per Tastatur. Abgeschlossene
  Aufgabenlisten haben keine direkte Neuanlage. Globale Erfassung in die Inbox
  bleibt über die Inbox-Navigation erreichbar.
- Aufgabenstatus wird im Dialog getrennt von der Ablage angezeigt. Warten auf und
  Irgendwann belegen passend vor; andere offene Listen starten in Noch zu klären.
  Erfolgreich angelegte Aufgaben werden angezeigt, störende Filter zurückgesetzt.
- Übersicht ist eigener Kopfzeilenreiter; Beschreibung kann darüber bearbeitet
  werden. Seit 0.11.0 rendern Übersichten Markdown schreibgeschützt; Container-
  beschreibungen verwenden Live/Quelltext/Lesen im vorhandenen Formular.
  Ordner öffnen ihre Beschreibung auch über den Button in der Inhaltsansicht;
  Umbenennen bleibt separat. Ungespeicherte Texte blockieren auch Auswahlwechsel
  und Abwählen. [Beschreibung und Nachweise](MARKDOWN_BESCHREIBUNGEN_PLAN.md).

## Umsetzung

1. Anlageziel aus sichtbarer Auswahl/Elterncontainer ableiten, verstecktes separates
   Ordnerziel entfernen. Öffnen, Abwählen und Kategorieübersicht vereinheitlichen.
2. Kopfzeilenreiter Übersicht, Beschreibung und sichtbare Containermarkierung.
3. Plus/Tastatur/Leerzustände über dieselben Menüregeln bedienen. Zielpfade und
   Zielauswahl in Inhalt-/TXT-Dialogen sowie Import ergänzen.
4. Temporäre Widgettests prüfen zwei Hauptanlagen, Auswahl/Abwahl, Unterordner,
   Elternziel geöffneter Notiz, Kontextziel, expliziten Zielwechsel zur Wurzel,
   Tastatur, Aufgaben/Filter, Archiv/Papierkorb und Entwurfschutz. Bestehende native
   Tests an die ausdrücklich geänderte Navigation anpassen und ausführen.
5. Analyse, vollständige Flutter-Suite, Linux-Release und nativen Bedientest
   ausführen. Bedienung/Architektur/Prüfnachweise aktualisieren, committen, pushen
   und lokale App mit Rückfallkopie ersetzen. Laufende Entwürfe nicht beenden.

## Grenzen

Reine Bedienänderung; bestehende Daten und Sitzungen bleiben lesbar. Aktuell
Schema 6 und session.v2, keine Änderung am Speicherformat.
Keine Nutzdatenmigration, kein neuer Datenordner. Vorhandene freie Inhalte auf
Bereiche-/Ressourcen-Wurzelebene bleiben lesbar und als explizite Ziele nutzbar.
Vorhandene MCP-Operationen und Daten bleiben unverändert.

## Prüfnachweise

### Abnahme 0.9.2

- Getrennte Baumbedienung 0.9.2: Analyse ohne Befund, 133 Flutter-Tests erfolgreich.
  Alle zehn nativen Auswahl-/Anlageabläufe erfolgreich, erweitert um getrennte
  Name-/Pfeilklicks für Projekt/Bereich/Ressource/Ordner, Archiv und Papierkorb,
  Entwurferhalt beim Einklappen und unabhängigen gespeicherten Baumzustand.
  Alle zwölf bisherigen Linux-Bedienabläufe nach Umstellung ihrer Klicks geprüft;
  ein macOS-spezifischer Test auf Linux übersprungen. Release 0.9.2+15 lokal
  mit vollständiger Daten-/App-Rückfallkopie installiert, alle 24 Paketdateien
  gegen den Build geprüft und installierte App mit temporären XDG-Verzeichnissen
  gestartet. Kein regulärer Nutzerbestand als Testumgebung.

### Ursprüngliche Abnahme 0.7.3

- Analyse ohne Befund; alle 82 Flutter-Tests erfolgreich.
- Zehn neue native Linux-Abläufe erfolgreich: Kategorie ohne Auswahl,
  Containerübersicht und Abwahl, zweite Bereichs-/Ressourcen-/Projektanlage,
  Unterordner/Dateieltern, Kontextziel und explizite Wurzel, TXT/Importziel,
  Aufgabenstatus mit wirksamem Filter, Entwurfschutz, Archiv/Papierkorb,
  Sitzungswiederaufnahme und Aufgaben in eigenständigen Inbox-Ordnern.
- Alle zwölf auf Linux anwendbaren bisherigen nativen Bedienabläufe erfolgreich.
  Der macOS-spezifische Bookmark-Test wird auf Linux übersprungen; eine erneute
  native macOS-Prüfung dieser Version bleibt offen.
- Projektübersicht als natives Vergleichsbild visuell geprüft; synthetische Daten.
- Testdateien: `integration_test/creation_test.dart` und vorhandene native
  Abläufe unter `integration_test/workspace_test.dart`. Die neue Testdatei läuft
  nativ, damit Dateisystem-/Datenbankzugriffe und Sitzungszustand real geprüft
  werden. Keine Tests gegen reguläre Nutzerbestände.
- Linux-Release 0.7.3 lokal installiert; sämtliche kopierten Dateien gegen den
  Release-Build geprüft. Vorherige App als Rückfallkopie erhalten. Schema 5,
  Bundle-Kennung und regulärer Datenpfad unverändert. Laufende App nicht beendet;
  neue Bedienung wird nach einem App-Neustart aktiv.
