# Dateifläche, Tabs und verstellbarer Explorer

Stand: 28. Oktober 2026 · aktueller Bedienvertrag in Flutter 0.10.1, umgesetzt
seit 0.9.0. A mit optionalem B und verstellbarem Explorer. Die versionsgebundenen
Nachweise am Ende gelten für 0.9.0+13; aktueller [Prüfstand](UMSETZUNGSPLAN.md).

## Bestätigter Umfang

- Variante **A** ist die Grundlage: breite Dateifläche, Dateitabs und kompakter
  Dateikopf. [Interaktiver Entwurf](mockups/para-datei-tabs.html),
  [Ansichten und Grenzen](mockups/DATEI_TABS.md).
- Variante **B** ist optional erreichbar: Explorer ausblenden und wieder einblenden.
- Die Explorer-Breite lässt sich an der rechten Kante mit der Maus ziehen.
  Ausblenden allein reicht nicht.
- Geteilte Ansichten wie **C** sind zurückgestellt, bis Bedarf besteht.

Die folgenden Bedien- und Zahlenwerte sind konkrete Umsetzungsvorgaben dieses
Plans. Sie konkretisieren die Auswahl; Mock-Beispieldaten sind keine Produktvorgaben.

## Zielbedienung

### Dateifläche

- Markdown-Dateitabs und Editoraktionen bilden seit 0.10.0 eine gemeinsame
  kompakte Zeile; keine zweite Markdown- oder Container-Kopfzeile darunter.
  Schmale Fenster dürfen die Zeile umbrechen. Andere Vorschauen/TXT behalten
  ihren Dateikopf. Containeransichten behalten Übersicht/Inhalte/Aufgaben.
  [Aktueller Markdown-Editorvertrag](MARKDOWN_EDITOR_UMSETZUNGSPLAN.md).
- Der Inhalt erhält die restliche Fensterfläche; Kopfzeile und Dateivorschauen
  bleiben breit. Seit 0.10.1 startet Text ohne gespeicherte Breitenwahl zentriert.
- Markdown-Lesespalte: 680 Pixel Text plus bis zu 32 Pixel Innenabstand je Seite,
  oben 48 Pixel. TXT-Lesebreite: 760 Pixel einschließlich 24 Pixel Innenabstand.
  „Volle Breite“ hebt die Begrenzung auf, „Lesebreite“ stellt sie wieder her.
  Gemeinsame Einstellung für Textansichten im Arbeitsbereich; gespeicherte Wahl erhalten.
- PDF nutzt die verfügbare Höhe und Breite statt eines 520 Pixel hohen Kastens.
  Seitenbreite als Ausgangsansicht; Zoom und Scrollen innerhalb der PDF-Vorschau.
- Rasterbilder und SVG proportional in die verfügbare Fläche einpassen; keine
  feste 330-Pixel-Höhe. CSV erhält den verfügbaren Bereich mit eigenem Scrollen.
  Bestehende Format-, Größen- und Suchgrenzen gelten weiter.
- Dateiname/Notiztitel bleibt im Tab. Markdown-Notizen erhalten keinen zweiten
  Titeltextblock; „Weitere Dateiaktionen“ bietet „Notiz umbenennen“, Verlauf,
  Infos und Lesebreite. Änderungen am Titel anschließend speichern. Speichern
  und sonstige Dateiaktionen bleiben erreichbar; vollständigen Pfad auf Abruf zeigen.
- Große Vorschauen erhalten begrenzte Layoutmaße; kein PDF-Viewer in einem
  äußeren, unbegrenzt hohen Scrollbereich. Text hat einen eigenen Scrollbereich.
  Nicht unterstützte Dateien behalten Export und Öffnen mit Standard-App.

### Explorer ziehen und ausblenden

- Symbolleiste und Explorer werden unabhängig angeordnet. Die bestehende
  Umschaltung zwischen Symbolen und Namen bleibt erhalten.
- Rechte Explorer-Kante mit sichtbarer Linie, etwa 8 Pixel breiter Trefferfläche
  und horizontalem Resize-Cursor. Ziehen verändert die Breite kontinuierlich;
  es startet weder einen Datei-Drag noch einen Import.
