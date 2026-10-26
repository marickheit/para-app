# Auswahl, Übersicht und Anlegen

Stand: 26. Oktober 2026. Vom Nutzer bestätigter Umfang, umgesetzt in 0.7.3.

## Verbindliche Bedienung

- Kategorie öffnen zeigt zunächst deren Übersicht ohne automatische Auswahl.
- Klick auf Projekt/Bereich/Ressourcensammlung wählt sichtbar aus, klappt auf
  und zeigt die Übersicht mit Beschreibung, Inhalten und Projektaktionen.
  Erneuter Klick wählt ab und klappt zu. Ordner verhalten sich entsprechend;
  beim Abwählen eines Unterordners wird sein Elterncontainer ausgewählt.
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
  werden. Ungespeicherte Texte blockieren auch Auswahlwechsel und Abwählen.

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

Reine Bedienänderung, Schema 5 und gespeicherte session.v1 bleiben lesbar.
Keine Nutzdatenmigration, kein neuer Datenordner. Vorhandene freie Inhalte auf
Bereiche-/Ressourcen-Wurzelebene bleiben lesbar und als explizite Ziele nutzbar.
MCP-Erweiterungen für Bereich/Ressource/Ordner sind separate offene Arbeit;
vorhandene MCP-Operationen und Daten bleiben unverändert.

## Prüfnachweise

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
