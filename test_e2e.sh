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
recv() { IFS= read -r -t 15 line <&4; printf '%s\n' "$line"; }

# Prints a tool call's result text; fails on a JSON-RPC error or isError.
tool_text() {
  python3 -c 'import json,sys
d = json.load(sys.stdin)
if "result" not in d: sys.exit("rpc error: %s" % d.get("error"))
t = d["result"]["content"][0]["text"]
if d["result"].get("isError"): sys.exit("tool error: %s" % t)
print(t)'
}

SBX_ID=""
cleanup() {
  # A failed step must not leave the sandbox running until its timeout.
  if [ -n "$SBX_ID" ]; then
    send "{\"jsonrpc\":\"2.0\",\"id\":99,\"method\":\"tools/call\",\"params\":{\"name\":\"kill_sandbox\",\"arguments\":{\"sandbox_id\":\"$SBX_ID\"}}}"
    recv >/dev/null || true
  fi
  exec 3>&- 4>&-
  kill "$MCP_PID" 2>/dev/null || true
  rm -f /tmp/mcp_in /tmp/mcp_out
}
trap cleanup EXIT

# Initialize
send '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}'
recv | python3 -c 'import json,sys; d=json.load(sys.stdin); print("INIT:", d["result"]["serverInfo"]["name"], d["result"]["serverInfo"]["version"])'

send '{"jsonrpc":"2.0","method":"notifications/initialized"}'

# Create sandbox
send '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"create_sandbox","arguments":{"template":"base","timeout":120,"security_preset":"standard"}}}'
CREATE=$(recv | tool_text)
SBX_ID=$(echo "$CREATE" | python3 -c 'import json,sys; print(json.load(sys.stdin)["sandbox_id"])')
echo "CREATE: $SBX_ID"

# Run command
send "{\"jsonrpc\":\"2.0\",\"id\":3,\"method\":\"tools/call\",\"params\":{\"name\":\"run_command\",\"arguments\":{\"sandbox_id\":\"$SBX_ID\",\"command\":\"echo hello-from-mcp\"}}}"
RUN=$(recv | tool_text)
echo "$RUN" | python3 -c 'import json,sys; r=json.load(sys.stdin); assert r["exit_code"] == 0 and r["stdout"].strip() == "hello-from-mcp", r; print("RUN: exit=%d stdout=%r" % (r["exit_code"], r["stdout"].strip()))'

# Write file
send "{\"jsonrpc\":\"2.0\",\"id\":4,\"method\":\"tools/call\",\"params\":{\"name\":\"write_file\",\"arguments\":{\"sandbox_id\":\"$SBX_ID\",\"path\":\"/tmp/mcp-test.txt\",\"content\":\"written via MCP server\"}}}"
WRITE=$(recv | tool_text)
echo "$WRITE" | python3 -c 'import json,sys; r=json.load(sys.stdin); assert r["written"] is True, r; print("WRITE:", r)'

# Read file
send "{\"jsonrpc\":\"2.0\",\"id\":5,\"method\":\"tools/call\",\"params\":{\"name\":\"read_file\",\"arguments\":{\"sandbox_id\":\"$SBX_ID\",\"path\":\"/tmp/mcp-test.txt\"}}}"
READ=$(recv | tool_text)
[ "$READ" = "written via MCP server" ] || { echo "READ: unexpected content: $READ" >&2; exit 1; }
echo "READ: '$READ'"

# List files
send "{\"jsonrpc\":\"2.0\",\"id\":6,\"method\":\"tools/call\",\"params\":{\"name\":\"list_files\",\"arguments\":{\"sandbox_id\":\"$SBX_ID\",\"path\":\"/tmp\"}}}"
LIST=$(recv | tool_text)
echo "$LIST" | python3 -c 'import json,sys; r=json.load(sys.stdin); names=[e["name"] for e in r["entries"]]; assert "mcp-test.txt" in names, names; print("LIST: %d entries" % len(names))'

# List sandboxes
send '{"jsonrpc":"2.0","id":7,"method":"tools/call","params":{"name":"list_sandboxes","arguments":{}}}'
LSBOX=$(recv | tool_text)
echo "$LSBOX" | SBX_ID="$SBX_ID" python3 -c 'import json,os,sys; r=json.load(sys.stdin); ids=[s["sandbox_id"] for s in r["sandboxes"]]; assert os.environ["SBX_ID"] in ids, ids; print("LIST_SANDBOXES: %d sandboxes" % r["count"])'

# Kill sandbox
send "{\"jsonrpc\":\"2.0\",\"id\":8,\"method\":\"tools/call\",\"params\":{\"name\":\"kill_sandbox\",\"arguments\":{\"sandbox_id\":\"$SBX_ID\"}}}"
KILL=$(recv | tool_text)
echo "$KILL" | python3 -c 'import json,sys; r=json.load(sys.stdin); assert r["killed"] is True, r; print("KILL:", r)'
SBX_ID=""

echo ""
echo "All 7 tools tested successfully!"
