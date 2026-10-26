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
  assert.equal(info.api_version, 2); assert.equal(info.default_page_size, 20);
  assert.equal(info.default_text_length, 4000); assert.equal(info.response_budget_bytes, 65536);
  const available = await client.listTools();
  assert.equal(available.tools.length, 19);
  const areaArgs = { title: 'MCP area', text: 'Area details', request_id: 'e2e-area' };
  const area = await call('create_area', areaArgs);
  assert.equal(area.kind, 'area'); assert.equal(area.section, 'areas'); assert.equal(area.parent_id, null);
  assert.equal((await call('create_area', areaArgs)).id, area.id);
  const resource = await call('create_resource', { title: 'MCP resource', text: 'Resource details', request_id: 'e2e-resource' });
  assert.equal(resource.kind, 'resource'); assert.equal(resource.section, 'resources'); assert.equal(resource.parent_id, null);
  for (const tool of ['create_area', 'create_resource']) {
    assert.equal((await client.callTool({ name: tool, arguments: { title: 'No', parent_id: area.id, request_id: `invalid-${tool}` } })).isError, true);
  }
  assert.equal((await client.callTool({ name: 'create_folder', arguments: { title: 'Missing location', request_id: 'missing-folder-location' } })).isError, true);
  const folder = await call('create_folder', { title: 'MCP folder', parent_id: area.id, request_id: 'e2e-folder' });
  assert.equal(folder.kind, 'folder'); assert.equal(folder.parent_id, area.id); assert.equal(folder.section, 'areas');
  const renamed = await call('update_entry', { id: area.id, title: 'MCP renamed area', expected_revision: area.revision, request_id: 'e2e-rename' });
  assert.equal(renamed.title, 'MCP renamed area');
  assert.equal((await call('read_text', { id: area.id })).text, 'Area details');
  const projectArgs = { title: 'MCP project', goal: 'Verified release', due_date: '2028-02-29', text: 'Project details', request_id: 'e2e-project' };
  for (const invalid of [{ due_date: '2026-02-29' }, { goal: ' ' }, { state: 'someday' }, { section: 'inbox' }]) {
    assert.equal((await client.callTool({ name: 'create_project', arguments: { ...projectArgs, ...invalid } })).isError, true);
  }
  const project = await call('create_project', projectArgs);
  assert.equal(project.kind, 'project');
  assert.equal(project.section, 'projects');
  assert.equal(project.parent_id, null);
  assert.equal(project.goal, projectArgs.goal);
  assert.equal(project.due_date, projectArgs.due_date);
  assert.equal((await call('read_text', { id: project.id })).text, projectArgs.text);
  assert.equal((await call('create_project', projectArgs)).id, project.id);
  const revisedProject = await call('update_entry', { id: project.id, expected_revision: project.revision, goal: 'Updated verified release', due_date: '2028-03-01', request_id: 'e2e-project-update' });
  assert.equal(revisedProject.goal, 'Updated verified release'); assert.equal(revisedProject.due_date, '2028-03-01');
  await call('update_entry', { id: project.id, expected_revision: revisedProject.revision, goal: projectArgs.goal, due_date: projectArgs.due_date, request_id: 'e2e-project-restore' });
  const note = await call('create_note', { title: 'MCP integration', text: 'before', request_id: 'e2e-note' });
  const read = await call('read_text', { id: note.id });
  const saved = await call('update_text', { id: note.id, expected_revision: read.revision,
    expected_body_hash: read.body_hash, text: 'after', request_id: 'e2e-save' });
  assert.equal(saved.revision, read.revision + 1);
  assert.equal((await call('read_text', { id: note.id })).text, 'after');
  assert.equal((await call('create_note', { title: 'MCP integration', text: 'before', request_id: 'e2e-note' })).id, note.id);
  const compact = await call('list_entries');
  assert.equal(compact.items.some(item => 'updated_at' in item), false);
  assert.equal('updated_at' in (await call('list_entries', { detail: 'full' })).items[0], true);
  await call('search', { query: 'integration' });
  const scoped = await call('search', { query: 'folder', parent_id: area.id, section: 'areas', kind: 'folder' });
  assert.deepEqual(scoped.items.map(item => item.id), [folder.id]);
  const beforeAppend = await call('read_text', { id: resource.id });
  const appendArgs = { id: resource.id, expected_revision: beforeAppend.revision, expected_body_hash: beforeAppend.body_hash, operation: 'append', text: '\nUnique tail', request_id: 'e2e-append' };
  const appended = await call('edit_text', appendArgs);
  assert.equal((await call('edit_text', appendArgs)).revision, appended.revision);
  assert.equal((await call('read_text', { id: resource.id })).text, 'Resource details\nUnique tail');
  const replaced = await call('edit_text', { id: resource.id, expected_revision: appended.revision, expected_body_hash: appended.body_hash, operation: 'replace', old_text: 'Unique tail', text: 'Changed tail', request_id: 'e2e-replace' });
  assert.equal(replaced.revision, appended.revision + 1);
  assert.equal((await call('read_text', { id: resource.id })).text, 'Resource details\nChanged tail');
  assert.equal((await client.callTool({ name: 'edit_text', arguments: { ...appendArgs, request_id: 'e2e-stale-append' } })).isError, true);
  const longText = '😀\n"'.repeat(10000);
  const longNote = await call('create_note', { title: 'MCP long text', parent_id: folder.id, text: longText, request_id: 'e2e-long' });
  let offset = 0, reconstructed = '', chunks = 0;
  do {
    const chunk = await call('read_text', { id: longNote.id, offset, length: 262144 });
    assert.ok(Buffer.byteLength(JSON.stringify(chunk)) <= 65536);
    assert.equal(chunk.offset, offset);
    assert.ok(chunk.text.length > 0);
    assert.equal(/[\uD800-\uDBFF]$/.test(chunk.text), false);
    reconstructed += chunk.text; chunks++;
    offset = chunk.next_offset;
  } while (offset !== null);
  assert.equal(reconstructed, longText); assert.ok(chunks > 1);
  const firstChunk = await call('read_text', { id: longNote.id });
  assert.ok(firstChunk.text.length <= 4001); assert.notEqual(firstChunk.next_offset, null);
  assert.equal((await client.callTool({ name: 'read_text', arguments: { id: longNote.id, offset: 1 } })).isError, true);
  await call('get_entry', { id: note.id }); await call('list_contexts');
  await call('get_links', { id: note.id, direction: 'incoming' });
  const task = await call('create_task', { title: 'MCP task', parent_id: project.id, state: 'next', request_id: 'e2e-task' });
  assert.equal(task.project_id, project.id);
  assert.equal((await call('list_tasks', { project_id: project.id })).total, 1);
  const updated = await call('update_task', { id: task.id, expected_revision: task.revision, energy: 'low', request_id: 'e2e-task-patch' });
  await call('set_task_state', { id: task.id, expected_revision: updated.revision, state: 'done', request_id: 'e2e-task-done' });
  assert.equal((await call('list_tasks', { state: 'done' })).total, 1);
  for (let i = 0; i < 21; i++) {
    await call('create_note', { title: `Page ${String(i).padStart(2, '0')}`, parent_id: folder.id, request_id: `e2e-page-${i}` });
  }
  const page = await call('list_entries', { parent_id: folder.id });
  assert.equal(page.items.length, 20); assert.equal(page.total, 22); assert.notEqual(page.next_cursor, null);
  const lastPage = await call('list_entries', { parent_id: folder.id, cursor: page.next_cursor });
  assert.equal(lastPage.items.length, 2); assert.equal(lastPage.next_cursor, null);
  assert.equal(new Set([...page.items, ...lastPage.items].map(item => item.id)).size, 22);
  process.stdout.write('MCP app end-to-end passed (19 tools).\n');
} finally { await client.close(); }
