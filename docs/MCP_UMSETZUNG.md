# MCP – Umsetzung und Prüfstand

Stand: 26. Oktober 2026 · App 0.8.1+12 · MCP-Paket 0.3.0.
Beauftragter Umfang gemäß [Architekturplan](MCP_PLAN.md),
[Einrichtung und Grenzen](MCP.md).

## Umgesetzt

1. [x] Authentifizierte lokale Bridge, sichere Verbindungsdatei und macOS-Release-Berechtigung.
2. [x] Konsistente Repository-Snapshots und Schutz sämtlicher Editorentwürfe.
3. [x] Acht Lese-Werkzeuge mit Filtern, Suche, Verweisen und Seitencursor.
4. [x] Elf Schreib-Werkzeuge mit Revision/Hash und Wiederholungsschutz.
5. [x] Einstellungen zur Freigabe, Widerruf und eigenständiges stdio-Paket in `mcp/`.
6. [x] Vertrags-, Sicherheits-, Konkurrenz-, Rückholungs- und echte stdio-Prüfungen.
7. [x] Signierte macOS-Release-Testapp, Bedienungsdoku und unabhängige Code-Reviews.

Freigabe gilt für die aktuelle App-Öffnung; keine Bestätigung jeder Einzelaktion.
Die Berechtigungspräferenz im Root aktiviert nach Neustart/Kopie keine Verbindung.
Das Inhaltsformat bleibt Schema 6. Kein neuer Datenordner und keine Migration
für MCP. Der MCP-Prozess öffnet selbst keine Datenbank oder Nutzdateien.

## Prüfnachweise

- Erweiterung 0.8.1: elf neue isolierte Diensttests; vollständige Flutter-Suite
  mit 111 Tests und sieben Node-Tests erfolgreich. Echter stdio-Client gegen
  temporäres Repository und native Linux-Testapp prüft alle 19 Werkzeuge,
  neue Anlage-/Änderungspfade, Pagination, JSON-Budget und Unicode.
  Binärdateien bleiben beim Umbenennen bytegleich; Konflikte, Editorzustand,
  Mehrdeutigkeit, ungültige Surrogate und Größenlimits überschreiben nichts.
  Neue Inhalte nach unabhängiger Sicherungsrückholung und Wiederöffnen geprüft.
  Unabhängiges Entwurfs-/Code-Nachreview ohne Blocker; Skillformat und vier
  synthetische Nutzerabläufe geprüft. [Vertrag](MCP_ERWEITERUNG_PLAN.md).
  Analyse ohne Befund, Linux-Release/MCP lokal mit vollständigen Rückfallkopien
  aktualisiert und Builddateien per SHA-256 geprüft. Installierter Server nochmals
  nativ mit allen 19 Werkzeugen erfolgreich geprüft; Skill-Verweis gültig.

- Projektanlage 0.7.2: Pflichtangaben und Kalenderdaten an App/MCP-Grenzen,
  Nur-Lesen-Schutz, parallele doppelte Requests, Text/Links, Projektaufgaben
  und Wiederöffnen geprüft. Analyse ohne Befund, alle 82 Flutter-Tests und sechs
  Node-Tests erfolgreich. Echter stdio-Client gegen native Linux-Testapp prüft
  alle 14 Werkzeuge einschließlich Projektanlage; ausschließlich temporäre Daten.
  Linux-Release gebaut und lokal installiert, einschließlich MCP 0.2.0;
  installierten Server erneut nativ mit allen 14 Werkzeugen geprüft.
  Skill-Format validiert und bestehender lokaler Repository-Verweis geprüft.

- Aktuelle Erweiterung: automatische Ablage auf macOS/Linux, sofortige Auswahl
  Aus/Lesen/Schreiben, sichere native Linux-Dateierzeugung und Serverstart ohne
  Pfadargument. Analyse, 80 Flutter-Tests und sechs Node-Tests erfolgreich.
