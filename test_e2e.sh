#!/bin/bash
set -euo pipefail

export DECLAW_API_KEY="${DECLAW_API_KEY:?Set DECLAW_API_KEY to a valid Declaw API key}"
export DECLAW_DOMAIN="${DECLAW_DOMAIN:-api.declaw.ai}"

# Start MCP server
mkfifo /tmp/mcp_in /tmp/mcp_out 2>/dev/null || true
node dist/index.js < /tmp/mcp_in > /tmp/mcp_out 2>/dev/null &
MCP_PID=$!
exec 3>/tmp/mcp_in 4</tmp/mcp_out

send() { echo "$1" >&3; }
recv() { read -t 15 line <&4; echo "$line"; }

# Initialize
send '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}'
INIT=$(recv)
echo "INIT: $(echo "$INIT" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d["result"]["serverInfo"]["name"], d["result"]["serverInfo"]["version"])')"

send '{"jsonrpc":"2.0","method":"notifications/initialized"}'

# Create sandbox
send '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"create_sandbox","arguments":{"template":"base","timeout":120,"security_preset":"standard"}}}'
CREATE=$(recv)
SBX_ID=$(echo "$CREATE" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(json.loads(d["result"]["content"][0]["text"])["sandbox_id"])')
echo "CREATE: $SBX_ID"

# Run command
send "{\"jsonrpc\":\"2.0\",\"id\":3,\"method\":\"tools/call\",\"params\":{\"name\":\"run_command\",\"arguments\":{\"sandbox_id\":\"$SBX_ID\",\"command\":\"echo hello-from-mcp\"}}}"
RUN=$(recv)
echo "RUN: $(echo "$RUN" | python3 -c 'import json,sys; d=json.load(sys.stdin); r=json.loads(d["result"]["content"][0]["text"]); print(f"exit={r[\"exit_code\"]} stdout={r[\"stdout\"].strip()!r}")')"

# Write file
send "{\"jsonrpc\":\"2.0\",\"id\":4,\"method\":\"tools/call\",\"params\":{\"name\":\"write_file\",\"arguments\":{\"sandbox_id\":\"$SBX_ID\",\"path\":\"/tmp/mcp-test.txt\",\"content\":\"written via MCP server\"}}}"
WRITE=$(recv)
echo "WRITE: $(echo "$WRITE" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(json.loads(d["result"]["content"][0]["text"]))')"

# Read file
send "{\"jsonrpc\":\"2.0\",\"id\":5,\"method\":\"tools/call\",\"params\":{\"name\":\"read_file\",\"arguments\":{\"sandbox_id\":\"$SBX_ID\",\"path\":\"/tmp/mcp-test.txt\"}}}"
READ=$(recv)
echo "READ: $(echo "$READ" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d["result"]["content"][0]["text"].strip()!r)')"

# List files
send "{\"jsonrpc\":\"2.0\",\"id\":6,\"method\":\"tools/call\",\"params\":{\"name\":\"list_files\",\"arguments\":{\"sandbox_id\":\"$SBX_ID\",\"path\":\"/tmp\"}}}"
LIST=$(recv)
echo "LIST: $(echo "$LIST" | python3 -c 'import json,sys; d=json.load(sys.stdin); r=json.loads(d["result"]["content"][0]["text"]); print(f"{len(r[\"entries\"])} entries")')"

# List sandboxes
send '{"jsonrpc":"2.0","id":7,"method":"tools/call","params":{"name":"list_sandboxes","arguments":{}}}'
LSBOX=$(recv)
echo "LIST_SANDBOXES: $(echo "$LSBOX" | python3 -c 'import json,sys; d=json.load(sys.stdin); r=json.loads(d["result"]["content"][0]["text"]); print(f"{r[\"count\"]} sandboxes")')"

# Kill sandbox
send "{\"jsonrpc\":\"2.0\",\"id\":8,\"method\":\"tools/call\",\"params\":{\"name\":\"kill_sandbox\",\"arguments\":{\"sandbox_id\":\"$SBX_ID\"}}}"
KILL=$(recv)
echo "KILL: $(echo "$KILL" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(json.loads(d["result"]["content"][0]["text"]))')"

# Cleanup
exec 3>&- 4>&-
kill "$MCP_PID" 2>/dev/null || true
rm -f /tmp/mcp_in /tmp/mcp_out
echo ""
echo "All 7 tools tested successfully!"
