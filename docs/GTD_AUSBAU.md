# GTD-Ausbau: Aufgabenangaben und weitere Vorschläge

Stand 0.9.2; Aufgabenangaben seit 0.6: Zeitbedarf, mehrere Kontexte, Energie, Chips, Kontextverwaltung und
Filter sind implementiert. Weitere GTD-Funktionen unten bleiben Vorschläge.

## Aufgabenangaben in 0.6

| Angabe | Auswahl | Voreinstellung |
| --- | --- | --- |
| Zeitbedarf | 5, 15, 30, 60 oder 120 Minuten; zusätzlich „Eigene Dauer …“ in Minuten | Keine Angabe |
| Kontexte | Mehrfachauswahl aus einer in Einstellungen verwaltbaren Liste; kein Hauptkontext und keine feste Anzahl pro Aufgabe | Keine Kontexte |
| Energiebedarf | Feste Stufen niedrig, mittel, hoch | Keine Angabe |

Zeitbedarf beschreibt geschätzte aktive Bearbeitungszeit. Alle Angaben sind
optional, beim schnellen Erfassen reicht weiterhin der Titel. „Keine Angabe“ ist
beim Energiebedarf ein eigener leerer Wert und wird nicht mit „niedrig“ gleichgesetzt.

Kontexte werden unter Einstellungen → Aufgaben → Kontexte hinzugefügt, umbenannt,
deaktiviert und sortiert. Die Anzahl ergibt sich aus der Liste; kein zusätzliches
Feld „Anzahl der Kontexte“. Anfangswerte: Zuhause, Unterwegs, Arbeit;
die Namen sind frei änderbar. Weitere Werte wie Telefon oder Computer kann man selbst
ergänzen. Kontextdefinitionen gehören zum Arbeitsbereich und damit in Sicherung,
Datenordnerübernahme und spätere Migrationen.

Umbenennen erhält die Zuordnung bestehender Aufgaben über eine stabile Kennung.
Deaktivierte Kontexte bleiben an vorhandenen Aufgaben sichtbar und filterbar;
sie verschwinden aus der normalen Auswahl für neue Zuordnungen. Endgültiges Entfernen
von Kontextdefinitionen wird nicht angeboten; Deaktivieren erhält alle Zuordnungen.
Vorhandene freie Kontexttexte werden verlustfrei übernommen, ohne sie automatisch
zu zerlegen. Gleiche bestehende Werte können dieselbe Kontextdefinition verwenden.

In Aufgabendetails eine Kontext-Mehrfachauswahl sowie kompakte Felder für Zeit
und Energie. Schnellerfassung ohne diese Angaben bleibt möglich.

### Darstellung als Chips

Alle Kontexte, Zeitbedarf und Energie als kleine farbige, abgerundete
Chips nach Art der bereitgestellten Referenz. Nur gesetzte Werte darstellen.
Beispiel: „Computer“, „Arbeit“, „30 Min“, „Mittel“ als vier getrennte Chips.

Platzierung: direkt unter dem Aufgabentitel, kleiner als der Titel,
bei Platzmangel mit Zeilenumbruch. Titel, Checkbox und Drei-Punkte-Menü behalten
ihren Platz. Keine zusätzliche dauerhafte Seitenleiste.

Gestaltung: dezente Hintergrundtönung und farbiger Rand, lesbar
in heller und dunkler Darstellung. Kontextfarben in der Kontextverwaltung wählbar;
Zeit und Energie erhalten jeweils eine einheitliche eigene Farbgebung und ein
kleines Uhr-/Blitzsymbol. Die ausgeschriebenen Werte bleiben sichtbar, sodass
Information nicht allein von der Farbe abhängt.

Ein kleiner Filterbutton in „Nächste Aktionen“ öffnet Kontext, maximal verfügbare
Zeit und maximalen Energiebedarf. Aktive Filter bleiben erkennbar und lassen sich
gemeinsam zurücksetzen. Bei mehreren gewählten Kontextfiltern stehen „Mindestens einer“
und „Alle ausgewählten“ zur Auswahl; Standard „Mindestens einer“.
Kontexte sind frei vergebene Kennzeichnungen, keine automatisch ermittelten
Orts-/Gerätebedingungen. Zeit und Energie schränken das Ergebnis zusätzlich ein. Projektgruppierung
bleibt erhalten. „Ohne Angaben einbeziehen“ standardmäßig aktiv und sichtbar;
fehlende Angaben werden nicht als null Minuten oder niedrigste Energie gespeichert.

Beispiel: „Zuhause · höchstens 30 Min · höchstens Mittel“ zeigt passende Aufgaben
für die aktuelle Situation, einschließlich der auf Wunsch eingeblendeten Aufgaben
mit noch fehlenden Angaben. Filter verbergen Aufgaben nur in der Ansicht und ändern
weder Status noch Priorität.

Es gibt keinen hervorgehobenen Hauptkontext. Beispielsweise können „Computer“
und „Arbeit“ gleichberechtigt an derselben Aufgabe stehen. Anzahl und Namen der
insgesamt verfügbaren Kontexte bleiben in Einstellungen frei verwaltbar.

## Weitere Vorschläge zur späteren Auswahl

