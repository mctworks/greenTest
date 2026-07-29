#!/usr/bin/env bash
set -e

echo "Vanilla Compost GreenTest JS bootstrap"
echo "====================================="

# 1. Check Node.js and npm are installed - install via nvm (curl|bash, no
# sudo) if missing, rather than apt. nvm is more universal: it doesn't
# depend on a package manager being available or Debian's nodejs/npm
# packages being recent enough, and it needs no root.
export NVM_DIR="$HOME/.nvm"
# shellcheck disable=SC1091
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

if ! which node >/dev/null 2>&1; then
    echo "node not found - installing via nvm..."
    curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.5/install.sh | bash
    # shellcheck disable=SC1091
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
    nvm install --lts
fi
echo "Found Node.js $(node --version) at $(which node)"

if ! which npm >/dev/null 2>&1; then
    echo "npm was not found on your system. Please install Node.js with npm."
    exit 1
fi
echo "Found npm v$(npm --version) at $(which npm)"

# 2. Check Node version is >= 18.0.0
if ! node -e 'process.exit(parseInt(process.versions.node.split(".")[0]) >= 18 ? 0 : 1)'; then
    echo "This needs Node.js v18 or newer. Upgrade Node.js, then re-run this script."
    exit 1
fi

# 3. Check python3 is installed (needed to host the Jupyter Notebook)
if ! which python3 >/dev/null 2>&1; then
    echo "python3 is required to run the Jupyter Notebook. Install it first:"
    echo "  sudo apt install python3 python3-pip python3-venv"
    exit 1
fi
echo "Found $(python3 --version) at $(which python3)"

# 4. Handle python symlink if needed
# Persists $HOME/.local/bin on PATH for future shells (appends to ~/.bashrc,
# only if not already there) and exports it now so the rest of *this* script
# sees it immediately. Doesn't source ~/.bashrc - Debian's default one
# returns early for non-interactive shells (which is what this script is),
# so sourcing it here would be a no-op, not a real update.
ensure_path() {
    local dir="$1"
    case ":$PATH:" in
        *":$dir:"*) ;;
        *) export PATH="$dir:$PATH" ;;
    esac
    if ! grep -qxF "export PATH=\"$dir:\$PATH\"" "$HOME/.bashrc" 2>/dev/null; then
        echo "export PATH=\"$dir:\$PATH\"" >> "$HOME/.bashrc"
        echo "Added $dir to PATH in ~/.bashrc for future shells."
    fi
}

if ! which python >/dev/null 2>&1; then
    mkdir -p "$HOME/.local/bin"
    ln -sf "$(which python3)" "$HOME/.local/bin/python"
    echo "No 'python' command found - symlinked it to your verified python3 at $HOME/.local/bin/python"
    ensure_path "$HOME/.local/bin"
fi

# 5. Best-effort: compare Node version against latest release info from endoflife.date API
LATEST=$(node -e "
const https = require('https');
https.get('https://endoflife.date/api/nodejs.json', (res) => {
    let data = '';
    res.on('data', chunk => data += chunk);
    res.on('end', () => {
        try {
            console.log(JSON.parse(data)[0].latest);
        } catch(e) {}
    });
}).on('error', () => {});
" 2>/dev/null) || LATEST=""

if [ -n "$LATEST" ]; then
    echo "Latest stable Node.js release is $LATEST, for reference - not required."
fi

# 6. Check for pip
if ! python -m pip --version >/dev/null 2>&1; then
    echo "pip was not found for python. Try: python -m ensurepip --upgrade"
    exit 1
fi

cd "$(dirname "$0")"

# 7. Set up Python venv for Jupyter
if [ ! -f ".venv/bin/activate" ]; then
    echo "Creating a virtual environment for Jupyter at js/.venv..."
    if ! python -m venv .venv; then
        rm -rf .venv
        echo "Could not create a virtual environment. Install python3-venv:"
        echo "  sudo apt install python3-venv"
        exit 1
    fi
fi

source ".venv/bin/activate"

# 8. Install Jupyter inside venv
if ! python -m jupyter --version >/dev/null 2>&1; then
    echo "Jupyter not found. Installing it now (inside .venv)..."
    python -m pip install --quiet notebook
fi
echo "Jupyter is ready."

# 9. Launch the GreenTest notebook
echo "Starting greentest.ipynb..."
python -m jupyter notebook greentest.ipynb
