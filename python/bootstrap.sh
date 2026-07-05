#!/usr/bin/env bash
set -e

echo "Vanilla Compost GreenTest bootstrap"
echo "===================================="

# 1. Check python3 is installed
if ! which python3 >/dev/null 2>&1; then
    echo "python3 was not found on your system. Install it first:"
    echo "  macOS:   brew install python3   (or https://www.python.org/downloads/)"
    echo "  Linux:   sudo apt install python3 python3-pip python3-venv   (or your distro's equivalent)"
    echo "  Windows: https://www.python.org/downloads/ (check 'Add python.exe to PATH' during install)"
    exit 1
fi
echo "Found $(python3 --version) at $(which python3)"

# 2. Check the version found is new enough (the notebook uses f-strings, Python 3.6+)
if ! python3 -c 'import sys; sys.exit(0 if sys.version_info >= (3, 6) else 1)'; then
    echo "This needs Python 3.6 or newer. Upgrade python3, then re-run this script."
    exit 1
fi

# 3. This machine's python3 is confirmed installed and a supported version. If
# there's no bare 'python' command, symlink it to this verified python3 rather
# than requiring one to already exist - many systems (Debian/Ubuntu especially)
# don't ship 'python' by default.
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

# 4. Best-effort: compare against the latest known release (informational only,
# never blocks - if there's no network or the API is unreachable, just skip it)
LATEST=$(curl -s --max-time 5 "https://endoflife.date/api/python.json" 2>/dev/null \
    | python -c "import json,sys
try:
    print(json.load(sys.stdin)[0]['latest'])
except Exception:
    pass" 2>/dev/null) || LATEST=""
if [ -n "$LATEST" ]; then
    echo "Latest stable Python release is $LATEST, for reference - not required."
fi

# 5. Check for pip
if ! python -m pip --version >/dev/null 2>&1; then
    echo "pip was not found for this python. Try this, then re-run this script:"
    echo "  python -m ensurepip --upgrade"
    exit 1
fi

cd "$(dirname "$0")"

# 6. Set up a virtual environment for Jupyter, rather than installing into the
# system python directly. This isn't just tidiness: modern Debian/Ubuntu (and
# similar) refuse "pip install" outside a venv on purpose (PEP 668,
# "externally-managed-environment") to stop exactly what installing straight
# into system python does. A venv sidesteps that entirely and behaves the same
# way on Windows/macOS/Linux, instead of asking anyone to change how python
# itself is installed on a machine that already works fine for everything else.
if [ ! -f ".venv/bin/activate" ] && [ ! -f ".venv/Scripts/activate" ]; then
    echo "Creating a virtual environment at python/.venv..."
    if ! python -m venv .venv; then
        rm -rf .venv  # venv creates the directory before it can fail - don't leave a broken one behind
        echo "Could not create a virtual environment. On Debian/Ubuntu this usually means:"
        echo "  sudo apt install python3-venv"
        exit 1
    fi
fi

if [ -f ".venv/bin/activate" ]; then
    source ".venv/bin/activate"
else
    source ".venv/Scripts/activate"
fi

# 7. Check for / install Jupyter, inside the venv - this pip install is safe
# now regardless of how the system python outside the venv is managed.
if ! python -m jupyter --version >/dev/null 2>&1; then
    echo "Jupyter not found. Installing it now (inside .venv)..."
    python -m pip install --quiet notebook
fi
echo "Jupyter is ready."

# 8. Launch the GreenTest notebook
echo "Starting greentest.ipynb..."
python -m jupyter notebook greentest.ipynb
