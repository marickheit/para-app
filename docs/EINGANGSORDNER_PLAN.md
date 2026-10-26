# Automatischer Eingangsordner

Finalisierter Umfang für Version 0.8.0. Umsetzung und Prüfungen stehen im
[Implementierungsplan](EINGANGSORDNER_UMSETZUNGSPLAN.md).

## Bedienung und Umfang

- Ein frei gewählter lokaler Ordner ist der Inbox eines bestimmten Arbeitsbereichs
  zugeordnet. Dateien und verschachtelte echte Ordner einschließlich leerer Ordner
  werden mit ihrer Struktur übernommen. Beispiel:
  `PARA-Eingang/Steuern/2026/Beleg.pdf` → `Inbox/Steuern/2026/Beleg.pdf`.
- Die Inbox unterstützt Ordner bereits; kein neuer Inhaltstyp erforderlich.
- Verarbeitung nur bei laufender App. Beim Start und regelmäßig nachprüfen;
  keine Hintergrunddienste oder Autostarts. Ausdrücklich aktivierte Automatik darf
  beim nächsten normalen Start weiterlaufen. Pause bleibt über Neustarts erhalten.
- Einstellungen → Eingangsordner: auswählen, Aktivierung mit Hinweis auf vorhandene
  Inhalte bestätigen, pausieren, jetzt prüfen, Status/Fehler und Originale öffnen.
- Alle Dateien bleiben bytegetreue Dateien. Auch kleine Markdown-Dateien sind als
  Dateien bearbeitbar; die automatische Umwandlung in Notizen bleibt dem bisherigen
  manuellen Import vorbehalten. Keine OCR oder automatische KI-Verarbeitung.
- Neue gleichnamige Einwürfe sind getrennte Inhalte. Wiederaufnahme desselben Jobs
  erhält dagegen Eltern-/Kind-UUIDs und erzeugt keinen zweiten Teilbaum.
- Originale erst nach geprüfter Veröffentlichung aus dem sichtbaren Eingang nehmen
  und in `.para-ingest/completed/<Job-ID>/` derselben Quelle aufbewahren.
  Keine automatische Leerung; dieser zusätzliche Speicherbedarf ist beabsichtigt.

## Regeln und Grenzen

- Quelle weder innerhalb noch oberhalb des Arbeitsbereichs; keine Repositories,
  Sicherungs-/Rückholordner, Symlinks, Spezialdateien oder macOS-Dateipakete.
  Unfertige Downloads und temporäre Dateien zurückstellen.
- Ordner nicht teilweise übernehmen und anschließend insgesamt entfernen. Den ganzen
  unterstützten Baum samt Identitäten aufnehmen, kopieren und vor/nach Quellverschiebung
  prüfen. Neue, nicht lesbare oder geänderte Kinder verhindern den Abschluss.
- Native Kopien lesen ohne Symlinkfolge und vergleichen den beim Lesen ermittelten
  SHA-256 mit der anschließend erneut gelesenen Zwischenkopie. Verschiebungen
  überschreiben keine vorhandenen Ziele. Originale niemals endgültig löschen.
- Ruhephasen und stabile Metadaten sind kein Fertigsignal. Ein noch geöffnetes
  Schreibprogramm kann weiter schreiben. Zuverlässige Erzeuger schreiben außerhalb
  des Eingangs fertig und verschieben erst nach dem Schließen hinein.
  Spätere Änderungen im Rückholbereich werden nicht erneut automatisch importiert.
- Erste Version ist für lokale Dateisysteme geprüft. Cloud-Platzhalter, Netzlaufwerke,
  mehrere Eingangsordner und Verarbeitung bei beendeter App bleiben weiterer Ausbau.
- Quellen-/Jobfehler werden in den Einstellungen angezeigt. Andere verarbeitbare
  Einwürfe derselben Quelle können weiterlaufen; es gibt nur eine Quelle je Root.
  Bei aktiver Automatik nach Beheben „Jetzt prüfen“ verwenden. Hat sich die Quelle
  nach Veröffentlichung verändert, importierte Fassung und Original behalten und
  die Abweichung manuell prüfen.

## Technische Umsetzung

- `InboxIngestService` nutzt rekursive Kontrollscans, eine Ruhephase und die
  Repository-Warteschlange. Root-Ereignisse beschleunigen den Abgleich. Tiefe
  Änderungen werden unabhängig von Ereignissen bei jedem Kontrollscan gefunden.
  Damit sind auch auf Linux keine unbeschränkt vielen Unterordner-Watcher nötig.
- Schema 6 ergänzt `ingest_jobs` mit versioniertem Payload. Zustände:
  `preparing` → `ready` → `committed` → `done`; `recovered` für unabhängig
  fertiggestellte Sicherungskopien ohne Zugriff auf die ursprüngliche Quelle.
- Geprüfte Zwischenkopien liegen unter `ingest/<Job-ID>/`, Layoutkennung 1.
  Reservierte UUIDs, Elternbeziehungen, Manifest und Prüfsummen liegen im Journal.
  Inhaltsdatensätze und Journalzustand werden gemeinsam veröffentlicht. Fehler des
  abgeleiteten Suchindex machen keinen zweiten Import nötig.
- Der Dienst wird vor Rootwechsel/Repositoryschluss angehalten. Prozessübergreifende
  Quellensperre und Sperre im Prozess verhindern gleichzeitigen Konsum derselben Quelle.
  Sicherungsexport wartet in derselben Warteschlange auf laufende Importoperationen.
- Fachliche Zuordnung/Aktivierung: `ingest.sources.v1` im Root. Außerhalb nur lokale
  Ordnerrechte, gebunden an kanonischen Root, Quellenpfad und Bindungskennung.
  macOS verwendet zusätzlich seine persistente Ordnerfreigabe.
- Schemaübernahme aus 1–5 erst nach vollständiger Rückfallkopie. Sicherungsformat 3
  enthält das Journal und interne Zwischenstände. Quellenfreigabe im Sicherungsabbild
  invalidieren; eine Rückholung darf keine externen Originale automatisch verschieben.
  Verifizierte interne Zwischenkopien lassen sich unabhängig fertigstellen.
- Externe Originale und Rückholkopien gehören nicht automatisch zur Sicherung des
  Arbeitsbereichs. Unvollständige Zwischenkopien nicht als fertigen Inhalt ausgeben.

## Verworfen für die erste Version

Ein eigener Hintergrunddienst oder eine weiterlaufende App ohne Fenster wären
möglich, benötigen aber zusätzlichen Lebenszyklus, Prozesskoordination und native
macOS-Rechte. Ein externes Kopier-/Löschskript bietet nicht das notwendige Journal
und darf die App-Datenbank oder deren exklusive Sperre nicht umgehen.

## Technische Quellen

- [Dart: FileSystemEntity.watch](https://api.dart.dev/dart-io/FileSystemEntity/watch.html):
  Plattformunterschiede, fehlende Linux-Rekursion und zusammengefasste Ereignisse.
- [Apple: App Sandbox](https://developer.apple.com/documentation/security/accessing-files-from-the-macos-app-sandbox):
  Ordnerauswahl, persistente Bookmarks und Zugriffslebenszyklus.
