# Projektdokumentation

Die aktuellen Produktfunktionen stehen in [PLANUNG.md](../PLANUNG.md), die
Bedienung in [README.md](../README.md) und Abnahme/offene Arbeit im
[Arbeitsstand](UMSETZUNGSPLAN.md). Die [Projektregeln](../AGENTS.md) verpflichten
dazu, alle betroffenen Dokumente bei jeder Änderung im selben Arbeitsgang
anzugleichen und Verweise zu prüfen.

## Aktuelle Anleitungen und Verträge

| Thema | Zuständige Dokumente |
| --- | --- |
| Produkt, Bedienung und Entwicklung | [Produktstand](../PLANUNG.md), [Bedienung/Entwicklungsbefehle](../README.md), [Projektregeln](../AGENTS.md) |
| Architektur, Daten und Kompatibilität | [Architektur](ARCHITEKTUR.md), [Arbeitsbereiche](ARBEITSBEREICHE.md), [Sicherung/Rückholung](SICHERUNG.md) |
| Oberfläche und Grenzen | [UI-Anforderungen](UI_UMZUG.md), [kritische Bewertung/Vorschläge](UI_REVIEW.md) |
| Auswahl, Baum und Anlageziele | [Bedienvertrag/Prüfungen](ANLEGEN_UMSETZUNGSPLAN.md), [umgesetzter Umfang/verbleibender Vorschlag](ANLEGEN_VORSCHLAG.md) |
| Markdown-Editor, Tabellen und Text-Undo | [Bedienvertrag, Reviews und Prüfungen](MARKDOWN_EDITOR_UMSETZUNGSPLAN.md), [Lesebild nach Mock 1](EDITOR_LESBILD_PLAN.md) |
| Dateitabs, Fokus, Resize und Sitzung | [Bedienvertrag/Prüfungen](DATEI_TABS_UMSETZUNGSPLAN.md) |
| Start und Suchindex | [Abgleich, Cache und Prüfungen](STARTZEIT_UMSETZUNGSPLAN.md) |
| Aufgabenangaben und unbestätigte GTD-Vorschläge | [GTD-Ausbau](GTD_AUSBAU.md) |
| Automatischer Eingang | [Umfang/Grenzen](EINGANGSORDNER_PLAN.md), [Implementierung/versionsgebundene Abnahme](EINGANGSORDNER_UMSETZUNGSPLAN.md) |
| MCP für Benutzer und Entwickler | [Einrichtung/Werkzeuge](MCP.md), [Architekturvertrag](MCP_PLAN.md), [Serverpaket](../mcp/README.md), [P.A.R.A.-Skill](../skills/para-workspace/SKILL.md) |
| MCP-Fachverträge und Abnahme | [Automatische Verbindung](MCP_AUTOMATISCHE_VERBINDUNG.md), [Projektanlage](MCP_PROJEKTE_PLAN.md), [Ablage/Text/Antwortbudgets](MCP_ERWEITERUNG_PLAN.md), [versionsgebundene Prüfungen](MCP_UMSETZUNG.md) |
| Aktuelle Abnahme und offene Arbeit | [Arbeitsstand](UMSETZUNGSPLAN.md) |

Versionszahlen in Prüfnachweisen bezeichnen den tatsächlich geprüften Stand,
nicht automatisch die aktuelle App-Version. Eine frühere macOS-Abnahme belegt
keine spätere Funktion oder Plattformänderung. Fachverträge beschreiben dagegen
die aktuelle Implementierung; unbestätigte Vorschläge müssen ausdrücklich so
gekennzeichnet bleiben. Bei einem Widerspruch Code und Prüfungen abgleichen,
die Dokumentation korrigieren und keine zusätzliche Funktion daraus ableiten.

## Grundlagen, frühere Abnahmen und Designstudien

| Dokument | Einordnung |
| --- | --- |
| [Flutter-Grundumsetzung](FLUTTER_UMZUG_PLAN.md) | Umgesetzte Grundlage mit aktuellem Verweis auf Bedienung und Plattformprüfungen |
| [Umsetzung 0.6](UMSETZUNG_0_6.md), [Review 0.6](REVIEW_0_6.md) | Versionsgebundene Nachweise für Arbeitsbereiche/Aufgabenangaben; keine aktuelle Vollabnahme |
| [Oberflächenvarianten](BEDIENKONZEPTE.md) | Vergleichsentwürfe, abgegrenzt von der aktuellen Bedienung |
| [Markdown-Editor-Entwurf](mockups/MARKDOWN_EDITOR.md) | Interaktive Designvorschau mit Beispieldaten; maßgeblich sind aktueller Editorvertrag und native Implementierung |
| [Dateitab-Designstudie](mockups/DATEI_TABS.md) | Erläutert HTML-/Bild-Mocks mit synthetischen Inhalten, keine native Funktionsabnahme |
| [UI-Referenz](mockups/para-zieloberflaeche.html), [Dateitab-Varianten](mockups/para-datei-tabs.html) | Unverbindliche interaktive Beispiele; alte Klickabläufe und Beispieldaten sind keine Produktanforderungen |
| [Stand statt Entscheidungsprotokoll](ENTSCHEIDUNGEN.md) | Verweise auf die aktuellen Dokumente; keine laufende Gesprächshistorie |

## Maßgebliche Implementierungsquellen

- App-Version: [pubspec.yaml](../pubspec.yaml) und
  [Workspace-Version](../lib/domain/workspace_format.dart).
- Daten/Übernahme: [Datenbank](../lib/data/database.dart),
  [Root-Prüfung](../lib/data/workspace_storage.dart),
  [Repository](../lib/data/local_workspace_repository.dart),
  [Sitzung](../lib/services/workspace_session.dart).
- Oberfläche/Suche: [Workspace](../lib/ui/workspace_screen.dart),
  [Suchdialog](../lib/ui/workspace_search.dart),
  [Indexdienst](../lib/data/search_index_repository.dart),
  [Formatgrenzen](../lib/services/file_formats.dart),
  [Markdown-Editor](../lib/ui/markdown_editor.dart),
  [Markdown-Quellbereiche](../lib/ui/markdown_source.dart).
- MCP: [Paket/SDK-Versionen](../mcp/package.json),
  [App-Dienst/Werkzeugumfang](../lib/services/mcp_access_service.dart),
  [Vertragsfixture](../test/fixtures/mcp/contract.json).

Prüfzahlen und Installationsnachweise nur nach tatsächlich ausgeführten Prüfungen
ändern. Dokumentationsänderungen allein erfordern keine neue App-Version und
keine erneute Installation.
