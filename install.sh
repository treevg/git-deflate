#!/usr/bin/env bash
set -e

# install.sh: Installs or symlinks git-deflate into ~/.local/bin (or custom path).

INSTALL_DIR="${INSTALL_DIR:-$HOME/.local/bin}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_FILE="$SCRIPT_DIR/git-deflate"
TARGET_LINK="$INSTALL_DIR/git-deflate"

show_help() {
  cat << EOF
Usage: ./install.sh [options]

Installs git-deflate to your system PATH ($INSTALL_DIR).

Options:
  --copy        Copy the script instead of creating a symlink.
  --uninstall   Remove git-deflate from $INSTALL_DIR.
  -h, --help    Show this help message.
EOF
}

UNINSTALL=false
USE_COPY=false

for arg in "$@"; do
  case $arg in
    --uninstall)
      UNINSTALL=true
      ;;
    --copy)
      USE_COPY=true
      ;;
    -h|--help)
      show_help
      exit 0
      ;;
    *)
      echo "Unknown option: $arg"
      show_help
      exit 1
      ;;
  esac
done

if [ "$UNINSTALL" = true ]; then
  echo "Uninstalling git-deflate from $INSTALL_DIR..."
  rm -f "$TARGET_LINK"
  echo "git-deflate uninstalled successfully."
  exit 0
fi

if [ ! -f "$SOURCE_FILE" ]; then
  echo "Error: Source script not found at $SOURCE_FILE" >&2
  exit 1
fi

mkdir -p "$INSTALL_DIR"
chmod +x "$SOURCE_FILE"

if [ "$USE_COPY" = true ]; then
  echo "Copying git-deflate to $TARGET_LINK..."
  cp "$SOURCE_FILE" "$TARGET_LINK"
else
  echo "Symlinking git-deflate to $TARGET_LINK..."
  ln -sf "$SOURCE_FILE" "$TARGET_LINK"
fi

chmod +x "$TARGET_LINK"

echo ""
echo "=== Installation Successful! ==="
echo "Installed: $TARGET_LINK"

case ":$PATH:" in
  *":$INSTALL_DIR:"*)
    echo "PATH check: $INSTALL_DIR is in your PATH."
    ;;
  *)
    echo "Warning: $INSTALL_DIR is NOT in your PATH."
    echo "Add the following line to your ~/.zshrc or ~/.bashrc:"
    echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
    ;;
esac

echo "You can now run 'git deflate' in any Git repository!"
