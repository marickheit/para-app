# Arbeitsstand

Stand: 26. Oktober 2026 · Version 0.9.1+14.

## Implementiert

- Startzeit 0.9.1: vorhandener Index sofort nutzbar, geänderte Dateien und PDF-
  Importe im Hintergrund indexieren; unveränderte Dateien nicht erneut auslesen.
  Suchdialog mit aktuellen Treffern und Fortschritt/Fehlern. Abgeleiteter Cache
  Format 1, Schema 6 und Sicherungsformat 3 bleiben erhalten.
  [Ablauf und Prüfnachweise](STARTZEIT_UMSETZUNGSPLAN.md).

- Dateifläche und Tabs 0.9.0: A mit optionalem Fokusmodus B, ziehbarer Explorer-
  Breite und Textlesebreite. Vorschau-/dauerhafte Dateitabs, gemeinsame UUID-Tabfolge,
  kompakter Kopf und flächenfüllende Vorschauen. Speicherschutz, Sitzung Format 2
  und Übernahme mit vollständigem Rückfallexport; Schema 6 / Sicherungsformat 3.
  [Bedienvertrag und Abnahme](DATEI_TABS_UMSETZUNGSPLAN.md). Splits bleiben zurückgestellt.

- MCP-Ablage und kompakte Antworten: Bereiche/Ressourcensammlungen/Ordner anlegen,
  Titel/Projektdaten ändern und Texte gezielt anhängen/eindeutig ersetzen.
  19 Werkzeuge, kompakte Standardseiten (20), Textabschnitte (4.000) und
  64-KiB-JSON-Budget mit Fortsetzung. Schema 6 unverändert.
  [Vertrag und Umsetzungsplan](MCP_ERWEITERUNG_PLAN.md).

- Automatischer Eingangsordner 0.8.0: rekursive, bytegetreue Inbox-Übernahme,
  Ruhephase, dauerhafte Jobs und stabile UUIDs, geprüfte Zwischenkopien sowie
  Original-Rückholbereich. App-Laufzeit, Pause, Neustart und lokale Quellenbindung.
  Schema 6, Sicherungsformat 3 und getestete unabhängige Rückholung.
  [Implementierung und Abnahme](EINGANGSORDNER_UMSETZUNGSPLAN.md).

- Auswahl, Übersicht und Anlegen 0.7.3: Kategorien ohne automatische Auswahl,
  graues Anlageziel, Containerklick wählt/klappt auf, erneuter Klick wählt ab/zu.
  Übersicht mit Beschreibung und Aktionen; Plus und Cmd/Ctrl+N mit denselben
  Regeln. Weitere Haupttypen bleiben erreichbar, explizite Zielpfade/-auswahl in
  Anlegedialogen und Import. [Umsetzung und Abnahme](ANLEGEN_UMSETZUNGSPLAN.md).

- Flutter-Grundlayout mit Symbolleiste, Explorer, Editor und Suche.
- Dateien/Notizen bearbeiten, importieren, verschieben und verknüpfen; unterstützte
  Vorschauen, Archiv, Papierkorb und Textverlauf gemäß README.md.
- GTD-Listen mit projektweisen nächsten Aktionen und getrenntem Aufgabenabschluss.
- Mehrere Kontexte, optionale Minuten und Energie; Chips und kombinierbare Filter.
- Kontextverwaltung, wählbare Arbeitsbereiche, vollständiges Kopieren und gespeicherte Ansicht.
- Automatischer rekursiver Inbox-Eingang bei laufender App, persistentes Journal,
  geprüfte Zwischenkopien und externe Originalaufbewahrung; siehe
  [Umsetzung](EINGANGSORDNER_UMSETZUNGSPLAN.md).
- Schema 6: vollständige Rückfallkopie vor Migrationen aus 1–5, Root-Sperre und
  Ablehnung unbekannter neuerer Datenformate.
- Lokaler MCP-Server im Repository: sofortige Zugriffsauswahl und automatische
  sichere Verbindungsablage auf macOS/Linux, acht Lese- und
  elf Schreib-Werkzeuge über die laufende App. Revisions-/Hashschutz,
  Schutz offener Editorentwürfe und Widerruf beim Rootwechsel.

[Bedienung](../README.md) · [MCP-Einrichtung](MCP.md) ·
[MCP-Architekturplan](MCP_PLAN.md) · [MCP-Umsetzung und Prüfungen](MCP_UMSETZUNG.md) ·
[Arbeitsbereiche](ARBEITSBEREICHE.md) · [Aufgabenangaben](GTD_AUSBAU.md).

## Prüfstand

