# Zusammenarbeit an diesem Projekt

- Zuerst PLANUNG.md und README.md lesen.
- Aktuell: lokale Flutter-App auf macOS und Linux. Der Produktstand steht in PLANUNG.md,
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
  Markdown-Editor mit Live, Quelltext und Lesen; kompakte Aktionen im Dateitabstreifen.
  Textversionen bei Markdown im Dateiaktionsmenü, bei TXT über das Verlaufssymbol. Aufgaben zeigen
  mehrere Kontext-, Zeit- und Energie-Chips unter dem Titel.
- UI-Mocks enthalten Beispieldaten. Ihre Inhalte oder Klicks sind keine
  verbindlichen Produktentscheidungen.

## Dokumentation dauerhaft synchron halten

- Dokumentation ist Teil der Fertigstellung jeder fachlichen Änderung, kein
  späterer Nachtrag. Alle betroffenen Anleitungen, Fachpläne, MCP-/Skill-Verträge
  und Querverweise im selben Arbeitsgang mit der Implementierung abgleichen;
  nicht nur README oder den Arbeitsstand ändern. Zuständigkeiten und Übersicht:
  [docs/README.md](docs/README.md).
- Implementierte Funktionen an Code und vorhandenen Prüfungen belegen. Bestätigte,
  noch offene Anforderungen und unverbindliche Vorschläge klar kennzeichnen.
  Ein Widerspruch in älterer Dokumentation ist kein Auftrag, neue Funktionen
  einzubauen. Aktuelle Nutzeranweisungen gehen älteren Beschreibungen vor.
- Bei geänderter Bedienung/Terminologie repositoryweit nach den bisherigen
  Formulierungen suchen. Auch Funktionsgrenzen, Plattformen, Versionen, Daten-/
  Sicherungsformate, Start-/Suchverhalten und MCP-Umfang prüfen, soweit betroffen.
- Versionsgebundene Prüfnachweise mit ihrer tatsächlichen Version und Plattform
  erhalten; sie sind keine aktuelle Vollabnahme oder fortgeltenden Arbeitsaufträge.
  Veraltete fachliche Aussagen korrigieren oder eindeutig als überholten Entwurf
  kennzeichnen und auf den aktuellen Vertrag verweisen. Mocks bleiben Beispiele.
- Vor Abschluss sowie Commit/Push die betroffenen Dokus gegen den finalen Code
  prüfen, lokale Verweise und `git diff --check` kontrollieren. Eine Änderung ist
  erst fertig, wenn Implementierung, Bedienung und dokumentierter Status zusammenpassen.

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
- Inhalte und fachliche Einstellungen liegen gemeinsam im gewählten Root,
  einschließlich Kontextdefinitionen und Sitzungszustand. Außerhalb nur Startverweis
  und geräteabhängige Ordnerrechte merken; gewählte Roots über Updates erhalten.
- Standard-Bundle-Kennung und regulären Datenpfad bei Updates stabil halten.
  Ein bewusst gewählter Test-Datenpfad ist keine Verlagerung der Nutzerdaten.
- Nutzerdaten, lokale Sicherungen, Test-Arbeitsbereiche, Zugangsdaten und
  Build-Ergebnisse gehören nicht ins Git-Repository. Synthetische Test-Fixtures
  und geprüfte Vergleichsbilder dürfen versioniert werden.
- Bedienung und Grenzen aktuell halten: [README.md](README.md),
  [Sicherung](docs/SICHERUNG.md), [Architektur](docs/ARCHITEKTUR.md) und
  [Arbeitsstand](docs/UMSETZUNGSPLAN.md). Geplante Schutzmaßnahmen nicht als
  bereits implementiert darstellen.
