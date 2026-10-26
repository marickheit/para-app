// Called by Flutter/native integration tests against a real, isolated app bridge.
import assert from 'node:assert/strict';
import { fileURLToPath } from 'node:url';
import { Client } from '@modelcontextprotocol/client';
import { StdioClientTransport } from '@modelcontextprotocol/client/stdio';
const client = new Client({ name: 'para-app-e2e', version: '1.0.0' });
const transport = new StdioClientTransport({ command: process.execPath,
  env: { ...process.env },
  args: [process.env.PARA_MCP_SERVER ?? fileURLToPath(new URL('../dist/server.js', import.meta.url)),
    ...(process.argv[2] ? [process.argv[2]] : [])] });
async function call(name, args = {}) {
  const value = await client.callTool({ name, arguments: args });
  assert.notEqual(value.isError, true, JSON.stringify(value.content));
  return value.structuredContent;
}
try {
  await client.connect(transport);
  const info = await call('workspace_info');
  assert.equal(info.write, true);
  const note = await call('create_note', { title: 'MCP integration', text: 'before', request_id: 'e2e-note' });
  const read = await call('read_text', { id: note.id });
  const saved = await call('update_text', { id: note.id, expected_revision: read.revision,
    expected_body_hash: read.body_hash, text: 'after', request_id: 'e2e-save' });
  assert.equal(saved.revision, read.revision + 1);
  assert.equal((await call('read_text', { id: note.id })).text, 'after');
  assert.equal((await call('create_note', { title: 'MCP integration', text: 'before', request_id: 'e2e-note' })).id, note.id);
  await call('list_entries'); await call('search', { query: 'integration' });
  await call('get_entry', { id: note.id }); await call('list_contexts');
  await call('get_links', { id: note.id, direction: 'incoming' });
  const task = await call('create_task', { title: 'MCP task', state: 'next', request_id: 'e2e-task' });
  const updated = await call('update_task', { id: task.id, expected_revision: task.revision, energy: 'low', request_id: 'e2e-task-patch' });
  await call('set_task_state', { id: task.id, expected_revision: updated.revision, state: 'done', request_id: 'e2e-task-done' });
  assert.equal((await call('list_tasks', { state: 'done' })).total, 1);
  process.stdout.write('MCP app end-to-end passed (13 tools).\n');
} finally { await client.close(); }