- Startbreite 270 logische Pixel; regulärer Bereich 220–520 Pixel. Zusätzlich
  mindestens 480 Pixel für den Hauptbereich reservieren. Die aktuell wirksame
  Obergrenze ergibt sich aus Fensterbreite minus Symbolleiste, Griff und Hauptbereich.
- Die gewünschte Breite separat von der momentan möglichen Breite speichern.
  Fensterverkleinerung begrenzt nur die Darstellung; nach Vergrößerung kommt die
  gewünschte Breite zurück. Erweiterung der Symbolleiste berücksichtigt dieselbe Regel.
- Wenn 220 Pixel Explorer plus Mindesthauptbereich nicht hineinpassen, Navigation
  als Overlay/Drawer öffnen. Keine negative Breite oder permanente Verkleinerung
  der gespeicherten Einstellung. Im Overlay keine Resize-Kante.
- Doppelklick am Griff stellt 270 Pixel wieder her. Fokussierbarer Griff mit
  verständlichem Namen: Links/Rechts ändern um 10 Pixel, Home setzt zurück.
- Button „Explorer ausblenden“ schaltet nach **B**: Nur Symbolleiste, Tabs und
  Inhalt bleiben sichtbar. „Explorer einblenden“ bringt Baum, Auswahl,
  Scrollposition und bisherige Breite zurück; auch ohne offenen Tab erreichbar.
- Bestehendes Cmd/Ctrl+\ blendet weiterhin die gesamte Navigation ein/aus.
  Dieser Zustand und der Explorer-Fokuszustand sind getrennt: vollständiges
  Wiedereinblenden stellt den vorherigen Explorerzustand wieder her.
- Ziehen, Fokuswechsel und Fensteränderungen dürfen einen Editor nicht neu
  erzeugen und keinen Speicherdialog auslösen. Sitzungsbreite nach Ende des
  Ziehens speichern; keine Datenbankschreibserie pro Pointerbewegung.

### Dateitabs

- Eine gemeinsame Tabreihe für Dateien und Notizen des geöffneten Arbeitsbereichs,
  auch über Projekte und Kategorien hinweg. Identität über UUID, nicht Dateiname/Pfad.
  Aufgaben, Ideen und Containeransichten bleiben zunächst in ihren bisherigen Ansichten.
- Ein Klick im Explorer öffnet einen temporären, kursiven Vorschautab. Der nächste
  neue Vorschauinhalt ersetzt ihn. Bereits geöffnete Inhalte wählen ihren vorhandenen
  Tab aus; gleiche Namen an verschiedenen Orten bleiben unterscheidbar über Pfad-Tooltip.
- Doppelklick oder Tabaktion „Tab behalten“ macht die Vorschau dauerhaft.
  Beginn einer Bearbeitung behält den Tab ebenfalls. Neue Texte und Öffnen über
  Suche, Dateiwechsel oder internen Link erzeugen/behalten einen dauerhaften Tab.
- Schließen über Kreuz, mittlere Maustaste oder Cmd/Ctrl+W innerhalb der App.
  Mit offenem Dialog gilt dessen Tastatursteuerung. Ohne Dateitab bleibt die
  bisherige Fensterfunktion von Cmd/Ctrl+W erhalten.
- Aktiven Tab schließen wählt den rechten Nachbarn, sonst den linken. Letzten
  schließen zeigt die zugehörige Container- oder Kategorieansicht. Keine Demo-Datei
  offen halten und keine neuen Inhalte erzeugen.
- Viele Tabs horizontal scrollen; aktiven Tab sichtbar halten. Dateinamen kürzen,
  Tooltip und Liste „Offene Dateien“ für den schnellen Wechsel anbieten.
  Fokus und Pfeiltasten im Tabstreifen funktionieren unabhängig vom Texteditor.
- Plus am Tabstreifen öffnet den Dateiwechsel und trägt dessen Tooltip.
  Neuanlage bleibt über Explorer-Plus und Cmd/Ctrl+N erreichbar, auch in B.
