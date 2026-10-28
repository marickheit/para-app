# Arbeitsstand

Stand: 28. Oktober 2026 · Version 0.11.0+19.

Aktueller Umfang und Prüfnachweise; Fachdetails stehen in den verlinkten Verträgen.
Die [Dokumentationsübersicht](README.md) ordnet aktuelle Anleitungen,
versionsgebundene Abnahmen und unverbindliche Entwürfe ein.

## Implementiert

- **Explorer:** Name/Zeile wählt aktive Container aus oder ab. Nur der separate
  Pfeil ändert ihren Baumzustand; das Kopfzeilensymbol kann alle Zweige umschalten.
  Archiv-/Papierkorbzeilen öffnen schreibgeschützte Inhalte, ihre Pfeile ändern
  nur den Baum. Pfeilklicks erhalten Auswahl und offene Entwürfe. Suche, Datei-/
  Tabwechsel, Links und Neuanlage können den Zielpfad automatisch sichtbar machen.
  [Auswahl, Übersichten und Anlageziele](ANLEGEN_UMSETZUNGSPLAN.md).
- **Dateifläche:** Vorschau-/dauerhafte Dateitabs über UUIDs, kompakter Kopf,
  zentrierte Textlesebreite/wählbare volle Breite, ziehbarer Explorer und Fokusmodus. Explizites
  Speichern und Speicherschutz; gespeicherte Sitzung Format 2 mit gesicherter
  Übernahme von Format 1. [Bedienvertrag](DATEI_TABS_UMSETZUNGSPLAN.md).
- **Markdown-Editor:** Live als Standard, Quelltext und Lesen mit bedienbaren
  Checkboxen; Return rendert den abgeschlossenen Absatz. 16 Pixel Text, 1,55-fache
  Zeilenhöhe, 16 Pixel Blockabstand (innerhalb von Listen 4 Pixel) und deckende Fläche. Zentrierte 680-Pixel-Lesespalte;
  gespeicherte Breitenwahl erhalten. Gültige YAML-Kopfdaten kompakt und verlustfrei
  aufklappbar/bearbeitbar. Tabellen in Inhaltsbreite mit begrenzten
  Spalten, Textumbruch und horizontalem Scrollen. Gemeinsame kompakte
  Tab-/Aktionszeile, Aa-Menü, Tabellenraster und direkte Zell-/Strukturänderungen,
  textbezogenes Undo/Redo. Explizites Speichern, MCP-/Konflikt-/Wechselschutz und
  gesperrte Archive/Papierkörbe bleiben. Keine Formatmigration.
  [Bedienvertrag, Reviews und Prüfstand](MARKDOWN_EDITOR_UMSETZUNGSPLAN.md).
- **Beschreibungen:** Projekte, Bereiche, Ressourcensammlungen und Ordner
  verwenden denselben Markdown-Editor wie Notizen. Strukturierte Felder bleiben
  separat; Übersichten rendern schreibgeschützt mit bedienbaren Links.
  Kein Datenformatwechsel. [Umfang/Prüfungen](MARKDOWN_BESCHREIBUNGEN_PLAN.md).
- **Suche/Start:** Vorhandenen Index sofort verwenden, geänderte Dateien und neue
  PDFs im Hintergrund auswerten. Unveränderte Dateien nicht erneut auslesen;
  offene Suche erhält neue Treffer und Status. Abgeleiteter Suchcache Format 1.
  [Ablauf und Grenzen](STARTZEIT_UMSETZUNGSPLAN.md).
- **Inhalte:** Markdown/TXT bearbeiten, PDF/Bilder/SVG/CSV anzeigen, importieren,
  verschieben, umbenennen und stabil verknüpfen. Archiv mit Herkunft,
  Papierkorb und Textversionen. [Bedienung/Formatgrenzen](../README.md).
- **Aufgaben:** Getrennte Arbeits-/Abschlusszustände, projektweise nächste Aktionen,
  mehrere Kontext-/Zeit-/Energiechips und Filter. Kontexte verwalten; bestätigte
  Anlageziele und Typauswahl über Plus und Cmd/Ctrl+N.
  [Aufgabenangaben und weitere Vorschläge](GTD_AUSBAU.md).
