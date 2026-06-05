# Declaw MCP Server

MCP server for [Declaw](https://declaw.ai) — secure sandbox execution for AI agents with network policies, PII scanning, prompt injection defense, and audit logging.

Works with Claude Desktop, Claude Code, Cursor, Windsurf, and any MCP-compatible AI tool.

## Quick Start

### Claude Desktop / Cursor / Windsurf

Add to your MCP config:

```json
{
  "mcpServers": {
    "declaw": {
      "command": "npx",
      "args": ["-y", "@declaw/mcp-server"],
      "env": {
        "DECLAW_API_KEY": "your-api-key"
      }
    }
  }
}
```

### Claude Code

```bash
claude mcp add declaw -- npx -y @declaw/mcp-server
```

Set `DECLAW_API_KEY` in your environment.

## Tools

| Tool | Description |
|------|-------------|
| `create_sandbox` | Create a secure sandbox with configurable security policies |
| `run_command` | Execute a shell command inside a sandbox |
| `read_file` | Read a file from a sandbox |
| `write_file` | Write a file to a sandbox |
| `list_files` | List directory contents in a sandbox |
| `kill_sandbox` | Destroy a sandbox |
| `list_sandboxes` | List all active sandboxes |

## Security Presets

When creating a sandbox, choose a security preset:

- **`none`** — No guardrails. Full internet access.
- **`standard`** (default) — PII scanning + audit logging. Full internet access.
- **`strict`** — PII scanning + prompt injection defense + audit logging + network deny-all.

You can also pass `allowed_domains` to restrict outbound traffic to specific domains:

```
create_sandbox with template="python", security_preset="strict", allowed_domains=["pypi.org", "github.com"]
```

## Why Declaw?

| | Declaw | Other Sandbox Providers |
|---|---|---|
| Sandbox execution | Yes | Yes |
| Non-bypassable network controls | Yes | No |
| PII scanning | Yes | No |
| Injection defense | Yes | No |
| Audit logging | Yes | No |
| Snapshots | Yes | Varies |
| Multiple templates | 8 built-in | Varies |
| Interactive stdio | Yes | Varies |

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `DECLAW_API_KEY` | Yes | Your Declaw API key |
| `DECLAW_DOMAIN` | No | Custom API domain (for on-prem deployments) |

## On-Prem

For self-hosted Declaw deployments, set the domain:

```json
{
  "mcpServers": {
    "declaw": {
      "command": "npx",
      "args": ["-y", "@declaw/mcp-server"],
      "env": {
        "DECLAW_API_KEY": "your-api-key",
        "DECLAW_DOMAIN": "declaw.internal.company.com"
      }
    }
  }
}
```

## License

Apache-2.0