- Kategorie-/Container-/Aufgabenwechsel lässt die offenen Tabs erhalten, zeigt aber
  die gewünschte Ansicht. Es gibt dann keinen sichtbar aktiven Dateitab. Tabklick
  öffnet wieder genau dessen Datei und synchronisiert Kategorie, Baum und Anlageziel.
- Umbenennen und Verschieben aktualisieren Tabtitel/Pfad ohne Duplikate.
  Archivieren und Papierkorb ändern den geöffneten Inhalt in die vorhandene
  schreibgeschützte Ansicht mit passendem Hinweis. Endgültig entfernte Inhalte
  schließen ihre Tabs; eine extern fehlende Anhangsdatei zeigt einen Fehler,
  ohne Inhalt zu löschen oder eine leere Datei anzulegen.
- Pro Texttab Modus und Scrollposition während der Sitzung merken (Markdown ab
  0.10.0 Live/Quelltext/Lesen, TXT Bearbeiten/Vorschau);
  PDF-Zoom/-Position beim Wechsel bestmöglich erhalten. Keine zweite gleichzeitig
  aktive Editorfläche und kein Ziehen von Tabs in Splits in dieser Iteration.

### Speichern und sichere Übergänge

- Weiter explizit speichern, kein Autosave. Höchstens der sichtbare Editor hat
  ungespeicherte Änderungen. Wechsel zu einem anderen Tab oder einer anderen
  Ansicht fragt wie bisher Speichern/Verwerfen/Abbrechen.
- Abbrechen lässt Text, Auswahl, Tabfolge und Vorschautab unverändert. Erst nach
  erfolgreichem Speichern/Verwerfen wird die Navigation oder Tabentfernung angewendet.
  Fehlgeschlagenes Speichern verhindert den Wechsel.
- Aktiven Tab erneut anklicken, inaktiven Tab schließen, Resize und Fokusmodus
  berühren den Entwurf nicht. Editor mit stabiler UUID und stabiler Widget-Identität
  halten; reine Layoutänderungen dürfen ihn nicht entladen.
- Rootwechsel und App-Beenden verwenden denselben Schutz. Keine ungespeicherten
  Texte in die Sitzungsdaten schreiben; automatische Entwurfsrettung bleibt offen.
- Den vorhandenen Revisions-/Hashschutz und McpEditorGuard erhalten. Während eines
  geschützten Entwurfs muss eine MCP-Änderung weiterhin abgewiesen werden; nach
  einem erfolgreichen Wechsel dürfen keine veralteten Editorsperren übrig bleiben.

## Technischer Zuschnitt

`lib/ui/workspace_screen.dart` koordiniert Navigation, Auswahl und einen aktiven
Editor über `GlobalKey<EntryEditorState>`. `document_tabs.dart` kapselt die
UUID-Tabfolge, `explorer_resize.dart` den Griff und `workspace_session.dart`
Validierung/Übernahme von Format 1 nach 2. `entry_editor.dart` trennt den festen
Kopf vom begrenzten Inhaltsbereich; `file_preview.dart` nutzt die verbleibende Fläche.
Die Aufteilung folgt diesen Regeln:

1. Reinen Tabzustand mit UUID-Reihenfolge, aktivem Tab, Vorschautab und
   Zustandsübergängen aus der Screen-Klasse lösen. Zunächst einen aktiven Editor
   weiterverwenden; keine Sammlung versteckter Editoren mit eigenen Entwürfen.
2. Navigation in Symbolleiste, Explorer und Resize-Griff trennen. Gemeinsame
   Berechnung für tatsächlich verfügbare Breiten verwenden, auch in Kopfzeile,
   Drawer und Datei-Dropzielen. Keine neue Desktop-Gesamtbreite hart codieren.
3. Gemeinsamen Dateikopf außerhalb der scrollenden Texte/Vorschauen platzieren.
   EntryEditor erhält einen begrenzten Inhaltsbereich und meldet Titel-/Dirtyzustand
   nach außen. Vorschauen nach Format statt über gemeinsame Textbreite layouten.
