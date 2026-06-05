#!/usr/bin/env node

import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import { initConfig } from './util/config.js';
import { registerSandboxTools } from './tools/sandbox.js';
import { registerCommandTools } from './tools/commands.js';
import { registerFileTools } from './tools/files.js';

initConfig();

const server = new McpServer({
  name: 'declaw',
  version: '0.1.0',
});

registerSandboxTools(server);
registerCommandTools(server);
registerFileTools(server);

const transport = new StdioServerTransport();
await server.connect(transport);
