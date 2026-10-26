import { homedir } from 'node:os';
import { isAbsolute, join } from 'node:path';

export function defaultConnectionPath(
  platform = process.platform,
  home = homedir(),
  environment = process.env,
) {
  if (platform === 'linux') {
    const state = environment.XDG_STATE_HOME;
    return join(state && isAbsolute(state) ? state : join(home, '.local', 'state'),
      'para-mcp', 'para-mcp-connection.json');
  }
  if (platform === 'darwin') {
    return join(home, 'Library', 'Containers', 'dev.para.paraWorkspace', 'Data',
      'Library', 'Application Support', 'para-mcp', 'para-mcp-connection.json');
  }
  throw new Error('Automatic MCP connection supports macOS and Linux only.');
}
