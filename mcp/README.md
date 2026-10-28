# P.A.R.A. MCP

Lokaler stdio-Server 0.3.0 für die laufende P.A.R.A.-App ab Version 0.8.1
(aktueller App-Stand 0.11.0), API-Funktionsstand 2 mit 19 Werkzeugen.
Node.js >=22; offizielles MCP TypeScript SDK 2.4.0 (stabile v2-Linie,
Protokoll 2026-07-28 mit SDK-Unterstützung älterer Clients).
Abhängigkeiten sind einschließlich Lockdatei festgelegt.

```sh
npm ci
npm run build
node dist/server.js
```

Einstellungen → KI-Anbindung → Zugriff aktiviert die Verbindung unmittelbar.
Die App verwaltet die private Verbindungsdatei auf macOS/Linux automatisch;
der Server findet sie ohne Pfadargument. Ein optionales Pfadargument wird für
bestehende Konfigurationen und getrennte Tests weiterhin unterstützt.
Die Datei bleibt außerhalb dieses Repositories und des Arbeitsbereichs. stdout enthält ausschließlich MCP;
Diagnosen stehen auf stderr. Der Prozess öffnet keine SQLite-Datenbank und
übernimmt keine App-Öffnung oder Migration.

[Einrichtung, Rechte, Werkzeuge und Grenzen](../docs/MCP.md) ·
[Client-Beispiel](config/client.example.json)

```sh
npm test
```

Tests verwenden ausschließlich temporäre Dateien und lokale Testserver.
`test/app-smoke.mjs` wird zusätzlich von Flutter gegen ein echtes Repository
und im nativen Release-Test gegen die App-Bridge ausgeführt.
