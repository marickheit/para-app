# Automatische lokale MCP-Verbindung

Aktueller Vertrag in App 0.10.0/MCP 0.3.0; umgesetzt seit App 0.7.1.
Die Ergebnisnachweise unten gelten für 0.7.1. Aktuelle Einrichtung und alle
19 Werkzeuge: [MCP.md](MCP.md).

## Implementierter Vertrag

1. **Bedienung:** Eine Auswahl „Aus / Nur lesen / Lesen und Schreiben“ aktiviert
   beziehungsweise widerruft den Zugriff unmittelbar. Kein Ordnerdialog und kein
   zusätzlicher Ablagebutton. Zustand und notwendiges Neuverbinden klar anzeigen.
2. **Plattformen:** Linux verwendet `$XDG_STATE_HOME/para-mcp` (sonst
   `~/.local/state/para-mcp`). Die sandboxed macOS-App verwendet
   `~/Library/Containers/dev.para.paraWorkspace/Data/Library/Application Support/para-mcp`.
   Die App verwaltet den Ordner selbst; geheime Dateien atomar mit 0600 schreiben,
   Symlinks, fremde Eigentümer und unsichere bestehende Dateien ablehnen.
3. **Server:** Ohne Pfadargument denselben Plattformstandard ermitteln. Explizite
   bisherige Dateipfade weiter unterstützen. Verbindungsformat 1, Inhaltsformat aktuell Schema 6,
   Bundle-Kennung, Nutzdatenpfade und Berechtigungspräferenz `mcp.v1` erhalten.
   Alte Freigaben werden nicht automatisch aktiviert oder übernommen.
4. **Lebenszyklus:** Beenden, Rootwechsel und Widerruf schließen den Zugang.
   Neustarts bleiben ausgeschaltet. Kein stiller Wechsel eines bereits
   verbundenen MCP-Prozesses zu einer anderen Freigabe.
5. **Tests vor Installation:** Flutter-Analyse und vollständige Testsuite,
   Widgettests der neuen Auswahl, Pfadtests für Linux/macOS, native Dateischutz-
   und MCP-Integration unter Linux mit allen aktuell 19 Werkzeugen. Sämtliche Testdaten
   und Verbindungsdateien ausschließlich in temporären Ordnern. macOS-Nativtest
   auf diesem Rechner nicht möglich und als offene Prüfung kennzeichnen.
6. **Installation:** Linux-Release bauen, bisherigen installierten App-/Serverstand
   als Rückfallkopie erhalten, beide Installationen ersetzen und Codex auf
   automatische Pfadermittlung umstellen. Keine Inhaltsmigration nötig.
   Eine bereits laufende App nicht mit offenen Entwürfen zwangsweise beenden.
7. **Dokumentation:** Bedienung, Plattformpfade, Kompatibilität, Sicherungsgrenzen
   und tatsächliche Prüfergebnisse im selben Arbeitsgang aktualisieren.

## Versionsgebundene Ergebnisse 0.7.1 und Plattformgrenzen

- App 0.7.1+8 und MCP 0.1.1 umgesetzt; Linux-Release gebaut und die lokalen
  Benutzerinstallationen einschließlich Codex-Konfiguration aktualisiert.
  Bisherige Installationen als `.previous-0.7.0` beziehungsweise `.previous-0.1.0`
  neben der jeweiligen App erhalten. Laufende alte App bleibt bis zum regulären
  Neustart geöffnet.
- Codeanalyse, 80 Flutter-Tests, sechs Node-Tests und nativer Linux-Test mit
  automatischer Erkennung und allen 13 Werkzeugen erfolgreich. Alte explizite
  Pfade, Datenmigrationen und unabhängige Sicherungsrückholung weiterhin geprüft.
- macOS-Pfadlogik geprüft; nativer Sandbox-Build und Bedienprüfung der neuen
  automatischen Ablage auf macOS bleiben offen. Dazu denselben nativen Test auf
  einem Mac mit externem MCP-Treiber ausführen; siehe [MCP-Prüfung](MCP.md).
- Keine Datenformatänderung oder Inhaltsmigration. Zugriffe nach App-Neustart und
  Rootwechsel bleiben aus. Nach erneuter Freigabe den MCP-Client neu verbinden.