4. Alle Öffnungspfade auf denselben Tab-/Navigationsübergang führen: Baum, Suche,
   Link, Neuanlage, Import, Wiederherstellung und bestehende Dateiaktionen.
   Aufgaben-/Containereditoren behalten dabei ihren bisherigen Speicherschutz.
5. Sitzung getrennt von flüchtigem Darstellungszustand serialisieren; keine
   Editorcontroller, Texte, Binärdaten oder vollständigen PDF-Dokumente speichern.

## Sitzung und Datenkompatibilität

- Neues Sitzungsformat **2** unter `workspace_settings` / `session.v2`: bisherige
  Navigation und Filter plus dauerhafte Tab-UUIDs/Reihenfolge, aktive Inhaltsansicht,
  gewünschte Explorer-Breite, Explorer-Sichtbarkeit und Textlesebreite.
  Ein temporärer Vorschautab wird beim regulären Neustart nicht wiederhergestellt.
- Bestehende `session.v1` verlustfrei übernehmen: Navigation, Auswahl, Filter,
  Baumzustand und Sichtbarkeit erhalten; bislang geöffnete Datei/Notiz wird ein
  dauerhafter Tab, Aufgaben und Container bleiben ihre jeweilige Ansicht.
  Fehlende neue Felder bekommen die oben beschriebenen Voreinstellungen.
- Schema 6 und Sicherungsformat 3 bleiben erhalten; nur der versionierte
  Sitzungswert wurde ergänzt, keine neue maßgebliche Inhaltstabelle.
  Vor der ersten Übernahme vollständigen konsistenten Rückfallexport erstellen.
  Erst nach erfolgreicher Validierung `session.v2` aktivieren; `session.v1` erhalten.
- Unbekannte neuere oder beschädigte Sitzungsformate nicht überschreiben;
  Wiederherstellungsfehler anzeigen und automatische Sitzungsschreibvorgänge sperren,
  bis der Zustand bewusst geklärt ist. Niemals deswegen einen leeren Root öffnen.
- UUIDs deduplizieren, Typen/Version prüfen, Breiten auf endliche gültige Zahlen
  prüfen. Fehlende Inhaltskennungen nachvollziehbar melden und überspringen;
  existierende Archiv-/Papierkorbziele mit ihrem aktuellen Schreibschutz öffnen.
- Alle Einstellungen bleiben im Root und werden mitkopiert/gesichert.
  Schmale Zielgeräte begrenzen nur die Anzeige. Keine neuen globalen Präferenzen.
  Eine alte App mit neuem Bestand ist kein unterstützter Rückfall; passendes
  App-/Sicherungspaar verwenden.

## Umsetzung und Abnahme

| Schritt | Ergebnis | Erforderlicher Nachweis |
| --- | --- | --- |
| 1. Tabzustand und Übergänge | Einheitliche Regeln ohne UI-Sonderpfade | Zustandsprüfungen für Vorschau, Behalten, Duplikate, Nachbartab und leere Tabreihe |
| 2. Navigation und Resize | Ziehbare Breite, B und schmale Navigation | Widgettests mit langen Namen, beiden Symbolleistenbreiten, Resize-Grenzen, Tastatur und Fensterwechsel |
| 3. Dateifläche | Breiter Text, begrenzte Lesebreite, flächenfüllende Vorschauen | Layouttests plus native Darstellung für MD, TXT, mehrseitiges PDF, Rasterbild, SVG, breite CSV und unbekanntes Format |
| 4. Tabs integrieren | Öffnen/Schließen über alle relevanten Wege | Native Abläufe über mehrere Projekte, Kategorien, Suche und Links; UUID bleibt beim Umbenennen/Verschieben erhalten |
| 5. Schutz und Ereignisse | Entwürfe und MCP-Konflikte bleiben korrekt | Speichern/Verwerfen/Abbrechen, Speicherfehler, Rootwechsel, Beenden, Papierkorb/Archiv und endgültiges Entfernen |
| 6. Sitzung übernehmen | Neustart und Rückholung mit Format 2 | Repräsentative session.v1-Fixtures, unabhängiger Sicherungsexport/-rückholung, zwei getrennte Roots, unbekannte/beschädigte Formate |
| 7. Abnahme und Dokumentation | Bedienung und Grenzen entsprechen der App | Flutter analyze, vollständige Flutter-Tests, betroffene native Linux-/macOS-Abläufe; offene Plattformnachweise ausdrücklich benennen |

