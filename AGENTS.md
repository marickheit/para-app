# Zusammenarbeit an diesem Projekt

- Zuerst PLANUNG.md und README.md lesen.
- Aktuell: lokale Flutter-App auf macOS. Der Produktstand steht in PLANUNG.md,
  Bedienung in README.md, nächste Arbeit und Prüfnachweise in docs/UMSETZUNGSPLAN.md.
- Projekte sind konkrete, zeitlich begrenzte Vorhaben mit Ergebnis und
  Fälligkeitsdatum. Projekte haben keinen „Irgendwann / Vielleicht“-Status.
  Diese Liste enthält Ideen und zurückgestellte Aufgaben.
- Dokumentation bei inhaltlichen Änderungen im selben Arbeitsgang aktualisieren.
  Kurz, konkret und auf den aktuellen Stand konzentriert: Funktionen, Bedienung,
  Konsequenzen und Grenzen. Keine laufende Einzelentscheidungs- oder Gesprächshistorie.
- Umgesetzte Funktionen, aktuelle Nutzeranforderungen und offene Vorschläge klar
  unterscheiden. Bestätigte UI: einklappbare Symbolleiste mit benachbartem
  Projekt-/Datei-Explorer, eine gemeinsame Kopfzeile, Suche/Dateiwechsel auf Abruf
  und mehr Platz für den Editor. Papierkorb links unter „Alle Aufgaben“;
  Textversionen über einen kleinen Verlaufsbutton im Dateikopf.
- UI-Mocks enthalten Beispieldaten. Ihre Inhalte oder Klicks sind keine
  verbindlichen Produktentscheidungen.

## Datenkompatibilität und Weiterentwicklung

- Die App wird mit echten Nutzerdaten verwendet. Neue Versionen müssen bestehende
  Arbeitsbereiche und Sicherungen weiterhin lesen oder über eine getestete,
  verlustfreie Migration/Konvertierung übernehmen können. Ein neuer Datenordner
  oder ein Zurücksetzen ist kein Ersatz für eine Migration.
- UUIDs, interne Links, Texte, Anhänge, Ablagestruktur, Aufgabenstatus,
  Archivherkunft, Papierkorb und Textversionen erhalten. Abgeleitete Suchindizes
  dürfen neu aufgebaut werden; maßgebliche Nutzerdaten dürfen dabei nicht verloren gehen.
- Änderungen an Datenbank, Speicherlayout, Link- oder Sicherungsformat brauchen
  eine passende Versionskennung, einen Übernahmepfad und Tests mit repräsentativen
  älteren Daten. Migration und unabhängige Sicherungsrückholung im selben
  Arbeitsgang prüfen und dokumentieren.
- Vor einer Migration echter Nutzerdaten eine vollständige Rückfallkopie erstellen.
  Fehlgeschlagene Konvertierungen oder unbekannte neuere Formate dürfen keine
  Daten überschreiben oder still einen leeren Arbeitsbereich erzeugen.
- Rückwärtskompatibilität bedeutet: neue App übernimmt ältere Daten. Dass eine
  alte App einen neueren Datenstand öffnen kann, ist nicht vorausgesetzt.
  Rückfall nur mit passender alter App und zugehöriger Sicherung.

## Entwicklung, Tests und Git

- Automatisierte Tests und Beispieldaten ausschließlich in getrennten temporären
  Arbeitsbereichen ausführen. Manuelle Entwicklungs-/Migrationstests über
  `--dart-define=PARA_DATA_DIR=...` auf einen eigenen beschreibbaren Datenordner
  richten; niemals den regulären Nutzerbestand als Testumgebung verwenden.
- Standard-Bundle-Kennung und regulären Datenpfad bei Updates stabil halten.
  Ein bewusst gewählter Test-Datenpfad ist keine Verlagerung der Nutzerdaten.
- Nutzerdaten, lokale Sicherungen, Test-Arbeitsbereiche, Zugangsdaten und
  Build-Ergebnisse gehören nicht ins Git-Repository. Synthetische Test-Fixtures
  und geprüfte Vergleichsbilder dürfen versioniert werden.
- Bedienung und Grenzen aktuell halten: [README.md](README.md),
  [Sicherung](docs/SICHERUNG.md), [Architektur](docs/ARCHITEKTUR.md) und
  [Arbeitsstand](docs/UMSETZUNGSPLAN.md). Geplante Schutzmaßnahmen nicht als
  bereits implementiert darstellen.
