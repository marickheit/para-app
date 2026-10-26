import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, writeFile, chmod, symlink, rm, readFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { createServer } from 'node:http';
import { randomBytes } from 'node:crypto';
import { readConnection, BridgeClient } from '../dist/bridge.js';
import { Client } from '@modelcontextprotocol/client';
import { StdioClientTransport } from '@modelcontextprotocol/client/stdio';

const token = randomBytes(32).toString('base64url') + '=';
test('credentials require owner-only regular file and loopback endpoint', async () => {
  const dir = await mkdtemp(join(tmpdir(), 'para-mcp-node-'));
  const path = join(dir, 'connection.json');
  const data = { version: 1, token, endpoint: 'http://127.0.0.1:12345/v1/call', opening_id: 'test' };
  try {
    await writeFile(path, JSON.stringify(data), { mode: 0o600 });
    assert.equal((await readConnection(path)).token, token);
    await chmod(path, 0o644);
    await assert.rejects(readConnection(path), { code: 'connection_file' });
    await chmod(path, 0o600);
    await symlink(path, join(dir, 'link.json'));
    await assert.rejects(readConnection(join(dir, 'link.json')), { code: 'connection_file' });
    for (const endpoint of ['https://evil.example/v1/call', 'http://localhost:12/v1/call', 'http://127.0.0.1:12/other']) {
      await writeFile(path, JSON.stringify({ ...data, endpoint }));
      await assert.rejects(readConnection(path), { code: 'connection_file' });
    }
  } finally { await rm(dir, { recursive: true }); }
});

test('real SDK stdio connection exposes shared contract and forwards structured results', async () => {
  const dir = await mkdtemp(join(tmpdir(), 'para-mcp-stdio-'));
  const path = join(dir, 'connection.json');
  const requests = [];
  const server = createServer(async (req, res) => {
    assert.equal(req.headers.authorization, `Bearer ${token}`);
    let body = ''; for await (const part of req) body += part;
    const call = JSON.parse(body); requests.push(call);
    res.setHeader('Content-Type', 'application/json');
    res.end(JSON.stringify({ result: { opening_id: call.opening_id, items: [], bridge_version: 1 } }));
  });
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  const config = { version: 1, token, endpoint: `http://127.0.0.1:${server.address().port}/v1/call`, opening_id: 'opening-1' };
  await writeFile(path, JSON.stringify(config), { mode: 0o600 });
  const transport = new StdioClientTransport({ command: process.execPath, args: [fileURLToPath(new URL('../dist/server.js', import.meta.url)), path] });
  const client = new Client({ name: 'para-test', version: '1.0.0' });
  try {
    await client.connect(transport);
    const list = await client.listTools();
    const fixture = JSON.parse(await readFile(new URL('../../test/fixtures/mcp/contract.json', import.meta.url), 'utf8'));
    assert.deepEqual(list.tools.map(t => t.name).sort(), [...fixture.read_tools, ...fixture.write_tools].sort());
    const response = await client.callTool({ name: 'workspace_info', arguments: {} });
    assert.equal(response.isError, undefined);
    assert.equal(response.structuredContent.bridge_version, 1);
    assert.equal(requests[0].opening_id, 'opening-1');
    await writeFile(path, JSON.stringify({ ...config, opening_id: 'opening-2' }));
    await client.callTool({ name: 'workspace_info', arguments: {} });
    assert.equal(requests[1].opening_id, 'opening-1');
  } finally { await client.close(); await new Promise(resolve => server.close(resolve)); await rm(dir, { recursive: true }); }
});

test('redirect never forwards credentials and ambiguous writes report unknown outcome', async () => {
  const dir = await mkdtemp(join(tmpdir(), 'para-mcp-redirect-'));
  const path = join(dir, 'connection.json');
  const server = createServer((_, res) => { res.writeHead(302, { Location: 'http://example.com/' }); res.end(); });
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  await writeFile(path, JSON.stringify({ version: 1, token, endpoint: `http://127.0.0.1:${server.address().port}/v1/call`, opening_id: 'test' }), { mode: 0o600 });
  try {
    await assert.rejects(new BridgeClient(path).call('create_note', {}), { code: 'outcome_unknown' });
  } finally { await new Promise(resolve => server.close(resolve)); await rm(dir, { recursive: true }); }
});
