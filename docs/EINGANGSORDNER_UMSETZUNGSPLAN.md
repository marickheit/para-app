# Eingangsordner – Implementierungsplan

Version: 0.8.0+11. Status: implementiert, geprüft und lokal unter Linux installiert.
Der Nutzer hat die Funktion im Praxistest bestätigt und Commit/Push freigegeben.

## Festgelegter Umfang

- Ein frei gewählter lokaler Eingangsordner je Arbeitsbereich; Dateien und echte,
  beliebig verschachtelte Ordner einschließlich leerer Ordner erhalten ihre Struktur.
- Automatik läuft nur mit der App, prüft beim Start und regelmäßig rekursiv nach.
  Dateisystemereignisse beschleunigen den Abgleich, sind keine Vollständigkeitsgarantie.
- Dateien bleiben bytegetreue Dateien, auch Markdown. Nach geprüfter Übernahme
  Originale im ausgeschlossenen `.para-ingest`-Rückholbereich der Quelle aufbewahren.
  Keine automatische endgültige Löschung. Kein Zusammenführen gleichnamiger Einwürfe.
- Quellenbindung und Aktivierung im Root; lokale Ordnerfreigabe an genau diesen
  Root gebunden. Kopien/Sicherungsrückholungen aktivieren keine fremden Quellen.
- Quellen innerhalb/oberhalb des Roots, Repositories, Sicherungen, Symlinks,
  Spezialdateien und macOS-Dateipakete ablehnen. Unfertige Kopien zurückstellen.

## Schritte und Abnahme

1. Schema 6: dauerhaftes Importjournal, versionierte Einstellungen und interne
   Zwischenkopien. Migration aus 1–5 mit vollständiger Rückfallkopie; Sicherung
   Format 3 nimmt Journal und Zwischenstände mit. Unabhängige Rückholung prüfen.
2. Wiederanlauffähige Übernahme: stabile Baum-Manifeste, reservierte UUIDs,
   geprüfte Kopien, gemeinsame Veröffentlichung aller Eltern-/Kinddatensätze und
   Journalzustand. Nach Absturz denselben Job fortsetzen; keine zweite Anlage.
3. Native macOS-/Linux-Dateioperationen für Identität, Kopieren ohne Symlinkfolge
   und Verschieben ohne Überschreiben. Vor/nach Quellverschiebung Baum prüfen;
   bei Änderungen keine endgültige Löschung, Original wieder bereitstellen oder
   erhaltenen Rückholort als Fehler zeigen. Ruhephasen sind kein Fertigsignal.
4. App-Dienst, lokale Ordnerrechte, Quellensperre und Lebenszyklus integrieren.
   Vor Rootwechsel anhalten, laufende Jobs abwarten; Sicherung mit Importzustand
   serialisieren. Abgeleitete Suchfehler dürfen keine Doppelimporte auslösen.
5. Einstellungen: Ordner wählen, verständlich aktivieren/pausieren, jetzt prüfen,
   Status/Fehler anzeigen und Eingangs-/Rückholordner öffnen. Kein Zugriff über MCP
   nötig. Ordner nicht selbst am Nutzerbestand aktivieren.
6. Tests: rekursive/gleiche/leere Ordner, Originalbytes, langsame Kopien,
   Quellenwechsel/Symlinks, Neustart an Übergängen, Quellensperren, Pause/Rootwechsel,
   Schemaübernahme und unabhängige Sicherungsrückholung. Gesamtsuite, Analyse,
   nativer Linux-Test und Release-Build. macOS-Nativprüfung hier nicht möglich;
   Plattformcode und offene Prüfung ausdrücklich dokumentieren.
7. Lokale App mit Rückfallkopie aktualisieren; laufende alte App mit offenen
   Entwürfen nicht zwangsweise schließen. Nutzer testen lassen. Commit und Push
   erst nach dessen Rückmeldung; bis dahin Änderungen lokal belassen.

Prüfungen verwenden ausschließlich eigene temporäre Arbeitsbereiche und Quellen.

## Prüfnachweise

- `flutter analyze`: ohne Befund. `flutter test`: alle 100 Tests erfolgreich,
  einschließlich 18 neuer Importtests. Rekursive/leere/gleichnamige Ordner,
  Markdown-Originalbytes, beschädigte Kopien, tiefe Quellenänderungen, Quellensperre,
  Pause/Neustart und drei unterbrochene Übergänge ohne zweite Inhaltsanlage geprüft.
- Ein künstlich abgelehnter Journalabschluss rollt Inhaltsanlage und Journal zurück;
  die Quelle bleibt erhalten. Wiederholung verwendet dieselbe Ziel-UUID.
- Schema 5 mit Papierkorb/Textversionen nach vollständiger Rückfallkopie übernommen
  und unabhängig zurückgeholt. Bestehende Prüfungen der Schemas 1–4, UUIDs, Links,
  Anhänge, Status, Archiv, Textversionen und Einstellungen ebenfalls erfolgreich.
- Format-3-Sicherung mit verifizierter, noch unveröffentlichter Zwischenkopie an
  unabhängigem Ort geöffnet: Inhalt mit derselben UUID fertiggestellt, kein Zugriff
  auf die alte Quelle. Unbekanntes Zwischenformat ohne Textänderung abgelehnt.
- Nativer Linux-Test `integration_test/ingest_test.dart`: Aktivierungsdialog,
  Pause, rekursive Struktur, Originalbytes, Rückholbereich und Wiederanlauf geprüft.
  Native Kopie lehnt Quellenwechsel/Symlinks ab; Verschiebung überschreibt nichts.
- Zwölf bisherige native Linux-Bedienabläufe erfolgreich; ein macOS-spezifischer
  Ordnerrechte-/Bookmark-Test übersprungen. Der neue macOS-Plattformcode ist umgesetzt,
  kann hier aber weder gebaut noch nativ mit Sandbox geprüft werden.
- Regulärer Linux-Release gebaut und lokal nach `~/.local/opt/para-workspace`
  installiert. Alle 24 Paketdateien gegen den Build geprüft. Alte App unter
  `~/.local/opt/para-workspace.previous-0.7.3` erhalten; laufende App nicht beendet.
  Keine regulären Nutzdaten für Tests geöffnet oder migriert. Migration erfolgt
  erst beim nächsten normalen App-Start, nach automatischer vollständiger Rückfallkopie.

## Nutzerabnahme

Am 26. Oktober 2026 vom Nutzer als funktionierend bestätigt.

1. Offene Änderungen speichern, P.A.R.A. schließen und neu öffnen.
2. Einstellungen → Eingangsordner → einen eigenen lokalen Ordner auswählen,
   Aktivieren bestätigen. Zum Einstieg verzichtbare Kopien von Beispieldateien verwenden.
3. Einen verschachtelten Ordner mit Dateien und einem leeren Unterordner einwerfen;
   nach der Ruhephase erscheint derselbe Baum in der Inbox.
4. Originale öffnen: Rückholkopien vorhanden. Gleichnamigen Ordner erneut einwerfen:
   separater Eingang, kein Überschreiben. Pause und Neustart prüfen.
