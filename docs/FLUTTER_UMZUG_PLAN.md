# Umsetzung der bestätigten Zieloberfläche in Flutter

Stand: 25. Oktober 2026. In Flutter 0.4 umgesetzt und geprüft; Referenz:
[mockups/para-zieloberflaeche.html](mockups/para-zieloberflaeche.html).
Keine neuen optionalen Produktfunktionen aus dem Review vorwegnehmen.

## Arbeitsschritte

- [x] Datenhaltung: „Nicht mehr relevant“ dauerhaft speichern, vorherigen Status
  für Wiederaufnahme erhalten; bestehende Daten migrieren. Textdateien sicher lesen,
  bearbeiten und für unterstützte Formate indizieren.
- [x] Darstellung: schmale/ausgeklappte Symbolleiste, benachbarter Explorer,
  gemeinsame kompakte Kopfzeile, Dateikopf/Editor und Menü unten nach Vorlage.
- [x] Explorer: alle Projekte auf oberster Ebene; Ordner per Zeilenklick aufklappen,
  Dateien direkt anzeigen; Plusmenü, gleiche Kontext-/Drei-Punkte-Aktionen,
  Zielanzeige, Datei-/Ordnerimport und Verschieben in allen aktiven Ablagen.
- [x] Editor/Vorschau: MD und TXT mit explizitem Speichern und Änderungsschutz;
  Metadaten über Info, unterstützte Vorschau, lokale Dateiaktion für andere Formate.
- [x] Aufgaben/Suche: globale GTD-Ansichten, nächste Aktionen nach Projekt,
  erledigt und nicht mehr relevant unterscheiden/wiederaufnehmen; Suchfenster
  mit Cmd/Ctrl+F, unscharfen Namen, unterstützten Inhalten und Pfeiltasten.
- [x] Prüfung: Repository-/Widgettests, Migration und Wiederöffnen, native Mac-Abläufe,
  schmale Fenster sowie visueller Abgleich mit dem Mockup; Release bauen/starten.
- [x] Dokumentation auf den tatsächlichen Stand bringen, Grenzen und Prüfergebnis
  festhalten. Mockup und reale Funktionen weiterhin klar unterscheiden.

## Erhaltungsregeln

UUIDs, Dateien, Notiztexte und stabile Links erhalten. Archiv nach Jahr/Herkunft
und ursprünglichen Ordnern weiterführen. Aktive Projekte nicht verschachteln.
Importiert wird als lokale Kopie; Änderungen bleiben explizit zu speichern.
Tests verwenden getrennte temporäre Arbeitsbereiche; Nutzerdaten nicht mit
Beispieldaten befüllen oder ersetzen.

Nachweise: [Prüfstand](UMSETZUNGSPLAN.md). Formatgrenzen und offene Vorschläge
stehen im [UI-Umzug](UI_UMZUG.md), die Bedienung in [README.md](../README.md).
