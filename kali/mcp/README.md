What the script does, step by step:

User:

```bash
export CLAUDE_API_KEY="sk-ant-..."
export MSF_PASSWORD="your_msf_password"

# Optional overrides:
# export MSF_SERVER="127.0.0.1"
# export MSF_PORT="55553"
# export INSTALL_DIR="${HOME}/tools/MetasploitMCP"

chmod +x install.sh && ./install.sh
```

- Validates env vars first — API key and MSF password must exist before anything is written to disk 
- Checks prerequisites — git, Node.js, npm, Python 3.10+
- Installs uv — required by MetasploitMCP's toolchain
- Installs Claude Code via npm if not already present
- Writes Claude Code config 
- Clones or updates MetasploitMCP
- Creates a isolated venv and installs Python dependencies (avoids the externally-managed-environment error seen on Kali/Debian)
- Writes a .env with chmod 600 to protect MSF credentials
- Registers the MCP server with Claude Code using claude mcp add-json so it's available immediately in-session
- Verifies the install and prints next steps


# AI Coding Tool Plans — MetasploitMCP Compatibility

| Plan | Cost | Usage / Limits | Claude Code Access | MetasploitMCP Compatible | Notes |
|---|---|---|---|---|---|
| **Free (Claude.ai)** | $0 | Limited daily messages | ❌ No | ❌ No | No terminal/MCP access |
| **Pro** | $20/mo ($17/mo annual) | ~45 prompts / 5hr window | ✅ Yes | ✅ Yes | Minimum plan for MetasploitMCP via Claude Code |
| **Max 5x** | $100/mo | 5× Pro usage | ✅ Yes | ✅ Yes | Better for long recon/exploit sessions |
| **Max 20x** | $200/mo | 20× Pro usage | ✅ Yes | ✅ Yes | Best for heavy continuous pentesting use |
| **API (pay-as-you-go)** | Usage-based | Unlimited (billed per token) | ✅ Yes | ✅ Yes | Script uses `CLAUDE_API_KEY` — most direct fit |
| **Gemini CLI** | $0 | 1,000 req/day | ✅ Yes (Gemini) | ⚠️ Partial | MCP supported but MetasploitMCP untested against it |
| **GitHub Copilot Free** | $0 | 2,000 completions/mo | ✅ Yes (Copilot) | ❌ No | No MCP support in free tier |
| **Codex CLI** | $0 (open source) | API costs apply | ✅ Yes (GPT) | ✅ Yes | Confirmed STDIO MCP support — MetasploitMCP uses STDIO transport, so it should work |