- Startzeit 0.9.1: Plan-/Codereviews durch Subagenten, Analyse ohne Befund,
  133 Flutter-Tests erfolgreich. 15 neue Index- und drei Suchdialogtests prüfen
  Cacheübernahme, Konkurrenz, Fehler, Lebensdauer und unabhängige Rückholung.
  Nativer Start-/Live-Suchtest mit echtem PDF-Extractor erfolgreich; beim
  Wiederöffnen keine erneute Extraktion. Alle zwölf bisherigen Linux-Abläufe
  erfolgreich, ein macOS-spezifischer Test übersprungen. Linux-Release lokal
  installiert, alle 25 Paketdateien gegen den Build geprüft; vollständige Daten-
  und App-Rückfallkopien erhalten. Installierte App isoliert mit temporären XDG-
  Verzeichnissen gestartet. Keine Nutzerdaten als Testumgebung; neue macOS-
  Abnahme offen. [Details](STARTZEIT_UMSETZUNGSPLAN.md).

- Dateifläche/Tabs 0.9.0: Analyse ohne Befund, alle 115 Flutter-Tests erfolgreich.
  Vier neue Modell-/Resize-/Übernahmetests mit unabhängiger Rückholung von Texten,
  Anhängen, Links, Papierkorb und Textversionen. Fünf neue native Linux-Abläufe
  erfolgreich, einschließlich Entwurferhalt über Resize/Fokus, Abbruch/Speichern,
  30 Tabs, Formatvorschauen, Wiederöffnung und Schutz unbekannter Sitzungsformate.
  Alle zwölf bisherigen Linux-Bedienabläufe sowie zehn Anlage-/Zielauswahltests
  erfolgreich; ein macOS-spezifischer Test auf Linux übersprungen.
  Linux-Release 0.9.0 lokal installiert, alle 24 Paketdateien per SHA-256 gegen
  den Build geprüft, vorige App als Rückfallkopie erhalten. Tatsächlich installierte
  Release-App mit vollständig getrennten temporären XDG-Verzeichnissen gestartet:
  Schema 6, Sitzung Format 2, fehlerfreier Start. Alle Testdaten synthetisch und
  temporär; kein regulärer Nutzerbestand als Testumgebung. Neue native macOS-
  Abnahme einschließlich Cmd+W-Menüweiterleitung weiterhin offen.

- MCP 0.8.1 / Server 0.3.0: vollständige Flutter-Suite mit 111 Tests erfolgreich,
  davon elf neue isolierte Erweiterungstests; sieben Node-Tests erfolgreich.
  Echter stdio-Client prüft alle 19 Werkzeuge gegen Repository und native Linux-
  Testapp, einschließlich Antwortbudgets, Pagination und Unicode. Unabhängige
  Entwurfs-/Codeprüfung ohne verbleibende Blocker, Skill mit vier synthetischen
  Abläufen geprüft. Unabhängige Sicherungsrückholung und Wiederöffnen erfolgreich.
  Alle App-Testdaten temporär; kein Nutzerbestand als Testumgebung.
  Analyse ohne Befund; Linux-Release und MCP lokal mit vollständigen Rückfallkopien
  installiert, Builddateien per SHA-256 geprüft. Installierter MCP-Server erneut
  nativ mit allen 19 Werkzeugen geprüft; Skill-Verweis gültig.
  Neuer macOS-Nativnachweis weiterhin offen.

- Eingangsordner 0.8.0: Analyse ohne Befund, 100 Flutter-Tests einschließlich
  18 neuer Import-/Wiederanlauf-/Integritätstests. Nativer Linux-Test für neue
  Bedienung, sichere Dateioperationen und rekursive Übernahme erfolgreich.
  Zwölf bisherige native Linux-Bedienabläufe erfolgreich, ein macOS-spezifischer
  Test übersprungen. Neue native macOS-Sandbox-Prüfung offen.
  Alle Testquellen und Arbeitsbereiche temporär, keine regulären Nutzdaten geöffnet.
  Linux-Release 0.8.0 lokal installiert, alle 24 Paketdateien geprüft; bisherige
  App als Rückfallkopie erhalten. Nutzer hat die Funktion am 26. Oktober 2026
  im Praxistest bestätigt und Commit/Push freigegeben.

- Auswahl/Übersicht/Anlegen 0.7.3: Analyse ohne Befund und alle 82 Flutter-Tests
  erfolgreich. Zehn neue native Linux-Abläufe sowie alle zwölf auf Linux
  anwendbaren bisherigen Bedienabläufe erfolgreich. Der macOS-spezifische
  Ordnerrechte-/Bookmark-Test wird auf Linux ausdrücklich übersprungen;
  erneute native macOS-Prüfung offen. Projektübersicht visuell geprüft.
  Ausschließlich temporäre synthetische Arbeitsbereiche. Details im
  [Anlege-Umsetzungsplan](ANLEGEN_UMSETZUNGSPLAN.md). Linux-Release gebaut und
  lokal als 0.7.3 installiert, alle kopierten Dateien gegen den Build geprüft.
  Rückfallkopie der vorherigen App vorhanden; laufende App nicht beendet.

