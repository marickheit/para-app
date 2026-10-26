# Review 0.6

Versionsgebundener Review-Nachweis für 0.6; keine aktuelle Abnahme von 0.9.2.
Aktuelle Bedienung: [README](../README.md), Prüfstand: [Arbeitsstand](UMSETZUNGSPLAN.md).

Für die damalige Review wurde die Release-App mit einem getrennten Beispielarbeitsbereich
gestartet. Bisherige Nutzerdaten und deren Startauswahl wurden nicht verändert.
Die bisherige App wurde damals zusätzlich als lokale Rückfallkopie erhalten.

## Zum Ausprobieren

1. In „Nächste Aktionen“ die Chips unter den Aufgaben vergleichen. Eine Aufgabe
   öffnen und mehrere Kontexte, Zeit und Energie ändern; speichern. Angaben können
   auch vollständig leer bleiben.
2. Über den Filterbutton Kontexte, verfügbare Zeit und Energie kombinieren.
   „Mindestens einer“ und „Alle ausgewählten“ vergleichen, Aufgaben ohne Angaben
   ein-/ausschließen und anschließend zurücksetzen.
3. Menü → Einstellungen oder Cmd+, → Aufgaben / Kontexte: Kontext anlegen,
   umbenennen, umfärben, sortieren oder deaktivieren. Vorhandene Zuordnungen bleiben
   beim Umbenennen und Deaktivieren erhalten.
4. Unter „Daten & Sicherung“ den Beispielbestand in einen eigenen leeren Ordner
   kopieren. App vollständig beenden und erneut öffnen: Bestand, Einstellungen
   und Ansicht sollen aus diesem Ordner wiederkommen. „Arbeitsbereich öffnen …“
   wechselt zurück; „Neuen Arbeitsbereich anlegen …“ startet einen getrennten
   leeren Bestand. Für die Review ausschließlich Testordner verwenden.

## Geprüft und noch offen

59 Fach-/Widgettests, 13 native Mac-Prüfungen und die Codeprüfung sind erfolgreich.
Ordnerauswahl und Freigabe nach vollständigem Neustart wurden zusätzlich mit einem
externen Testordner geprüft. Ältere Datenformate, vollständige Sicherungen,
fehlende Ordner und fehlgeschlagene Wechsel sind durch isolierte Prüfungen abgedeckt.

Ungespeicherte Texte benötigen weiterhin Speichern/Verwerfen/Abbrechen.
Kontexte lassen sich deaktivieren; dauerhaftes Entfernen wird nicht angeboten.
Automatische regelmäßige Backups, App-Updater, Cloud-Sync und Wiederherstellung
ungespeicherter Entwürfe gehören nicht zu dieser Umsetzung.

[Umfang](UMSETZUNG_0_6.md) · [Prüfnachweise und Bilder](UMSETZUNGSPLAN.md) ·
[Bedienung](../README.md).