- **Arbeitsbereiche/Sicherung:** Root öffnen, neu anlegen oder vollständig kopieren;
  Einstellungen/Sitzung im Root. Schema 6, vollständige Rückfallkopie vor Migration
  aus 1–5, Root-Sperre und Ablehnung neuerer Formate. Sicherungsformat 3.
  [Arbeitsbereiche](ARBEITSBEREICHE.md), [Rückholung](SICHERUNG.md).
- **Eingangsordner:** Eine lokale Quelle je Root; rekursive bytegetreue Übernahme,
  Ruhephase, Journal und geprüfte Zwischenkopien. Originale im externen
  Rückholbereich ohne automatische Löschung. Keine Aktivierung fremder Quellen
  nach Kopie/Rückholung. [Umfang/Prüfungen](EINGANGSORDNER_UMSETZUNGSPLAN.md).
- **MCP:** Lokale stdio-Anbindung über die laufende App, automatische private
  Verbindungsablage auf macOS/Linux, Freigabe und Widerruf. Acht Lese-/elf
  Schreibwerkzeuge, kompakte Antworten und Fortsetzung, Revision-/Hash-/Editorschutz.
  MCP-Paket 0.3.0, API 2, Bridge 1. [Vertrag](MCP.md).

## Prüfstand

- **Markdown-Beschreibungen 0.11.0+19 · Linux:** Analyse ohne Befund, alle
  184 Flutter-Tests und sieben MCP-Tests erfolgreich. Neuer nativer Ablauf für
  alle vier Containertypen sowie zehn bestehende Anlage-/Auswahlfälle erfolgreich.
  Breite/schmale Darstellung visuell geprüft. Linux-Release installiert,
  24 Paketdateien geprüft und installierten Build isoliert mit Schema 6 gestartet;
  Startverweis unverändert. Native macOS-Abnahme offen.
  [Plan und Nachweise](MARKDOWN_BESCHREIBUNGEN_PLAN.md).

- **Listenabstand 0.10.2+18 · Linux:** 4 Pixel zwischen Listenpunkten in Live/Lesen,
  Abschnittsabstände unverändert. Analyse ohne Befund, alle 179 Flutter-Tests
  und beide nativen Linux-Editorfälle erfolgreich; kompakte und mehrzeilige Listen
  visuell geprüft. Release installiert, 24 Paketdateien verglichen und installierten
  Build isoliert gestartet. [Aktuelle Nachweise](EDITOR_LESBILD_PLAN.md).

- **Lesebild 0.10.1+17 · Linux:** Analyse ohne Befund, alle 177 Flutter-Tests
  und sieben native Linuxfälle erfolgreich. Rezeptdarstellung in Dunkel/Hell und
  schmal geprüft; Quellerhalt, Breitenwahl und bisherige Editor-/Dateitababläufe
  erfolgreich. Linux-Release installiert, 24 Paketdateien per SHA-256 geprüft,
  installierter Build mit temporärem Root gestartet; Startverweis unverändert.
  [Plan und Nachweise](EDITOR_LESBILD_PLAN.md).

- **Editor 0.10.0:** Analyse ohne Befund, zuletzt alle 170 Flutter-Tests erfolgreich.
  28 native Linuxfälle einschließlich neuer Editorbedienung und bestehender
  Datei-/Anlage-/Workspaceabläufe erfolgreich; ein macOS-Fall übersprungen.
  Inhaltsbreite, Spaltenbegrenzung, Umbruch und Scrollen in Live/Lesen geprüft;
  nativer Linux-Editortest mit kompakter Tabellenbreite erneut erfolgreich.
  Sieben MCP-Tests bei der vorherigen Abstandskorrektur erfolgreich. Linux-Release neu installiert, 25
  Paketdateien geprüft und installierten Build mit temporärem Root gestartet.
  Neue Darstellung beim nächsten App-Start verfügbar. [Reviews, Nachweise und Installationsgrenzen](MARKDOWN_EDITOR_UMSETZUNGSPLAN.md).
  Die folgenden Nachweise behalten ihre tatsächliche Versionsbindung; eine neue
  macOS-Editorabnahme steht aus.
- **0.9.2:** Analyse ohne Befund, alle 133 Flutter-Tests erfolgreich. Zehn native
  Auswahl-/Anlageabläufe prüfen zusätzlich getrennte Name-/Pfeilklicks für
  Projekt, Bereich, Ressource, Ordner, Archiv und Papierkorb, Entwurferhalt sowie
  Wiederöffnung mit geschlossenem Elternzweig und unverändertem Anlageziel.
  Alle zwölf bisherigen Linux-Bedienabläufe nach angepasster Pfeilbedienung
  erfolgreich; ein macOS-spezifischer Test auf Linux übersprungen.
