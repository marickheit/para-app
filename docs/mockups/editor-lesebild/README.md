# Editor-Lesebild: Mock 1

Ausgewählte visuelle Referenz: [mock-1.png](mock-1.png), mit dem eingebauten
Imagegen-Werkzeug aus dem Vergleichsbild erzeugt. Beispielrezept und gezeichnete
Bedienelemente sind keine zusätzlichen Fachanforderungen. Maßgeblich sind
[Umfang und Nachweise](../../EDITOR_LESBILD_PLAN.md) sowie der
[Editorvertrag](../../MARKDOWN_EDITOR_UMSETZUNGSPLAN.md).

Die nativen Vergleichsbilder `native-dark.png`, `native-light.png` und
`native-narrow.png` sowie `native-lists.png` stammen aus dem isolierten synthetischen Test
`integration_test/editor_readability_test.dart` für 0.10.2+18 unter Linux.
Sie zeigen die implementierte Oberfläche; das Mock ist keine pixelgenaue Vorgabe
für Fensterrahmen, Symbolzeichnungen oder Markdown-Inhalte.

## Bildprompt der ausgewählten Referenz

Eingabe: Vergleichsscreenshot, linke Hälfte P.A.R.A. als Ziel, rechte Hälfte
Obsidian ausschließlich als Referenz für den Leserhythmus. Eingebautes Imagegen,
keine CLI/API-Ausführung.

> Use case: ui-mockup. Create ONE high fidelity desktop UI design mockup of the P.A.R.A. app shown in the LEFT half of the reference screenshot, with improved Markdown document typography. The right half is Obsidian, only a reference for calm reading rhythm; do NOT include Obsidian in the output. Output a single wide landscape full app window around 1440x1000, flat pixel sharp UI screenshot, no perspective, no desktop wallpaper or surrounding presentation. Preserve P.A.R.A.'s recognizable shell: narrow left icon rail, adjacent Ressourcen folder explorer about 250px wide, a single compact top strip containing tabs 'Power List.md' and active 'One Pot Feta Pasta.md', then actions 'Live', 'Quelltext', 'Lesen', 'Aa', table icon, save icon and ellipsis. Live selected with restrained sage accent. Explorer rows 'Bullet Journal', 'Disziplin u. Produktivität', expanded 'Kochen', expanded 'Rezepte', selected file 'One Pot Feta Pasta.md', 'Koffer', 'Programming', 'Sexy', 'Software'; muted folder glyphs and subtle selection. Icon rail includes tasks and trash. Keep chrome compact, not gigantic. Main requested changes: fully opaque uniform charcoal editor #202020; darker subtle chrome; centered document column approx 680px wide with generous lateral margins; body text approx 16px with 1.55 line height, section gaps 26px; clear H1 30px and H2 20px. Clean modern sans serif. Text white-grey #d6d6d6, subtle borders. No cards, gradients, glowing effects, decorative images, recipe photograph, or marketing. Document is an ordinary rendered Markdown recipe, NOT a recipe-specific app. Start document after 50px top breathing room with H1 'One Pot Feta Pasta'. Under it small muted inline text 'recipe · vegetarian · pasta · one-pot' as an illustrative compact rendering of metadata, no heavy horizontal rules or raw YAML. H2 'Übersicht', then normal understated two-column Markdown table with rows 'Portionen | 4', 'Vorbereitung | 20 min', 'Koch-/Backzeit | 25 min', 'Gesamtzeit | 45 min', 'Schwierigkeit | leicht', 'Bewertung | ★★★★'. Table uses sensible readable padding, thin muted dividers, no giant full width. Next H2 'Nährwerte', muted 'pro Portion', small two-column Markdown table 'Nährwert | Menge', rows 'Kalorien | 864 kcal', 'Kohlenhydrate | 104 g', 'Ballaststoffe | 5,5 g', 'Fett | 38 g', 'Protein | 33 g'. Next H2 'Zutaten' then comfortably spaced normal bullets '250 g Spaghetti', '200 g Feta', '2 Knoblauchzehen', '250 g Mini-Tomaten', '1 rote Zwiebel', 'Salz, Pfeffer, Olivenöl und Basilikum'. Allow remaining recipe to continue below viewport, with slim vertical scrollbar; do not shrink text to fit all content. Bottom understated path status bar 'Ressourcen / Kochen / Rezepte / One Pot Feta Pasta.md'. This is a visual proposal, not implementation. Prioritize realistic typography, uncluttered existing shell, and a visibly comfortable reading experience.
