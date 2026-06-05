import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { Sandbox } from '@declaw/sdk';
import { ReadFileSchema, WriteFileSchema, ListFilesSchema } from '../util/schemas.js';
import { getConnectionOpts } from '../util/config.js';

export function registerFileTools(server: McpServer) {
  server.tool(
    'read_file',
    'Read a text file from a sandbox.',
    ReadFileSchema.shape,
    async (params) => {
      const opts = getConnectionOpts();
      const sandbox = await Sandbox.connect(params.sandbox_id, opts);
      const content = await sandbox.files.read(params.path);

      return {
        content: [{ type: 'text' as const, text: content }],
      };
    },
  );

  server.tool(
    'write_file',
    'Write text content to a file in a sandbox. Creates parent directories automatically.',
    WriteFileSchema.shape,
    async (params) => {
      const opts = getConnectionOpts();
      const sandbox = await Sandbox.connect(params.sandbox_id, opts);
      await sandbox.files.write(params.path, params.content);

      return {
        content: [
          {
            type: 'text' as const,
            text: JSON.stringify({ written: true, path: params.path }),
          },
        ],
      };
    },
  );

  server.tool(
    'list_files',
    'List files and directories at a given path in a sandbox.',
    ListFilesSchema.shape,
    async (params) => {
      const opts = getConnectionOpts();
      const sandbox = await Sandbox.connect(params.sandbox_id, opts);
      const entries = await sandbox.files.list(params.path);

      return {
        content: [
          {
            type: 'text' as const,
            text: JSON.stringify({
              path: params.path,
              entries: entries.map((e) => ({
                name: e.name,
                type: e.type,
              })),
            }),
          },
        ],
      };
    },
  );
}
