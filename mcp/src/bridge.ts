import { constants } from 'node:fs';
import { open } from 'node:fs/promises';

export class BridgeError extends Error {
  constructor(public code: string, message: string) { super(message); }
}

export async function readConnection(path: string) {
  let file;
  try {
    file = await open(path, constants.O_RDONLY | constants.O_NOFOLLOW);
    const stat = await file.stat();
    if (!stat.isFile() || stat.size > 8192 || (stat.mode & 0o777) !== 0o600 ||
        (process.getuid && stat.uid !== process.getuid())) throw new Error();
    const value = JSON.parse(await file.readFile('utf8'));
    const url = new URL(value.endpoint);
    if (value.version !== 1 || url.protocol !== 'http:' || url.hostname !== '127.0.0.1' ||
        !url.port || url.username || url.password || url.pathname !== '/v1/call' || url.search || url.hash ||
        typeof value.token !== 'string' || !/^[A-Za-z0-9_-]{43}=$/.test(value.token) ||
        typeof value.opening_id !== 'string') throw new Error();
    return { endpoint: url.toString(), token: value.token as string, opening_id: value.opening_id as string };
  } catch { throw new BridgeError('connection_file', 'Verbindungsdatei fehlt oder ist unsicher. In der App neu freigeben.'); }
  finally { await file?.close(); }
}

export class BridgeClient {
  private connection: Awaited<ReturnType<typeof readConnection>> | undefined;
  constructor(private path: string) {}
  async call(tool: string, args: Record<string, unknown>) {
    // Pin the opening for this MCP process; never silently follow a replacement file.
    this.connection ??= await readConnection(this.path);
    const write = ['create_note', 'create_task', 'create_project', 'create_area', 'create_resource', 'create_folder', 'update_entry', 'edit_text', 'update_text', 'update_task', 'set_task_state'].includes(tool);
    const body = JSON.stringify({ version: 1, opening_id: this.connection.opening_id, tool, arguments: args });
    if (Buffer.byteLength(body) > 2 * 1024 * 1024) throw new BridgeError('too_large', 'Anfrage zu groß.');
    let response;
    try {
      response = await fetch(this.connection.endpoint, {
        method: 'POST', headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${this.connection.token}` },
        body, redirect: 'error', signal: AbortSignal.timeout(30000),
      });
    } catch {
      throw new BridgeError(write ? 'outcome_unknown' : 'app_unavailable', write
        ? 'Ergebnis unbekannt. Inhalt in der App prüfen; Schreibaufruf nicht automatisch wiederholen.'
        : 'App nicht erreichbar. App öffnen, Verbindung freigeben und MCP-Verbindung neu starten.');
    }
    if (!response.ok) throw new BridgeError('connection_rejected', 'Verbindung abgelehnt. App-Freigabe prüfen und MCP neu verbinden.');
    let text = '';
    let size = 0;
    const decoder = new TextDecoder();
    if (!response.body) throw new BridgeError(write ? 'outcome_unknown' : 'invalid_response', 'Leere App-Antwort; Ergebnis in der App prüfen.');
    const reader = response.body.getReader();
    try {
      while (true) {
        const { value, done } = await reader.read();
        if (done) break;
        size += value.byteLength;
        if (size > 2 * 1024 * 1024 + 1024) throw new BridgeError(write ? 'outcome_unknown' : 'too_large', 'App-Antwort zu groß; Ergebnis in der App prüfen.');
        text += decoder.decode(value, { stream: true });
      }
      text += decoder.decode();
      const value = JSON.parse(text);
      if (value.error) throw new BridgeError(value.error.code, value.error.message);
      if (!value.result || typeof value.result !== 'object') throw new Error();
      return value.result as Record<string, unknown>;
    } catch (error) {
      await reader.cancel().catch(() => {});
      if (error instanceof BridgeError) throw error;
      throw new BridgeError(write ? 'outcome_unknown' : 'invalid_response', 'App-Antwort nicht lesbar; Ergebnis in der App prüfen.');
    }
  }
}
