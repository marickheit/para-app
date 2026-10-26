# P.A.R.A. MCP

Lokaler stdio-Server für die laufende P.A.R.A.-App ab Version 0.7.
Node.js >=22; offizielles MCP TypeScript SDK 2.4.0 (stabile v2-Linie,
Protokoll 2026-07-28 mit SDK-Unterstützung älterer Clients).
Abhängigkeiten sind einschließlich Lockdatei festgelegt.

```sh
npm ci
npm run build
node dist/server.js /absolute/path/para-mcp-connection.json
```

Die Verbindungsdatei wird in der App über Einstellungen → KI-Anbindung erzeugt.
Sie bleibt außerhalb dieses Repositories. stdout enthält ausschließlich MCP;
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
