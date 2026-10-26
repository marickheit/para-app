import test from 'node:test';
import assert from 'node:assert/strict';
import { defaultConnectionPath } from '../dist/connection-path.js';

test('automatic Linux discovery follows XDG and ignores relative or empty values', () => {
  const home = '/home/test';
  for (const XDG_STATE_HOME of ['', 'relative', undefined]) {
    assert.equal(defaultConnectionPath('linux', home, { XDG_STATE_HOME }),
      '/home/test/.local/state/para-mcp/para-mcp-connection.json');
  }
  assert.equal(defaultConnectionPath('linux', home, { XDG_STATE_HOME: '/tmp/private-state' }),
    '/tmp/private-state/para-mcp/para-mcp-connection.json');
});

test('automatic macOS discovery uses the stable sandbox container and handles spaces', () => {
  assert.equal(defaultConnectionPath('darwin', '/Users/Example User', {}),
    '/Users/Example User/Library/Containers/dev.para.paraWorkspace/Data/Library/Application Support/para-mcp/para-mcp-connection.json');
  assert.throws(() => defaultConnectionPath('win32', '/home/test', {}));
});
