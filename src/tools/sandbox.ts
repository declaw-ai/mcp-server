import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { Sandbox, createSecurityPolicy } from '@declaw/sdk';
import { CreateSandboxSchema, KillSandboxSchema, ListSandboxesSchema } from '../util/schemas.js';
import { getConnectionOpts } from '../util/config.js';

function buildSandboxOpts(
  preset: 'none' | 'standard' | 'strict',
  allowedDomains?: string[],
) {
  const result: Record<string, any> = {};

  if (preset !== 'none') {
    result.security = createSecurityPolicy({
      pii: { enabled: true, types: [], action: 'redact' as any, rehydrateResponse: false },
      injectionDefense: preset === 'strict',
      audit: true,
    });
  }

  if (allowedDomains && allowedDomains.length > 0) {
    result.network = { allowOut: allowedDomains };
  } else if (preset === 'strict') {
    result.network = { denyOut: ['0.0.0.0/0'] };
  }

  return result;
}

export function registerSandboxTools(server: McpServer) {
  server.tool(
    'create_sandbox',
    'Create a new secure sandbox environment. Returns a sandbox_id to use with other tools.',
    CreateSandboxSchema.shape,
    async (params) => {
      const opts = getConnectionOpts();
      const securityOpts = buildSandboxOpts(params.security_preset, params.allowed_domains);

      const sandbox = await Sandbox.create({
        template: params.template,
        timeout: params.timeout,
        envs: params.envs,
        ...securityOpts,
        ...opts,
      });

      return {
        content: [
          {
            type: 'text' as const,
            text: JSON.stringify({
              sandbox_id: sandbox.sandboxId,
              template: params.template,
              timeout: params.timeout,
              security_preset: params.security_preset,
            }),
          },
        ],
      };
    },
  );

  server.tool(
    'kill_sandbox',
    'Destroy a sandbox and release its resources.',
    KillSandboxSchema.shape,
    async (params) => {
      const opts = getConnectionOpts();
      const sandbox = await Sandbox.connect(params.sandbox_id, opts);
      const killed = await sandbox.kill();

      return {
        content: [
          {
            type: 'text' as const,
            text: JSON.stringify({ killed, sandbox_id: params.sandbox_id }),
          },
        ],
      };
    },
  );

  server.tool(
    'list_sandboxes',
    'List all active sandboxes for the current API key.',
    ListSandboxesSchema.shape,
    async () => {
      const opts = getConnectionOpts();
      const result = await Sandbox.list(opts);

      return {
        content: [
          {
            type: 'text' as const,
            text: JSON.stringify({
              count: result.sandboxes.length,
              sandboxes: result.sandboxes.map((s) => ({
                sandbox_id: s.sandboxId,
                template: s.templateId,
                name: s.name,
                state: s.state,
                started_at: s.startedAt?.toISOString(),
              })),
            }),
          },
        ],
      };
    },
  );
}
