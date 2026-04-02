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
