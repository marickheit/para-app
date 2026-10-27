# Startzeit und inkrementeller Suchindex

Aktueller Vertrag in 0.10.0, umgesetzt seit 0.9.1. Die Nachweise unten nennen den
jeweiligen Prüfstand; aktuelle Version und Abnahme im [Arbeitsstand](UMSETZUNGSPLAN.md).

## Ziel und Umsetzung

Den vorhandenen Suchtext und Linkindex sofort verwenden; Änderungen
nach dem Öffnen im Hintergrund abgleichen. Das Öffnen wartet nicht mehr auf
PDF-Textextraktion. Unveränderte Dateien werden nicht erneut ausgelesen.

- Abgeleiteter Cache Format 1 in `workspace_settings`, getrennt je Inhalts-UUID.
  Signatur: relativer Pfad, Größe, Änderungs-/Metadatenzeit, Indexerversion und
  PDF-Unterstützung. Kein neues maßgebliches Datenformat; Schema 6 und
  Sicherungsformat 3 bleiben bestehen. Alte Bestände ohne Cache bleiben lesbar.
- Extraktion außerhalb der exklusiven Schreibwarteschlange. Pro Inhalt kurzer,
  transaktionaler Abschluss für Suchtext, Links und Signatur. Vor Abschluss erneut
  Revision, Pfad und Dateisignatur prüfen; veraltete Ergebnisse verwerfen.
- Alte Treffer/Links bis zum erfolgreichen Ersatz erhalten. Extraktionsfehler
  überschreiben keinen bestehenden Index und werden beim nächsten Öffnen erneut
  versucht. Kein vollständiges Löschen des Linkindex beim Start.
- Notiz-/Textspeichern und Textimport bleiben unmittelbar suchbar; PDF-Importe
  werden im Hintergrund indexiert. Cachemarken entstehen nach geprüftem Abgleich.
  Abgleich läuft auch für Archiv und Papierkorb. Schließen stoppt
  weitere Arbeit und verhindert Abschlüsse nach Datenbankschluss.
- Suchdialog zeigt laufende Aktualisierung und Fehlerhinweis und empfängt neue
  Treffer ohne erneutes Öffnen. Namenssuche bleibt sofort verfügbar.
- Änderungen außerhalb der App werden beim nächsten Öffnen erkannt. Metadaten-
  signaturen sind kein Inhalts-Hash; Manipulationen mit vollständig identischen
  Dateimetadaten werden damit nicht garantiert erkannt.

## Prüfvertrag

Subagent-Review des Plans vor Implementierung und unabhängige Codeprüfung danach.
Temporäre synthetische Arbeitsbereiche: blockierter PDF-Extractor ohne blockiertes
Öffnen/Schreiben, unveränderte Wiederöffnung ohne Extraktion, geänderte Dateien,
Fehler/Wiederholung, Konkurrenz mit Speichern/Umbenennen/Löschen/Schließen,
Cacheverlust/-version, ältere Bestände und unabhängige Sicherungsrückholung mit
UUIDs, Texten, Anhängen, Links, Status, Archiv, Papierkorb und Textversionen.
Analyse, bestehende Flutter-Suite, nativer Linux-Start und Release-Build.
Lokale Installation erst nach Prüfung, mit Rückfallkopie und Paketvergleich;
regulären Nutzerbestand nicht als Testumgebung öffnen.

## Prüfnachweise 0.9.1

Stand: 26. Oktober 2026, Version 0.9.1+14.

- Plan und Implementierung unabhängig durch Subagenten geprüft. Keine offenen
  Blocker nach Prüfung der Cacheübernahme, Schreibserialisierung und Lebensdauer.
- `flutter analyze --no-pub`: ohne Befund. Vollständige Flutter-Suite:
  133 Tests erfolgreich, davon 15 neue Index- und drei neue Suchdialogtests.
  Gezielte Index-Suite nach präzisierter Konkurrenzprüfung: 15 erfolgreich.
- Geprüft: blockierte Extraktion ohne blockierten Start/Schreiben/Import,
  unveränderte Wiederöffnung ohne Extraktion, externe Änderungen, fehlende/
  beschädigte/veraltete Cachemarken, Fehler gegenüber gültigem leerem PDF-Text,
  veraltete Ergebnisse bei Änderung/Umbenennung/Löschen, Schreibserialisierung,
  konkurrierende Cachekorrektur und Schließen vor spätem Extraktionsfehler.
- Ältere Bestände ohne Cache sowie bisherige Schema-1–5-Übernahmen durch die
  Gesamtsuite geprüft. Unabhängiger Sicherungsexport/-rückholung erhält Texte,
  UUIDs, Anhänge, Links, Aufgabenstatus, Archivherkunft, Papierkorb und Textversionen.
- Nativer Linux-Test mit echtem PDF-Extractor erfolgreich: Oberfläche/Namenssuche
  bei angehaltener Extraktion bedienbar, offene Suche erhält anschließend den
  Inhaltstreffer. Wiederöffnung: null erneute Extraktionen. Repository-Öffnen
  im synthetischen Ein-PDF-Test: kalt 6 ms, warm 31 ms; Extraktion/Abschluss 80 ms.
  Das sind keine Messwerte des gesamten App-Starts oder des Nutzerbestands.
- Alle zwölf bisherigen nativen Linux-Bedienabläufe erfolgreich; der
  macOS-spezifische Freigabetest auf Linux übersprungen. Neue macOS-Abnahme offen.
- Linux-Release 0.9.1+14 lokal installiert; alle 25 Paketdateien per SHA-256
  gegen den Build geprüft. Bisherige App und vollständiger Datenbestand als
  Rückfallkopien unter `~/.local/opt/` erhalten; stabile App-Adresse und
  Arbeitsbereichsauswahl unverändert. Keine Datenmigration erforderlich.
- Tatsächlich installierte App mit vollständig getrennten temporären XDG-
  Verzeichnissen gestartet: sichtbares Fenster, Schema 6 und leerer Testbestand,
  ohne Laufzeitfehler. Danach die aktualisierte App zur normalen Nutzung erneut
  geöffnet. Keine regulären Nutzerdaten als Testumgebung verwendet.
