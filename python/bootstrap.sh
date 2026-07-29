#!/usr/bin/env bash
set -e

echo "Vanilla Compost GreenTest bootstrap"
echo "===================================="
# 0. Install basic tooling
sudo apt update && sudo apt install git curl wget python3 python3-pip python3-venv
# 1. Check python3 is installed
if ! which python3 >/dev/null 2>&1; then
    echo "python3 was not found on your system. Install it first:"
    echo "  sudo apt install python3 python3-pip python3-venv"
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
# system python directly. This isn't just tidiness: Debian/Ubuntu refuses
# "pip install" outside a venv on purpose (PEP 668,
# "externally-managed-environment") to stop exactly what installing straight
# into system python does. A venv sidesteps that entirely, instead of asking
# anyone to change how python itself is installed on a machine that already
# works fine for everything else.
if [ ! -f ".venv/bin/activate" ]; then
    echo "Creating a virtual environment at python/.venv..."
    if ! python -m venv .venv; then
        rm -rf .venv  # venv creates the directory before it can fail - don't leave a broken one behind
        echo "Could not create a virtual environment. This usually means:"
        echo "  sudo apt install python3-venv"
        exit 1
    fi
fi

source ".venv/bin/activate"

# 7. Check for / install Jupyter, inside the venv - this pip install is safe
# now regardless of how the system python outside the venv is managed.
if ! python -m jupyter --version >/dev/null 2>&1; then
    echo "Jupyter not found. Installing it now (inside .venv)..."
    python -m pip install --quiet notebook
fi
echo "Jupyter is ready."

# 8. Launch the GreenTest notebook
# echo "Starting greentest.ipynb..."
# python -m jupyter notebook greentest.ipynb