- **Installation 0.9.2+15:** Linux-Release gebaut, lokal installiert, alle 24
  Paketdateien per SHA-256 gegen den Build geprüft. Vollständige Daten-/App-
  Rückfallkopien erhalten. Installierte App isoliert mit temporären XDG-
  Verzeichnissen gestartet, danach zur normalen Nutzung wieder geöffnet.
- **Startindex seit 0.9.1:** 15 Index-/drei Suchdialogtests sind in der aktuellen
  Suite enthalten. Konkurrenz, Cacheverlust, Fehler, Schließen und unabhängige
  Sicherungsrückholung geprüft. Nativer Linux-Nachweis für 0.9.1: Oberfläche und
  Namenssuche während blockierter PDF-Extraktion bedienbar, Inhaltstreffer kommen
  live hinzu, unverändertes PDF bei Wiederöffnung nicht erneut ausgelesen.
  [Versionsgebundene Messwerte](STARTZEIT_UMSETZUNGSPLAN.md).
- **Dateitabs seit 0.9.0:** Fünf native Linux-Abläufe für Resize/Fokus, Entwurferhalt,
  Speichern/Abbrechen, 30 Tabs, Vorschauen, Wiederöffnung und Sitzungsübernahme
  nachgewiesen. Diese native Abnahme gilt für 0.9.0; Modell-/Widgetprüfungen bleiben
  Teil der aktuellen Suite. [Nachweise](DATEI_TABS_UMSETZUNGSPLAN.md).
- **MCP-Erweiterung 0.8.1 / Server 0.3.0:** Sieben Node-Tests und echter stdio-Client
  mit allen 19 Werkzeugen gegen Repository/native Linux-Testapp erfolgreich;
  Budgets, Pagination, Unicode, Editor-/Konfliktschutz und unabhängige Rückholung
  geprüft. [Versionsgebundene MCP-Nachweise](MCP_UMSETZUNG.md).
- **Datenkompatibilität:** Tests übernehmen Schemas 1–5, öffnen Sicherungen
  unabhängig und prüfen UUIDs, Texte, Anhänge, Links, Aufgabenstatus, Archivherkunft,
  Papierkorb, Textversionen und Einstellungen. Eingangsjournal/Quellenbindung
  einschließlich unterbrochener Übergänge geprüft.
- **Plattformgrenze:** Bisherige macOS-Abnahme aus 0.7.0 mit 13 Bedienabläufen und
  dem damaligen MCP-Kern ist kein Nachweis neuerer Änderungen. Native macOS-
  Nachprüfung von automatischer MCP-Ablage, Eingang, Tabs und Pfeilbedienung offen.
  Android-Build und plattformweite Linux-Vollabnahme über die geprüften Abläufe
  hinaus ebenfalls offen.

Alle automatisierten/manuellen Entwicklungsprüfungen verwenden getrennte
synthetische Arbeitsbereiche. Reguläre Nutzerbestände dienen nicht als Testumgebung.

## Weitere offene Arbeit

- Regelmäßige automatische Sicherungen, geführte Auswahl älterer Sicherungsstände,
  allgemeines Wiederanlaufjournal und App-Updater.
- Android, Cloud-Sync, Konfliktauflösung zwischen Geräten und externe Dateiverweise.
- Splits wie C, Tabgruppen und mehrere gleichzeitig ungespeicherte Editoren
  zurückgestellt. Autosave, Entwurfsrettung, Mehrfachauswahl,
  allgemeines Rückgängig für Ablageaktionen und zusätzliche Textformate sind
  unbestätigte Vorschläge; Markdown-Live und Text-Undo gehören zum Editor 0.10.0.
- Projektprüfung, Wochenrückblick und Wiederholungen sind unbestätigte GTD-Vorschläge.
- MCP: vorhandene Inhalte in Projekte umwandeln, Verschieben, Dateiimport,
  Archiv-/Papierkorbaktionen sowie dauerhafte/ordnerbezogene Freigaben nicht umgesetzt.

[Produktstand](../PLANUNG.md) · [Bedienung](../README.md) ·
[Architektur](ARCHITEKTUR.md) · [Sicherung](SICHERUNG.md)
