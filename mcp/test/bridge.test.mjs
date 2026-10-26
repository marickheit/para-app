import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, mkdir, writeFile, chmod, symlink, rm, readFile } from 'node:fs/promises';
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
    const entry = '00000000-0000-4000-8000-000000000001';
    const existing = { id: entry, expected_revision: 1, request_id: 'schema-write' };
    const invalidCalls = [
      ['create_area', { title: 'Area', parent_id: entry, request_id: 'invalid' }],
      ['create_resource', { title: 'Collection', section: 'inbox', request_id: 'invalid' }],
      ['create_folder', { title: 'Folder', request_id: 'invalid' }],
      ['update_entry', existing],
      ['update_entry', { ...existing, due_date: '2026-02-29' }],
      ['edit_text', { ...existing, expected_body_hash: 'a'.repeat(64), operation: 'replace', text: 'new' }],
      ['edit_text', { ...existing, expected_body_hash: 'a'.repeat(64), operation: 'replace', text: 'new', old_text: '' }],
      ['edit_text', { ...existing, expected_body_hash: 'a'.repeat(64), operation: 'append', text: 'new', old_text: 'old' }],
      ['edit_text', { ...existing, expected_body_hash: 'invalid', operation: 'append', text: 'new' }],
      ['create_note', { title: 'Too large UTF-8', text: 'ä'.repeat(524289), request_id: 'invalid' }],
      ['search', { query: 'find', detail: 'everything' }],
      ['edit_text', { ...existing, expected_body_hash: 'a'.repeat(64), operation: 'replace', text: 'new', old_text: '\ud83d' }],
      ['edit_text', { ...existing, expected_body_hash: 'a'.repeat(64), operation: 'append', text: '\ude00' }],
      ['create_area', { title: 'Broken \ud83d', request_id: 'invalid' }],
      ['update_entry', { ...existing, goal: 'Broken \ude00' }],
    ];
    for (const [name, args] of invalidCalls) {
      const response = await client.callTool({ name, arguments: args });
      assert.equal(response.isError, true, name);
    }
    assert.equal(requests.length, 2, 'Invalid arguments must never reach the app bridge.');
    const scoped = { query: 'find', parent_id: entry, section: 'areas', kind: 'note', detail: 'compact' };
    assert.notEqual((await client.callTool({ name: 'search', arguments: scoped })).isError, true);
    assert.deepEqual(requests[2].arguments, scoped);

  } finally { await client.close(); await new Promise(resolve => server.close(resolve)); await rm(dir, { recursive: true }); }
});

test('redirect never forwards credentials and ambiguous writes report unknown outcome', async () => {
  const dir = await mkdtemp(join(tmpdir(), 'para-mcp-redirect-'));
  const path = join(dir, 'connection.json');
  const server = createServer((_, res) => { res.writeHead(302, { Location: 'http://example.com/' }); res.end(); });
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  await writeFile(path, JSON.stringify({ version: 1, token, endpoint: `http://127.0.0.1:${server.address().port}/v1/call`, opening_id: 'test' }), { mode: 0o600 });
  try {
    for (const tool of ['create_note', 'create_task', 'create_project', 'create_area', 'create_resource', 'create_folder', 'update_entry', 'edit_text', 'update_text', 'update_task', 'set_task_state']) {
      await assert.rejects(new BridgeClient(path).call(tool, {}), { code: 'outcome_unknown' }, tool);
    }
    await assert.rejects(new BridgeClient(path).call('list_entries', {}), { code: 'app_unavailable' });
  } finally { await new Promise(resolve => server.close(resolve)); await rm(dir, { recursive: true }); }
});

test('server without a path discovers the Linux connection automatically',
  { skip: process.platform !== 'linux' }, async () => {
  const dir = await mkdtemp(join(tmpdir(), 'para-mcp-discovery-'));
  const folder = join(dir, 'para-mcp');
  await mkdir(folder, { mode: 0o700 });
  const server = createServer((_, res) => {
    res.setHeader('Content-Type', 'application/json');
    res.end(JSON.stringify({ result: { bridge_version: 1, write: false } }));
  });
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  await writeFile(join(folder, 'para-mcp-connection.json'), JSON.stringify({
    version: 1, token, endpoint: `http://127.0.0.1:${server.address().port}/v1/call`,
    opening_id: 'automatic-test',
  }), { mode: 0o600 });
  const client = new Client({ name: 'automatic-test', version: '1.0.0' });
  try {
    await client.connect(new StdioClientTransport({ command: process.execPath,
      args: [fileURLToPath(new URL('../dist/server.js', import.meta.url))],
      env: { ...process.env, XDG_STATE_HOME: dir },
    }));
    assert.equal((await client.listTools()).tools.length, 19);
    const result = await client.callTool({ name: 'workspace_info', arguments: {} });
    assert.notEqual(result.isError, true);
    assert.equal(result.structuredContent.write, false);
  } finally {
    await client.close();
    await new Promise(resolve => server.close(resolve));
    await rm(dir, { recursive: true });
  }
});


test('empty or oversized successful HTTP responses leave write outcome unknown', async () => {
  const dir = await mkdtemp(join(tmpdir(), 'para-mcp-response-'));
  const path = join(dir, 'connection.json');
  let empty = true;
  const server = createServer((_, res) => {
    if (empty) { res.writeHead(204); res.end(); }
    else { res.setHeader('Content-Type', 'application/json'); res.end('x'.repeat(2 * 1024 * 1024 + 1025)); }
  });
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  await writeFile(path, JSON.stringify({ version: 1, token, endpoint: `http://127.0.0.1:${server.address().port}/v1/call`, opening_id: 'response-test' }), { mode: 0o600 });
  try {
    await assert.rejects(new BridgeClient(path).call('edit_text', {}), { code: 'outcome_unknown' });
    await assert.rejects(new BridgeClient(path).call('read_text', {}), { code: 'invalid_response' });
    empty = false;
    await assert.rejects(new BridgeClient(path).call('edit_text', {}), { code: 'outcome_unknown' });
    await assert.rejects(new BridgeClient(path).call('read_text', {}), { code: 'too_large' });
  } finally { await new Promise(resolve => server.close(resolve)); await rm(dir, { recursive: true }); }
});
