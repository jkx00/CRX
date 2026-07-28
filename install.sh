#!/usr/bin/env bash
#
# install.sh - install crx + all dependency tools, then link `crx` to PATH.
# Idempotent: skips anything already installed.
#
set -e

R='\033[1;31m'; G='\033[1;32m'; Y='\033[1;33m'; B='\033[1;34m'; N='\033[0m'
log(){ echo -e "${B}[*]${N} $*"; }
ok(){ echo -e "${G}[+]${N} $*"; }
warn(){ echo -e "${Y}[!]${N} $*"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
have(){ command -v "$1" >/dev/null 2>&1; }

# --- PATH sanity ----------------------------------------------------------
GOBIN="$(go env GOPATH 2>/dev/null)/bin"
mkdir -p "$HOME/.local/bin" "$GOBIN" 2>/dev/null || true
export PATH="$GOBIN:$HOME/.local/bin:$PATH"

# --- Python venv for pip tools (uro) --------------------------------------
VENV="$HOME/.venv"
if [ ! -x "$VENV/bin/python3" ]; then
    log "Creating python venv at $VENV"
    python3 -m venv "$VENV"
fi

log "Installing Go tools (this can take a while on first run)..."
go_install(){
    local bin="$1" pkg="$2"
    have "$bin" && { ok "$bin already installed"; return; }
    log "go install $pkg"
    GO111MODULE=on go install "$pkg" && ok "$bin installed"
}
go_install nuclei      github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest
go_install httpx       github.com/projectdiscovery/httpx/cmd/httpx@latest
go_install subfinder   github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
go_install katana      github.com/projectdiscovery/katana/cmd/katana@latest
go_install dnsx        github.com/projectdiscovery/dnsx/cmd/dnsx@latest
go_install cdncheck    github.com/projectdiscovery/cdncheck/cmd/cdncheck@latest
go_install urlfinder   github.com/projectdiscovery/urlfinder/cmd/urlfinder@latest
go_install subzy       github.com/PentestPad/subzy@latest
go_install gau         github.com/lc/gau/v2/cmd/gau@latest
go_install hakrawler   github.com/hakluke/hakrawler@latest
go_install waybackurls github.com/tomnomnom/waybackurls@latest
go_install urldedupe   github.com/ameenmaali/urldedupe@latest

# --- pip tools (into venv, symlinked into ~/.local/bin) -------------------
log "Installing pip tools (uro, urless)..."
for pkg in uro urless; do
    if ! have "$pkg"; then
        "$VENV/bin/pip" install --quiet "$pkg" && \
        ln -sf "$VENV/bin/$pkg" "$HOME/.local/bin/$pkg" && ok "$pkg installed"
    else ok "$pkg already installed"; fi
done

# --- Corsy (git clone + wrapper) ------------------------------------------
if ! have corsy; then
    log "Installing Corsy..."
    mkdir -p "$HOME/tools"
    [ -d "$HOME/tools/Corsy" ] || git clone --depth 1 https://github.com/s0md3v/Corsy.git "$HOME/tools/Corsy"
    "$VENV/bin/pip" install --quiet requests
    cat > "$HOME/.local/bin/corsy" <<EOF
#!/usr/bin/env bash
exec "$VENV/bin/python3" "$HOME/tools/Corsy/corsy.py" "\$@"
EOF
    chmod +x "$HOME/.local/bin/corsy"
    ok "corsy installed"
else ok "corsy already installed"; fi

# --- WhatWeb (distro package) ---------------------------------------------
if ! have whatweb; then
    warn "whatweb not found. Install via your package manager, e.g.:"
    warn "  sudo pacman -S whatweb    # Arch/Garuda"
    warn "  sudo apt install whatweb  # Debian/Ubuntu"
fi

# --- Link crx to PATH -----------------------------------------------------
chmod +x "$SCRIPT_DIR/crx"
if ln -sf "$SCRIPT_DIR/crx" "$HOME/.local/bin/crx" 2>/dev/null; then
    ok "Linked crx -> $HOME/.local/bin/crx"
elif sudo ln -sf "$SCRIPT_DIR/crx" /usr/local/bin/crx 2>/dev/null; then
    ok "Linked crx -> /usr/local/bin/crx"
fi

echo
ok "Install complete. Ensure these are on your PATH:"
echo "    export PATH=\"$GOBIN:\$HOME/.local/bin:\$PATH\""
echo
ok "Run:  crx -d example.com"