Zusätzlich prüfen: ein langer ungespeicherter Text über Resize → B → A bleibt
zeichengetreu und am selben Bearbeitungsort; 30 Tabs sind noch erreichbar; während
eines Dialogs startet kein zweiter Wechsel; PDF-Scrollen und Explorer-Resize
beeinträchtigen Datei-Drops nicht. Bestehende Anlageziele, Kontextaktionen,
Papierkorb, Verlauf und Aufgabenfilter regressionsprüfen.

Alle Tests ausschließlich mit synthetischen Inhalten in temporären Roots;
manuelle Starts mit `--dart-define=PARA_DATA_DIR=...`. Keine Nutzerbestände als Testdaten.
README, UI-Anforderungen, Architektur, Arbeitsbereiche und Sicherung beschreiben
die umgesetzten Regeln. Der Standard-Datenpfad und die Bundle-Kennung bleiben stabil;
Sitzungsübernahme erfolgt erst beim Öffnen mit der neuen App und nach Rückfallexport.

## Später

Splits wie C, mehrere gleichzeitig ungespeicherte Editoren, Tabgruppen,
frei verschiebbare Tabs, Autosave und Entwurfswiederherstellung gehörten nicht
zur Tab-Iteration. Markdown-Live ist inzwischen im [Editor 0.10.0](MARKDOWN_EDITOR_UMSETZUNGSPLAN.md)
umgesetzt; die folgenden ursprünglichen Tabnachweise bleiben an 0.9.0 gebunden.

## Prüfnachweise 0.9.0

- `flutter analyze --no-pub`: ohne Befund.
- `flutter test --no-pub`: alle 115 Tests erfolgreich; neue Tests in
  `test/document_tabs_test.dart` und `test/explorer_resize_test.dart`.
- `integration_test/file_tabs_test.dart` nativ unter Linux: fünf Abläufe erfolgreich.
  Langer Entwurf über Resize/B/A und Cursorposition erhalten; Speichern/Abbrechen,
  Vorschautab, dauerhafter Tab, letzter Tab, Formatvorschauen, alte Sitzung mit
  Rückfallexport, Neustart, Breite bei Fensteränderung, unbekannte neue Sitzung,
  30 Tabs, Kategorien, Umbenennen/Verschieben, Archiv und Papierkorb geprüft.
- `integration_test/workspace_test.dart`: zwölf bisherige Linux-Abläufe erfolgreich,
  ein macOS-spezifischer Test übersprungen. Bestehende Prüfungen nur für die
  beabsichtigte Kopfzeilenänderung angepasst; Import/Datei-Drag, Suche, Textverlauf,
  Rückholung, Aufgaben und Rootwechsel bleiben geprüft.
- `integration_test/creation_test.dart`: zehn native Linux-Abläufe erfolgreich.
- Unabhängige Rückholung der vor Sitzungsübernahme exportierten Sicherung mit
  UUIDs, Text, Anhangsbytes, internen Links, Papierkorb und Textversionen erfolgreich.
- Linux-Release gebaut und lokal installiert; alle 24 Paketdateien stimmen per
  SHA-256 mit dem Build überein. Bisherige App als vollständiges Rückfallpaket unter
  `~/.local/opt/para-workspace-backup-before-0.9.0-…` erhalten. Launcher unverändert.
  Die installierte Release-App startet mit temporären XDG-Verzeichnissen erfolgreich
  und schreibt Format 2 bei unverändertem Schema 6. Keine Nutzdaten als Testumgebung.
- Native macOS-Abnahme noch offen, insbesondere Menüweiterleitung von Cmd+W und
  Sitzungsübernahme in freigegebenen Ordnern. Splits bleiben ausgeschlossen.
