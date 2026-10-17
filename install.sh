#!/usr/bin/env sh
# Install getproblem: dependencies + symlink into ~/.local/bin.
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
TARGET="$SCRIPT_DIR/getproblem"
BIN_DIR="${BIN_DIR:-$HOME/.local/bin}"
PY="${PYTHON:-python3}"

if ! command -v "$PY" >/dev/null 2>&1; then
    echo "error: '$PY' not found; set PYTHON=/path/to/python3" >&2
    exit 1
fi

if [ ! -f "$TARGET" ]; then
    echo "error: cannot find '$TARGET'" >&2
    exit 1
fi

echo "==> Installing Python dependencies (beautifulsoup4, curl_cffi)"
"$PY" -m pip install --user --upgrade beautifulsoup4
if ! "$PY" -m pip install --user --upgrade curl_cffi; then
    echo "warning: could not install curl_cffi; will fall back to requests." >&2
    echo "         Cloudflare may block some requests." >&2
fi

echo "==> Linking getproblem into $BIN_DIR"
mkdir -p "$BIN_DIR"
chmod +x "$TARGET"
ln -sf "$TARGET" "$BIN_DIR/getproblem"

case ":$PATH:" in
    *":$BIN_DIR:"*) ;;
    *)
        echo
        echo "warning: $BIN_DIR is not on your PATH."
        echo "Add this to your shell rc file (~/.bashrc or ~/.zshrc):"
        echo
        echo "    export PATH=\"$BIN_DIR:\$PATH\""
        ;;
esac

echo
echo "Done. Try it:"
echo "    getproblem 1831B && wl-paste | head"
