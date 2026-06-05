import { ConnectionConfig } from '@declaw/sdk';

let _apiKey: string | undefined;
let _domain: string | undefined;

export function initConfig() {
  _apiKey = process.env.DECLAW_API_KEY;
  _domain = process.env.DECLAW_DOMAIN;

  if (!_apiKey) {
    console.error('DECLAW_API_KEY environment variable is required');
    process.exit(1);
  }
}

export function getApiKey(): string {
  return _apiKey!;
}

export function getDomain(): string | undefined {
  return _domain;
}

export function getConnectionOpts(): { apiKey: string; domain?: string } {
  return { apiKey: _apiKey!, domain: _domain };
}
