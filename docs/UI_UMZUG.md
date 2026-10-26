# Zieloberfläche und Umzug nach Flutter

Stand: 26. Oktober 2026. Verbindliche Nutzeranforderungen und Abnahmekriterien,
kein Gesprächsprotokoll. Bei neuen Entscheidungen diese Beschreibung aktualisieren.

## Grundlage und Status

Die bestätigte Symbolleisten-/Explorer-Vorlage ist in Flutter 0.4 umgesetzt:
Anordnung, Farben, Symbole, Abstände, Editor, gemeinsame Kopfzeile, Dateiaktionen,
Aufgabenansichten und schmale Navigation orientieren sich eng am Mockup.

Die [Referenzquelle](mockups/para-zieloberflaeche.html) bleibt ein interaktiver
HTML/CSS/JavaScript-Entwurf mit Beispieldaten. Die reale App verwendet dieselben
Bedienideen mit dauerhaft gespeicherten Inhalten, echten Dateivorschauen und
nativen Datei-Drops. Die Beispieldaten wurden nicht in den Nutzerarbeitsbereich übernommen.

## Bestätigte Anforderungen

- Symbolleiste zwischen Symbolen und Namen umschaltbar; Menübutton unten mit
  öffnendem Menüfenster. Weitere Menüinhalte sind noch nicht festgelegt.
- Projekte visuell von Ordnern unterscheiden. Aktive Projekte stehen nur auf
  oberster Ebene; im Archiv gilt weiterhin Jahr → Herkunft → ursprüngliche Struktur.
- Ordner per Zeilenklick auf-/zuklappen. Notizen und Dateien vollständig im Baum
  anzeigen, auch in Ordnern wie „Unterlagen“. Keine feste Beispiel-Ordnerstruktur erzwingen.
- Unterstützte Dateien im Hauptbereich rendern, Metadaten über ein kleines
  Info-Symbol zeigen; für andere Formate Download beziehungsweise lokale Dateiaktion.
- Markdown-Notizen anlegen, bearbeiten und anzeigen. Auch gängige Textdateien,
  insbesondere TXT, intern bearbeiten. Weitere Textformate einzeln festlegen;
  daraus folgt keine Bearbeitung beliebiger Binär-/Office-Dateien.
- Explizites Speichern und Schutz ungespeicherter Änderungen beim Wechseln
  beibehalten. Ein Obsidian-artiger Arbeitsablauf bedeutet hier noch keine
  Entscheidung für Autosave oder einen bestimmten Live-Preview-Editor.
- Sichtbare Anlage-/Importaktion und Rechtsklick für Dateien, Ordner und Projekte;
  Drei-Punkte-Menü bietet dieselben verfügbaren Aktionen. Auch Aufgaben und
  „Irgendwann / Vielleicht“ behalten ihre Aktionen einschließlich Projektumwandlung.
- Dateien und Ordner im Baum per Drag-and-drop verschieben. Alternativ per
  Rechtsklick „Verschieben …“ mit Zielwahl, auch aus einem Projekt in Inbox,
  Bereiche oder Ressourcen. Projekte bleiben Projekte auf oberster Ebene;
  sie werden durch Verschieben nicht zu Unterordnern oder anderen Inhaltstypen.
- Externe Dateien per Auswahl und Drag-and-drop importieren: Inbox, Projekte,
  Bereiche, Ressourcen und deren Ordner. Externer Import erstellt lokale Kopien;
  internes Verschieben verändert den Ablageort desselben Objekts und erhält Links.
- Globale „Nächste Aktionen“ nach zugehörigem Projekt gruppieren, einschließlich
  Aufgaben in Projekt-Unterordnern; Aufgaben ohne Projekt separat anzeigen.
- Aufgaben können „Nicht mehr relevant“ sein. Von „Erledigt“ unterscheiden,
  sichtbar kennzeichnen und nicht als offene nächste Aktion zählen. Nicht löschen.
  Ein eigenes Symbol, Durchstreichen und Text kennzeichnen den Zustand.
  Wiederaufnahme stellt den vorherigen Arbeitsstatus wieder her; Schema 3 speichert ihn.
  Alte erledigte Aufgaben ohne gespeicherte Historie starten wieder als nächste Aktion.
- Lupe oder Cmd+F / Strg+F öffnet eine schwebende Suche: unscharfe Namen und
  Inhalte unterstützter Formate, Tastaturauswahl, Enter und Esc. Weiterer Suchausbau später.

## Umsetzung und Grenzen

- Die Symbolleiste ist 56 bzw. 164 Pixel breit; der Explorer startet bei 270 Pixel
  und ist zwischen 220 und 520 Pixel verstellbar, abhängig vom Fenster.
  Dateifläche breit, Textlesebreite optional 760 Pixel. Schmale Fenster nutzen
  eine überlagerte Navigation.
- Menü unten öffnet Daten & Sicherung; weitere Einstellungen wurden nicht erfunden.
- MD und TXT sind mit explizitem Speichern bearbeitbar. UTF-8-/Größenprüfung und
  Hash-/Revisionsprüfung schützen externe Änderungen. Dateiumbenennung erhält Links.
- PDF, Rasterbilder, SVG und CSV haben echte Vorschau. Text-/PDF-Suche arbeitet
  innerhalb der in [README.md](../README.md) beschriebenen Format- und Größenlimits.
- Interner Umzug ändert den Ablageort desselben Objekts; Import erstellt neue lokale
  Kopien. Aktive Projekte bleiben auf oberster Ebene, Selbst-/Nachfahrenziele sind gesperrt.
