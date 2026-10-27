# Markdown-Editor: interaktiver Entwurf

Designvorschau: `markdown-editor.html`. Eigenständiger Entwurf mit synthetischen
Beispielinhalten, keine native Abnahme. Der aktuelle Flutter-Stand und seine
Grenzen stehen im [Editorvertrag](../MARKDOWN_EDITOR_UMSETZUNGSPLAN.md).
Die Darstellung des Entwurfs kann davon abweichen: Für die Umsetzung wurde
Return als Absatzabschluss mit sofortigem Rendern und der Verzicht auf die
im Mock noch sichtbare grüne Aktivmarkierung bestätigt.

Gewünschte Richtung: drei Modi mit Live-Bearbeitung als Standard, bearbeitbarem
Markdown-Quelltext und gerenderter Leseansicht mit bedienbaren Checkboxen.
Im Live-Modus zeigt der aktive Textblock seine Markdown-Syntax. Tabellen sind
in diesem Entwurf direkt über Zellen bearbeitbar; Quelltext zeigt ihre Syntax.

Der überarbeitete Entwurf bündelt Dateitab, Moduswahl, Formatmenü, Tabellenanlage
und Speichern in einer gemeinsamen kompakten Kopfzeile. Keine zusätzliche
Titelzeile, dauerhafte Formatleiste oder Fußleiste. Formatierung, Syntaxhilfe und
Rückgängig/Wiederholen liegen im aufklappbaren „Aa“-Menü.

„Tabelle“ öffnet ein Raster mit acht Spalten und sechs Zeilen. Mausbewegung oder
Tastaturfokus markiert die Größe, Klick fügt die Tabelle ein. Die erste gewählte
Zeile ist die Kopfzeile. Die Rastergröße begrenzt nur diese Einfügehilfe;
anschließend lassen sich weitere Zeilen und Spalten hinzufügen.

Klick auf eine Tabellenzelle aktiviert die direkte Eingabe und zeigt lokale
Aktionen: Zeile darunter hinzufügen, ausgewählte Datenzeile löschen, Spalte
rechts hinzufügen, ausgewählte Spalte löschen. Die Kopfzeile und mindestens eine
Spalte bleiben bestehen. Tab/Enter wechselt zur nächsten vorhandenen Zelle,
Shift+Tab zurück; „Fertig“ oder Escape beendet die Tabellenbearbeitung.
Löschen lässt sich im Formatmenü rückgängig machen.

Der Mock zeigt umsetzbare Flutter-Bausteine: Buttons, verankerte Overlays,
Maus-/Fokusverfolgung im Raster, Textfelder, Markdown-Darstellung und Checkboxen.
Explorer und Navigation bleiben als Kulisse bestehen; bei schmaler Vorschau
werden sie ausgeblendet. Kleine Breiten lassen die gemeinsame Kopfzeile umbrechen.

Bedienbar sind Moduswechsel, Block- und Zellenbearbeitung, Checkboxen,
Formatbuttons, Tabellenanlage und Strukturänderungen, Hilfe sowie lokales
Rückgängig/Wiederholen. Der Punkt am Dateinamen zeigt Änderungen.
„Speichern“ hält ausschließlich den Text in dieser Vorschau; es greift auf
keinen Arbeitsbereich zu.

Grenzen: vereinfachtes Markdown-Rendering und Tabellenformat; keine echte
Dateispeicherung, Linknavigation, internen Verknüpfungen oder vollständige
Editor-Tastatursteuerung. Tabellen mit Zellenformatierung und Sonderzeichen,
Auswahl über Blockgrenzen, Cursor-/Scrollstabilität, vollständige Markdown-Syntax,
Konfliktschutz, Versionsverlauf und Leistung großer Dokumente müssen in der
Flutter-Umsetzung entwickelt und geprüft werden. Die Vorschau bestätigt keine
bereits vorhandene Flutter-Implementierung.
