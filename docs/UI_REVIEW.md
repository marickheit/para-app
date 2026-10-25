# Kritische Bewertung der Zieloberfläche

Stand: 25. Oktober 2026. Kritische Bewertung der Referenz und ihrer Flutter-Umsetzung.
Optionale Vorschläge sind keine weitere Funktionsfreigabe. Verbindliche Anforderungen stehen im [UI-Umzug](UI_UMZUG.md).

## Bewusste Gegenprüfung

| Risiko / Gegenbeispiel | Behandlung in der Vorlage | Stand in Flutter 0.4 |
| --- | --- | --- |
| Beim Dateiwechsel geht ein noch nicht gespeicherter Text verloren | Weiter bearbeiten, Verwerfen und Speichern & wechseln geprüft | Über echte Speicher-/Wechselabläufe geprüft |
| „Neu“ erzeugt Inhalte im falschen Ordner | „Neu in: …“ nennt das Ziel; Kontextaktion verwendet ihren Container | Zielanzeige und Container-Kontext vorhanden |
| Ziehen verschachtelt einen Ordner in sich selbst | Selbst-/Nachfahrenziele ausgeschlossen; Projektwurzeln nicht ziehbar | Repository sperrt Zyklen und verschachtelte Projekte |
| Ein verschobener Ordner lässt Aufgaben im alten Projekt zurück | Projektzuordnung aus der aktuellen Elternstruktur; geprüft | Gruppierung aus aktueller Projektidentität/Vorfahren |
| „Nicht mehr relevant“ sieht wie erfolgreich erledigt aus | Eigenes Symbol und Text; separate Ansicht; Wiederaufnahme möglich | Schema 3 speichert Abschluss und vorherigen Status |
| Irgendwann verliert seine Kontextaktionen | Drei Punkte und Rechtsklick mit Bearbeiten, Verschieben, Abschluss und Projektumwandlung | Gemeinsame Aktionen in allen GTD-Ansichten |
| Ein importierter Dateiname überschreibt einen vorhandenen Inhalt | Import behält beide mit Namenszusatz; interner Namenskonflikt wird blockiert | Import bewahrt beide Objekte mit eigenen UUIDs; gleiche Anzeigenamen sind möglich. Endgültige Konfliktbedienung offen |
| Archivierte Aufgaben werden weiter bearbeitet | Aufgaben bleiben sichtbar, Abschlussfeld gesperrt; Wiederherstellen als Aktion | Einzelne Inhalte wiederherstellen und schreibgeschütztes Archiv geprüft |

## Verbleibende Grenzen und Kritik

- Die sichtbaren Drei-Punkte-Menüs verbessern die Auffindbarkeit, nehmen aber
  Breite. Lange Dateinamen umbrechen früher. Eine reale Fensterprüfung mit vielen
  langen Namen ist wichtiger als nur die leere Beispielansicht.
- Zwei Navigationsspalten kosten weiterhin Platz, vor allem mit eingeblendeten
  Namen. Die passende Breite muss am echten Editor überprüft werden.
- Der MD-Editor zeigt Quelltext oder Vorschau. Ein vollständiger Obsidian-artiger
  Live-Preview-Editor mit eingebetteten Links/Dateien ist damit noch nicht entschieden.
- Die Formulierungen für „Erledigt“ und „Nicht mehr relevant“ sind verständlich;
  Symbol und Text trennen beide Zustände. Wiederaufnahme und dauerhafte Speicherung
  sind umgesetzt; ein zusätzlicher Verlauf ist nicht beschlossen.
- Echte PDF-Vorschau, Dateitextsuche, Import und Speicherung wurden getrennt in
  Flutter geprüft. Format-/Größenlimits bleiben bewusst sichtbar dokumentiert.
- Das Menüfenster enthält Daten & Sicherung. Weitere Einstellungen wurden nicht
  ergänzt, nur um das Menü zu füllen.

## Optionale Vorschläge zur nächsten Iteration

1. Rückgängig für Verschieben/Import, mit einem kurzen Hinweis auf das Ziel.
2. Explorer unabhängig von der Symbolleiste ausblenden und seine Breite direkt
   ziehen können; das schafft bei langen Schreibphasen mehr Platz.
3. Mehrfachauswahl und Sammelaktionen erst ergänzen, wenn der Einzelablauf stabil ist.
4. Live Preview / Autosave ausdrücklich gegen den bestehenden Speicherablauf abwägen.
5. Cmd+F als globale Suche ist bestätigt; eine spätere Dokumentsuche braucht eine
   klare Abgrenzung und ein zusätzliches Kürzel.
6. Weitere Menüinhalte erst bei konkretem Bedarf ergänzen; Daten & Sicherung ist vorhanden.

Diese Punkte sind Vorschläge und werden erst nach Auswahl zu Anforderungen.