- Nativer Linux-Test: UI-Zustände, Widerruf, 0700/0600, unsichere Datei/Symlink
  und alle 13 Werkzeuge über automatische Servererkennung erfolgreich.
  Abschließend denselben Ablauf mit dem installierten MCP-Server erfolgreich geprüft.
- macOS-Pfaderkennung ist automatisiert geprüft; die neue native Ordnererzeugung
  im macOS-Sandbox-Build ist auf diesem Linux-Rechner nicht prüfbar.
  Die folgenden macOS-Nachweise gelten für den bisherigen Umfang aus 0.7.0.

- Flutter-Codeprüfung ohne Befund; 78 Tests der vollständigen Suite einschließlich alter
  Schemas 1–4 und unabhängiger Sicherungsrückholung erfolgreich.
- MCP-Paket: Installation aus Lockdatei, TypeScript-Build und drei Node-Tests
  erfolgreich; Paketprüfung ohne gemeldete Sicherheitslücke.
- Echter SDK-Client über stdio → HTTP-Bridge → echtes temporäres Repository:
  alle 13 Werkzeuge, Textversionen und identische Wiederholung geprüft.
- Native, ad hoc signierte macOS-Release-Testapp mit Sandbox: alle 13 Werkzeuge
  über externen Node-Client erfolgreich. Leerer externer Testroot über echten
  Ordnerdialog ausgewählt; Daten anschließend überprüft und aufgeräumt.
- Nativer Verbindungsdateischutz: unsichere Bestandsdatei und auch ein Symlink
  auf ein fehlendes Ziel abgelehnt. Sichere Datei erzeugt und nach Widerruf entfernt.
- Negativfälle: Token, Origin, Host, Öffnungskennung, externe/umgeleitete
  Endpunkte, Dateirechte/Symlink, unzulässiger Ablageort, Pfadversuche,
  unbekannte Felder/Typen und Textlimit.
- Archiv-/Papierkorbinhalte bleiben auch bei Suche und Rückverweisen verborgen;
  geerbtes Archiv wird berücksichtigt. Suchrelevanz bleibt bei Pagination erhalten.
- Revision innerhalb derselben Warteschlange geprüft; konkurrierende UI-Änderung
  verwirft den MCP-Schreibversuch. Parallele identische Request-IDs erzeugen nur
  eine Änderung. Veraltete Seitencursor werden abgelehnt.
- Widgetprüfungen: Textentwurf, reine Aufgabenangaben, Speichern mit verzögerter
  UI-Revision und verzögertes Laden
  blockieren MCP-Änderungen. Gezielte Prüfung des Ausschaltens während eines
  verzögerten Verbindungsaufbaus sowie nach Repository-Schließung.
- Rootwechsel widerruft den bisherigen Zugang; unabhängige Sicherung erhält die
  Präferenz und Inhaltstexte, öffnet aber keine Verbindung und enthält keine
  Verbindungsdatei.
- Architektur- und Sicherheitsreview durch zwei Subagenten nach Korrekturen ohne
  verbleibende blockierende Befunde.

- Bestehende native macOS-Bedienprüfungen: zwölf Abläufe erfolgreich; der
  zusätzlich korrigierte Speicher-/Suchablauf gezielt erneut erfolgreich geprüft.
  Damit sind alle 13 bisherigen Abläufe abgedeckt.

## Grenzen / nicht Teil dieses Umfangs

Kein entfernter/cloudbasierter MCP-Zugang, keine dauerhafte Freigabe über
App-Neustarts, keine Einzelordnerrechte und keine garantierte dauerhafte
Genau-einmal-Ausführung. Nach Abbruch einer übermittelten Änderung kann das
Ergebnis unbekannt sein. Keine automatische Wiederholung oder Rollback-Zusage.
Erneute native macOS-Prüfung der automatischen Ablage, Android-Integration
und weitere MCP-Operationen bleiben offen.