- Globale nächste Aktionen gruppieren nach Projektidentität, auch bei gleichnamigen
  Projekten. Aufgaben in verschobenen Ordnern erhalten ihre neue Zuordnung automatisch.
- Das native macOS-Find-Menü ist an die schwebende Suche angeschlossen. Cmd/Ctrl+K
  bleibt als bestehendes Kürzel erhalten; Cmd/Ctrl+O bleibt auf Namen beschränkt.
- Es gibt weiterhin keinen Live-Preview-Editor, kein Autosave, keine Mehrfachauswahl
  und kein allgemeines Rückgängig für Verschieben/Import.

[Umsetzungsplan](FLUTTER_UMZUG_PLAN.md) · [Aktuelle Prüfungen](UMSETZUNGSPLAN.md).

## Abnahmekriterien

- Anlegen → bearbeiten → speichern → wieder öffnen ohne Inhaltsverlust.
- Ungespeicherte Änderungen bei Datei-/Ansichtswechsel und Import erhalten.
- Rechtsklick und Drei-Punkte-Menü führen dieselben passenden Aktionen aus.
- Datei und ganzer Ordner wechseln per Ziehen und per Zielwahl zwischen Ablagen;
  keine Zyklen, keine verschachtelten aktiven Projekte, stabile Links bleiben gültig.
- Dateiauswahl und nativer Drop liefern gleiche Importregeln in allen aktiven Ablagen.
- Aufgaben in Projekt-Unterordnern werden dem richtigen Projekt zugeordnet;
  erledigt und nicht mehr relevant bleiben unterscheidbar und wiederauffindbar.
- Archivregeln, Projektumwandlung, Tastatur, Suche und schmale Fenster bleiben bedienbar.

Die App-Prüfungen betreffen echte Speicherung, Migration, Dateiverarbeitung und
native Mac-Bedienung. Die früheren Mockup-Prüfungen ersetzen diese Nachweise nicht.
[Kritische Bewertung und optionale Vorschläge](UI_REVIEW.md).

## Noch nicht ausgewählte Vorschläge

- Live Preview und Autosave versus explizites Speichern weiter vergleichen.
- Rückgängig nach Verschieben/Import und übersichtlicher Importbericht.
- Mehrfachauswahl und Sammelaktionen bei vielen Dateien.
- Eigene Dokumentsuche zusätzlich zur globalen Suche; Kürzelkonflikt auflösen.
- Weitere Textformate, Encoding-Erkennung und Größenlimits festlegen.

Diese Vorschläge sind keine beschlossenen Zusatzfunktionen.

## Dateifläche und Tabs – umgesetzt in 0.9.0

- Variante A als Grundlage: breite Dateifläche, Tabs und kompakter gemeinsamer Kopf.
- Optionaler Fokusmodus B: Explorer aus-/einblenden, Symbolleiste weiter erreichbar.
- Explorer zusätzlich an seiner rechten Kante mit der Maus in der Breite verstellen.
  Beim Wiedereinblenden die gewählte Breite wiederherstellen.
- Geteilte Ansichten wie C zurückstellen, bis sie gebraucht werden.

[Bedienvertrag und Prüfnachweise](DATEI_TABS_UMSETZUNGSPLAN.md) beschreiben
Tabbedienung, Resize-Grenzen, Speicherschutz und Sitzungsübernahme.
Die Mocks bleiben Beispieldaten; geteilte Ansichten sind keine App-Funktion.

## Ergänzung in Flutter 0.5

- Papierkorb als eigener Eintrag links direkt unter „Alle Aufgaben“, in beiden
  Breiten der Symbolleiste. Reguläre Aktion heißt „In Papierkorb“.
- Papierkorb: Ordner auf-/zuklappen, schreibgeschützte Vorschau, Herkunft und Datum,
  Wiederherstellung und gemeinsame Rechtsklick-/Drei-Punkte-Aktionen.
  „Papierkorb leeren“ in der Kopfzeile; endgültige Entfernung mit Bestätigung,
  Umfang und Rückverweisen. Keine automatische Leerung.
- Versionsverlauf über ein kleines Verlaufssymbol im Notiz-/MD-/TXT-Kopf.
  Auswahl mit Zeitstempel, Textvorschau und bestätigte Wiederherstellung als neuer
  Stand. Aktuelle Metadaten und jüngere Texte bleiben erhalten.

## Ergänzung in Flutter 0.6

- Kleine abgerundete, farbig umrandete Chips unter dem Aufgabentitel: mehrere
  Kontexte, Zeit und Energie. Bei Platzmangel umbrechen, nur gesetzte Werte anzeigen.
- Kontext-Mehrfachauswahl und optionale Zeit-/Energiefelder in den Aufgabendetails.
  Kleiner Filterbutton in Aufgabenlisten; Projektgruppierung bleibt erhalten.
- Menü → Einstellungen öffnet Kontextverwaltung (Name, Farbe, Reihenfolge,
  aktiv/inaktiv). Daten & Sicherung enthält Öffnen, Kopieren und Neuanlegen
  vollständiger Arbeitsbereiche. Cmd+, öffnet Einstellungen auf dem Mac.
- Ein Arbeitsbereich bringt seinen gespeicherten Navigations-/Filterzustand mit.
  Fenster-/Editorentwürfe ohne Speicherung werden nicht automatisch wiederhergestellt.