| Ergänzung | Konkreter Nutzen | Empfehlung |
| --- | --- | --- |
| Projektprüfung | Vorhaben erkennen, für die noch keine ausführbare nächste Aktion feststeht | Zuerst |
| Wochenrückblick | Inbox, nächste Aktionen, wartende Aufgaben, Projekte und Irgendwann regelmäßig durchgehen | Zuerst |
| Warten auf: Person und Nachfassen | Wissen, von wem seit wann etwas fehlt und wann man nachsehen möchte | Danach |
| Wiedervorlage / Startdatum | Etwas bewusst später wieder vorlegen, ohne eine künstliche Fälligkeit zu setzen | Danach |
| Schnellerfassung für Aufgaben | Gedanken mit einem Titel direkt in die Inbox aufnehmen und später klären | Danach |
| Wiederkehrende Aufgaben | Regelmäßige Pflichten ohne manuelles Neuanlegen verfolgen | Später; Termin- und Abschlussregeln zuerst festlegen |

Diese weiteren Funktionen und ihre Reihenfolge sind Vorschläge, keine bereits
getroffene Produktauswahl.

## Zeit, Energie und Kontext

GTD berücksichtigt bei der Auswahl von Handlungen Kontext, verfügbare Zeit,
Energie und Priorität. Eine Schätzung soll deshalb helfen, eine jetzt passende
Aufgabe auszuwählen; sie braucht keine aufwendige Projektkalkulation.
[Grundlage: Choosing what to do, David Allen Company](https://gettingthingsdone.com/2023/01/choosing-what-to-do/).

- Zeitbedarf und Energiebedarf bleiben getrennt. Eine kurze Aufgabe
  kann viel Konzentration benötigen; Dauer und Schwierigkeit nicht gleichsetzen.
- In „Nächste Aktionen“ Filter für Kontext, verfügbare Zeit und optional Energie.
  Die Gruppierung nach Projekt bleibt erhalten, einschließlich Aufgaben ohne Projekt.
- Aufgaben ohne Schätzung bleiben standardmäßig sichtbar. Fehlende Angaben sind
  kein Fehler; das Anlegen einer Aufgabe bleibt ohne diese Felder möglich.
- Die implementierte Kontext-Mehrfachauswahl übernimmt ältere freie Kontextwerte
  verlustfrei. Umbenennen und Deaktivieren erhalten bestehende Zuordnungen.
- Kleine Angaben bei Bedarf in den Aufgabendetails, dezente Hinweise in der Liste.
  Keine zusätzlichen dauerhaften Spalten oder Pflichtfelder als Voreinstellung.
- Keine automatische Priorisierung nach kürzester Dauer, keine verpflichtenden
  Aufwandspunkte, keine automatische Terminvergabe aus einer Zeitschätzung.

## Projektprüfung und Wochenrückblick – unbestätigter Vorschlag

Ein aktives Projekt soll eine klar erkennbare nächste Handlung haben. Als Hilfe
eine unaufdringliche Ansicht „Projekte ohne nächste Aktion“ anbieten. Aufgaben in
Unterordnern mitzählen, Papierkorb/Archiv und abgeschlossene Aufgaben ausschließen.
Ein Projekt mit ausschließlich wartenden Aufgaben als „Wartet auf …“ kennzeichnen;
das ist ein anderer Fall als eine fehlende Planung und kein pauschaler Fehler.

Der Wochenrückblick führt in einem auf Abruf geöffneten Fenster durch Inbox,
nächste Aktionen, wartende Aufgaben, Projekte und Irgendwann. Bestehende Listen
verwenden; keine neue Aufgabenablage und kein neuer Projektstatus. Optional kann
später ein ausdrücklich bestätigter Prüfzeitpunkt gespeichert werden. Kalender
zunächst als manuellen Prüfschritt berücksichtigen, ohne eine Integration vorauszusetzen.
[Grundlage: offizieller Weekly Review](https://gettingthingsdone.com/2018/08/episode-43-the-power-of-the-gtd-weekly-review/).

## Weitere unbestätigte Vorschläge

- „Warten auf“ könnte Person, Beginn des Wartens und optional einen Nachfasstermin
  erhalten. Dieser Termin ist keine Fälligkeit der eigentlichen Aufgabe.
- Wiedervorlage/Startdatum von echter Fälligkeit unterscheiden. Später vorgesehene
  Aufgaben bleiben in einer zugänglichen Ansicht sichtbar, auch wenn die aktuelle
  Nächste-Aktionen-Liste sie ausblendet.
- Bei Wiederholungen zuerst feste Kalendertage gegenüber einem Abstand nach
  Erledigung und den Umgang mit ausgelassenen Terminen festlegen. Frühere Abschlüsse
  und ihre Kennungen nicht bei jeder Wiederholung überschreiben.
- Kontext-, Zeit- und Energieangaben helfen bei der Auswahl. Priorität entsteht
  zusätzlich aus Ergebnis, Verpflichtungen und aktueller Situation; eine starre
  Punktesumme kann diese Entscheidung nicht zuverlässig ersetzen.

Projekte behalten die bestehenden Regeln: Ergebnis und Fälligkeitsdatum,
kein Irgendwann-Status. Alle Ergänzungen benötigen die Kompatibilitäts- und
Migrationsprüfungen aus [AGENTS.md](../AGENTS.md).
