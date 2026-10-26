# Projektanlage über MCP

Stand: 26. Oktober 2026.

## Umfang

`create_project` ergänzt App-Dienst, TypeScript-MCP und P.A.R.A.-Skill.
Pflichtfelder: Titel, konkretes Ergebnis (`goal`), gültiges Kalenderdatum
(`due_date`, YYYY-MM-DD), Request-ID; optionaler Beschreibungstext.
Projekte entstehen ausschließlich auf oberster Ebene unter Projekte. Keine
Aufgabenstatus, frei wählbaren Eltern oder Ablagen. Die bestehende Repository-
Projektanlage übernimmt Speichern, UUID und Links; kein neues Datenformat.
Umwandlung vorhandener Aufgaben/Ideen bleibt außerhalb dieser Erweiterung.

## Umsetzung und Abnahme

1. App-Vertrag und MCP-Schema um das Werkzeug erweitern; Pflichtangaben und
   echte Kalenderdaten an beiden Grenzen prüfen. Bestehende Schreibfreigabe,
   Serialisierung und Wiederholungserkennung wiederverwenden.
2. Skill erklärt Pflichtangaben, Nachfragen bei fehlenden Angaben und Zuordnung
   nachfolgender Aufgaben über `parent_id`. Anleitung und Produktstand nachziehen.
3. Temporäre Tests prüfen Anlage, Text/Links, Unteraufgaben, doppelte Requests,
   Wiederöffnen, ungültige Angaben und Nur-Lesen-Schutz. Echter stdio-Client
   prüft alle 14 Werkzeuge einschließlich Projektanlage gegen die App.
4. Analyse, Flutter-/Node-Suiten, Linux-Release und nativen MCP-Test ausführen.
   App und MCP lokal mit Rückfallkopie aktualisieren; Skill verwendet den
   bestehenden Repository-Verweis. Commit und Push ohne Nutzdaten.

Schema 5, Sicherungsformat, Bundle-Kennung und regulärer Datenpfad bleiben
unverändert. Ein neuer nativer macOS-Nachweis ist auf Linux nicht möglich.
Prüfergebnisse stehen im [Arbeitsstand](UMSETZUNGSPLAN.md).
