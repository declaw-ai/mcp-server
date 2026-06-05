import { z } from 'zod';

export const CreateSandboxSchema = z.object({
  template: z
    .string()
    .default('base')
    .describe('Sandbox template: base, python, node, code-interpreter, ai-agent, mcp-server, web-dev, devops'),
  timeout: z
    .number()
    .min(10)
    .max(86400)
    .default(300)
    .describe('Sandbox timeout in seconds (default: 300)'),
  security_preset: z
    .enum(['none', 'standard', 'strict'])
    .default('standard')
    .describe(
      'Security preset. "none": no guardrails. "standard": PII scanning + audit logging. "strict": PII + injection defense + audit + network deny-all.',
    ),
  allowed_domains: z
    .array(z.string())
    .optional()
    .describe('Domain allowlist for outbound network access (e.g. ["pypi.org", "github.com"]). Overrides network deny-all.'),
  envs: z
    .record(z.string())
    .optional()
    .describe('Environment variables to set in the sandbox'),
});

export const RunCommandSchema = z.object({
  sandbox_id: z.string().describe('Sandbox ID returned by create_sandbox'),
  command: z.string().describe('Shell command to execute'),
  timeout: z
    .number()
    .min(1)
    .max(3600)
    .default(30)
    .describe('Command timeout in seconds (default: 30)'),
});

export const ReadFileSchema = z.object({
  sandbox_id: z.string().describe('Sandbox ID'),
  path: z.string().describe('Absolute file path to read'),
});

export const WriteFileSchema = z.object({
  sandbox_id: z.string().describe('Sandbox ID'),
  path: z.string().describe('Absolute file path to write'),
  content: z.string().describe('File content to write'),
});

export const ListFilesSchema = z.object({
  sandbox_id: z.string().describe('Sandbox ID'),
  path: z.string().default('/').describe('Directory path to list (default: /)'),
});

export const KillSandboxSchema = z.object({
  sandbox_id: z.string().describe('Sandbox ID to destroy'),
});

export const ListSandboxesSchema = z.object({});
