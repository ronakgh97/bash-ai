#!/usr/bin/env bash
set -e

INSTALL_DIR="$HOME/.local/bin"
TARGET="$INSTALL_DIR/spai"

if [ -f "$TARGET" ]; then
    rm -f "$TARGET"
    echo "🗑️ Removed $TARGET"
else
    echo "⚠️ spai not found in $INSTALL_DIR"
fi

# Ask to remove PATH entry
if grep -q 'export PATH="$HOME/.local/bin:$PATH"' "$HOME/.bashrc"; then
    echo -n "Do you want me to remove the PATH line from ~/.bashrc? (y/n) "
    read -r yn < /dev/tty
    case $yn in
        [Yy]* )
            sed -i '/export PATH="\$HOME\/.local\/bin:\$PATH"/d' "$HOME/.bashrc"
            echo "✅ PATH entry removed from ~/.bashrc. Restart your terminal."
            ;;
        * )
            echo " PATH entry left in ~/.bashrc"
            ;;
    esac
fi