- Projektanlage 0.7.2 gemäß [Plan](MCP_PROJEKTE_PLAN.md): `create_project`
  in App, MCP und Skill. Ergebnis/Termin Pflicht, feste oberste Projektebene.
  Analyse ohne Befund, alle 82 Flutter-Tests und sechs Node-Tests erfolgreich.
  Native Linux-Testapp mit echtem stdio-Client: alle 14 Werkzeuge erfolgreich,
  einschließlich Projektanlage und zugeordneter Aufgaben. Daten ausschließlich
  in temporären Testroots. Linux-Release gebaut, App 0.7.2 und MCP 0.2.0 lokal
  mit Rückfallkopien installiert; installierten Server erneut mit allen 14
  Werkzeugen geprüft. Skill-Verweis aktuell, Format validiert.
  Neuer nativer macOS-Test weiterhin offen.

- MCP 0.7.1: Analyse und alle 80 Flutter-Tests sowie sechs Node-Tests erfolgreich.
  Nativer Linux-Test prüft automatische Ablage, Zugriffsauswahl, 0700/0600,
  Symlink-/Dateischutz, Widerruf und alle 13 Werkzeuge über automatische
  Servererkennung. Nutzdaten ausschließlich in temporären Testroots.
  Auch der tatsächlich installierte MCP-Server mit allen 13 Werkzeugen geprüft.
  Neuer nativer macOS-Sandbox-Test steht noch aus.

- Linux x64 auf Omarchy: Release-Build mit Flutter 3.47.8 / Dart 3.13.7
  erfolgreich; alle 80 Flutter-Tests erfolgreich. SDK-gebundene Pakete im Lockfile
  angepasst, PDF-Engine auf 0.4.7 für die aktuelle Dart-Kompilierung aktualisiert.
  Nativer Linux-Integrationstest für Projektinhalte, stabile Links, Aufgabenwechsel,
  Speichern und Wiederöffnen erfolgreich, ausschließlich mit temporären Testdaten.
  Build-Ergebnis: `build/linux/x64/release/bundle/`; vollständige native
  Linux-Bedienprüfung weiterhin offen.
- Codeprüfung ohne Befund; alle 80 Flutter-Tests erfolgreich,
  einschließlich alter Schemas, unabhängiger Sicherungsrückholung, UUIDs,
  Texten, Dateien, Links, Status, Archiv, Papierkorb, Textversionen und Einstellungen.
- Bisheriger macOS-Prüfstand aus 0.7.0: echte stdio-Verbindung mit SDK-Client und temporärem Repository; alle
  13 Werkzeuge zusätzlich über eine signierte native macOS-Release-Testapp geprüft.
  Externer Root über nativen Ordnerdialog ausgewählt, unsichere Verbindungsdateien
  abgelehnt. Details im [MCP-Prüfstand](MCP_UMSETZUNG.md).
- Alle 13 bisherigen nativen macOS-Bedienabläufe für 0.7.0 geprüft.
- Architektur-/Sicherheitsreviews für den bisherigen Umfang aus 0.7.0 ohne Blocker.
- Alle Entwicklungs- und Testläufe verwenden getrennte synthetische Daten.
  Kein regulärer Nutzerarbeitsbereich wurde für diese Umsetzung geöffnet.

## Weitere offene Arbeit

- Splits wie C, Tabgruppen und mehrere gleichzeitig ungespeicherte Editoren erst
  später bei Bedarf. Kein Live Preview oder Autosave durch die Tab-Umsetzung.
- Regelmäßige automatische Sicherungen, geführte Auswahl älterer Sicherungsstände,
  allgemeiner Wiederanlauf für Datei-/Datenbankänderungen und App-Updater.
- Wochenrückblick, Projektprüfung, Wiederholungen und externe Dateiverweise sind
  weitere Vorschläge und nicht Teil dieser Umsetzung.
- Autosave, Live Preview, Mehrfachauswahl und Rückgängig bleiben offen.
- Vollständige Linux-Bedienprüfung, Android und Cloud-Sync bleiben offen.
- MCP-Erweiterungen: vorhandene Inhalte in Projekte umwandeln, Verschieben, Dateiimport,
  Archiv-/Papierkorbaktionen, dauerhafte oder eingeschränkte Teilfreigaben.

[Sicherung](SICHERUNG.md) · [Architektur](ARCHITEKTUR.md) ·
[UI-Anforderungen](UI_UMZUG.md).
