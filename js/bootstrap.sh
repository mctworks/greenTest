#!/usr/bin/env bash
set -e

echo "Vanilla Compost GreenTest JS bootstrap"
echo "====================================="

# 1. Check Node.js and npm are installed
if ! which node >/dev/null 2>&1; then
    echo "node was not found on your system. Install it first:"
    echo "  macOS:   brew install node"
    echo "  Linux:   sudo apt install nodejs npm"
    echo "  Windows: https://nodejs.org/"
    exit 1
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
if ! which python >/dev/null 2>&1; then
    mkdir -p "$HOME/.local/bin"
    ln -sf "$(which python3)" "$HOME/.local/bin/python"
    echo "No 'python' command found - symlinked it to your verified python3 at $HOME/.local/bin/python"
    case ":$PATH:" in
        *":$HOME/.local/bin:"*) ;;
        *) echo "Note: add this to your shell profile (~/.bashrc, ~/.zshrc, etc.) so it's still there in new terminals:"
           echo "  export PATH=\"\$HOME/.local/bin:\$PATH\"" ;;
    esac
    export PATH="$HOME/.local/bin:$PATH"
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
if [ ! -f ".venv/bin/activate" ] && [ ! -f ".venv/Scripts/activate" ]; then
    echo "Creating a virtual environment for Jupyter at js/.venv..."
    if ! python -m venv .venv; then
        rm -rf .venv
        echo "Could not create a virtual environment. Install python3-venv."
        exit 1
    fi
fi

if [ -f ".venv/bin/activate" ]; then
    source ".venv/bin/activate"
else
    source ".venv/Scripts/activate"
fi

# 8. Install Jupyter inside venv
if ! python -m jupyter --version >/dev/null 2>&1; then
    echo "Jupyter not found. Installing it now (inside .venv)..."
    python -m pip install --quiet notebook
fi
echo "Jupyter is ready."

# 9. Launch the GreenTest notebook
echo "Starting greentest.ipynb..."
python -m jupyter notebook greentest.ipynb
