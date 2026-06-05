import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { Sandbox } from '@declaw/sdk';
import { RunCommandSchema } from '../util/schemas.js';
import { getConnectionOpts } from '../util/config.js';

export function registerCommandTools(server: McpServer) {
  server.tool(
    'run_command',
    'Execute a shell command inside a sandbox. Returns stdout, stderr, and exit code.',
    RunCommandSchema.shape,
    async (params) => {
      const opts = getConnectionOpts();
      const sandbox = await Sandbox.connect(params.sandbox_id, opts);
      const result = await sandbox.commands.run(params.command, {
        timeout: params.timeout,
      });

      return {
        content: [
          {
            type: 'text' as const,
            text: JSON.stringify({
              exit_code: result.exitCode,
              stdout: result.stdout,
              stderr: result.stderr,
            }),
          },
        ],
      };
    },
  );
}
