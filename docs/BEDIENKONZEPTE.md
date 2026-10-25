# Kompaktere Oberfläche – Entwürfe

In Flutter 0.4 umgesetzt: **Symbolleiste mit Projekt-Explorer**. Der frühere
kompakte Explorer und die weiteren Varianten bleiben Vergleichsentwürfe.
Ihre Anforderungen, der Abgleich mit der App und der weitere Mockup-Plan stehen
im [UI-Umzug](UI_UMZUG.md). Maßgeblich für Bedienung und Grenzen der App ist README.md.
Die [aktuelle Mockup-Quelle](mockups/para-zieloberflaeche.html) ergänzt Editor,
Anlage, Import, Kontextaktionen, Verschieben und Aufgabenabschluss.

## Gemeinsame Richtung

Mehr Platz für Notizen, Dateien und Aufgaben. Suche und Erfassen über kleine
Buttons/Tastatur statt dauerhafter Suchleiste. Projektkontext, Ansichtswechsel
und Dokumentaktionen zusammenführen. Projektdetails nur bei Bedarf öffnen.
Die bestehenden Speicher- und Projektregeln bleiben die Grundlage.

## Varianten

- **Kompakter Explorer:** P.A.R.A.-Navigation und Projektordner in einer
  Seitenleiste. Eine gemeinsame Kopfzeile; rechts direkt der Editor.
  Gute Orientierung bei vielen Dateien, etwas mehr dauerhafte Navigation.
- **Liste mit Detail:** Schlanke Navigation, gemischte Inhaltsliste und Editor.
  Aufgaben, Notizen und Unterlagen bleiben nebeneinander erreichbar.
  Besonders gut zum Durcharbeiten; weniger Breite je Spalte.
- **Dokument im Fokus:** Schmale Symbolleiste, Dokument als Hauptfläche.
  Projekt-/Dateiwechsel, Ordner und Aufgaben bei Bedarf einblenden.
  Größte Arbeitsfläche; weniger dauerhaft sichtbare Struktur.
- **Symbolleiste mit Projekt-Explorer:** An Obsidian angelehnte Symbolleiste,
  per Button um die Navigationsnamen erweiterbar. Daneben ein Projektbaum mit
  Ordnern und Dateien; im Projekt direkter Wechsel zwischen Inhalten und Aufgaben.
  Globale Aufgaben öffnen die GTD-Ansichten. Breiten und Zeilenabstände sind im
  Mockup vergleichbar. Die Gestaltung und bestätigten Funktionen sind in Flutter 0.4 umgesetzt.

## Anforderungen im Symbolleisten-Mockup

- Aktive Projekte stehen ausschließlich auf oberster Ebene der Projektliste;
  im Archiv können sie unter Jahr/Herkunft liegen. Ein eigenes Projektsymbol
  unterscheidet sie von normalen Ordnern.
- Ordner lassen sich durch Klick auf die Zeile auf- und zuklappen. Ihre Notizen
  und Dateien erscheinen direkt im Explorer, auch innerhalb von „Unterlagen“.
- Dateien öffnen bei unterstützten Formaten eine Vorschau. Ein kleines
  Info-Symbol zeigt Typ, Größe, Änderungsdatum, Ablageort und Suchunterstützung.
  Für andere Formate steht ein Download zur Verfügung.
- Lupe oder Cmd+F / Strg+F öffnet eine schwebende Suche mit unscharfem
  Namensabgleich und Inhaltstreffern für unterstützte Formate. Pfeiltasten,
  Enter und Esc bedienen Auswahl, Öffnen und Schließen.

Im Mockup laufen Vorschau und Inhaltssuche mit hinterlegten Beispieldaten;
PDF- und Bilddarstellung illustrieren das Verhalten. Das Download-Beispiel ist
ein leeres ZIP-Archiv. Die App verwendet echte Vorschauen und Dateiindizes
innerhalb der in README.md beschriebenen Grenzen. Weiterer Suchausbau ist offen.

Die Mockups enthalten Beispieldaten. Maßgeblich für die aktuelle App sind
[Produktstand](../PLANUNG.md) und [Bedienung](../README.md). Referenzen:
[Everdo](https://everdo.net/) und [Obsidian Quick switcher](https://help.obsidian.md/plugins/quick-switcher).
