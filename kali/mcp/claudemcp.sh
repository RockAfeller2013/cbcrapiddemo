#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────
#  MetasploitMCP + Claude Code Auto-Installer
# ─────────────────────────────────────────────

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()    { echo -e "${GREEN}[+]${NC} $*"; }
warn()    { echo -e "${YELLOW}[!]${NC} $*"; }
die()     { echo -e "${RED}[-] ERROR:${NC} $*" >&2; exit 1; }

# ── 1. Validate required env vars FIRST ───────
: "${CLAUDE_API_KEY:?Set CLAUDE_API_KEY before running.}"
: "${MSF_PASSWORD:?Set MSF_PASSWORD before running (your msfrpcd password).}"

MSF_SERVER="${MSF_SERVER:-127.0.0.1}"
MSF_PORT="${MSF_PORT:-55553}"
MSF_SSL="${MSF_SSL:-false}"
INSTALL_DIR="${INSTALL_DIR:-${HOME}/tools/MetasploitMCP}"

# ── 2. Prerequisite checks ────────────────────
info "Checking prerequisites..."

command -v git  >/dev/null 2>&1 || die "git not found. Install git first."
command -v node >/dev/null 2>&1 || die "Node.js not found. Install from https://nodejs.org"
command -v npm  >/dev/null 2>&1 || die "npm not found. Install from https://nodejs.org"

# Python 3.10+
PYTHON=$(command -v python3 2>/dev/null || command -v python 2>/dev/null || true)
[[ -z "$PYTHON" ]] && die "Python 3 not found."
PY_VERSION=$("$PYTHON" -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
PY_MAJOR=$(echo "$PY_VERSION" | cut -d. -f1)
PY_MINOR=$(echo "$PY_VERSION" | cut -d. -f2)
(( PY_MAJOR < 3 || (PY_MAJOR == 3 && PY_MINOR < 10) )) && \
  die "Python 3.10+ required (found $PY_VERSION)."
info "Python $PY_VERSION ✓"

# ── 3. Install / verify uv ────────────────────
if ! command -v uv >/dev/null 2>&1; then
  info "Installing uv (Python package manager)..."
  pip install uv --break-system-packages 2>/dev/null || pip install uv
fi
info "uv ✓"

# ── 4. Install Claude Code ────────────────────
if ! command -v claude >/dev/null 2>&1; then
  info "Installing Claude Code..."
  npm install -g @anthropic-ai/claude-code
else
  info "Claude Code $(claude --version) already installed ✓"
fi

# ── 5. Write Claude Code config ───────────────
CLAUDE_CONFIG_DIR="${HOME}/.config/claude"
mkdir -p "${CLAUDE_CONFIG_DIR}"

info "Writing Claude Code config..."
cat > "${CLAUDE_CONFIG_DIR}/config.json" <<EOF
{
  "apiKey": "${CLAUDE_API_KEY}",
  "defaultModel": "claude-sonnet-4-6",
  "autoUpdate": true,
  "telemetry": false
}
EOF

# ── 6. Clone MetasploitMCP ────────────────────
if [[ -d "${INSTALL_DIR}/.git" ]]; then
  info "MetasploitMCP already cloned — pulling latest..."
  git -C "${INSTALL_DIR}" pull --ff-only
else
  info "Cloning MetasploitMCP into ${INSTALL_DIR}..."
  mkdir -p "$(dirname "${INSTALL_DIR}")"
  git clone https://github.com/GH05TCREW/MetasploitMCP.git "${INSTALL_DIR}"
fi

# ── 7. Create venv + install Python deps ─────
info "Setting up Python virtual environment..."
"$PYTHON" -m venv "${INSTALL_DIR}/.venv"
"${INSTALL_DIR}/.venv/bin/pip" install --upgrade pip -q
"${INSTALL_DIR}/.venv/bin/pip" install -r "${INSTALL_DIR}/requirements.txt" -q
info "Python dependencies installed ✓"

# ── 8. Write .env for the server ─────────────
info "Writing MetasploitMCP environment file..."
cat > "${INSTALL_DIR}/.env" <<EOF
MSF_PASSWORD=${MSF_PASSWORD}
MSF_SERVER=${MSF_SERVER}
MSF_PORT=${MSF_PORT}
MSF_SSL=${MSF_SSL}
PAYLOAD_SAVE_DIR=${HOME}/payloads
EOF
chmod 600 "${INSTALL_DIR}/.env"   # protect credentials

# ── 9. Register MCP server with Claude Code ──
info "Registering MetasploitMCP with Claude Code..."
claude mcp add-json "metasploit" \
  "$(cat <<JSON
{
  "command": "${INSTALL_DIR}/.venv/bin/python",
  "args": ["${INSTALL_DIR}/MetasploitMCP.py", "--transport", "stdio"],
  "env": {
    "MSF_PASSWORD": "${MSF_PASSWORD}",
    "MSF_SERVER":   "${MSF_SERVER}",
    "MSF_PORT":     "${MSF_PORT}",
    "MSF_SSL":      "${MSF_SSL}",
    "PAYLOAD_SAVE_DIR": "${HOME}/payloads"
  }
}
JSON
)"

# ── 10. Verify ────────────────────────────────
info "Verifying Claude Code installation..."
claude --version

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN} Installation complete!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo " Before using MetasploitMCP, start the RPC daemon:"
echo ""
echo -e "   ${YELLOW}msfrpcd -P \"\${MSF_PASSWORD}\" -S -a 127.0.0.1 -p 55553${NC}"
echo ""
echo " Then launch Claude Code:"
echo -e "   ${YELLOW}claude${NC}"
echo ""
warn "Only use against systems you have explicit written authorisation to test."
