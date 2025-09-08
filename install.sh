#!/usr/bin/env bash
set -e

INSTALL_DIR="$HOME/.local/bin"
TARGET="$INSTALL_DIR/spai"

mkdir -p "$INSTALL_DIR"
curl -fsSL "https://raw.githubusercontent.com/ronakgh97/bash-ai/master/src/spai.sh" -o "$TARGET"
chmod +x "$TARGET"

echo "✅ Installed spai to $TARGET"

# Check if ~/.local/bin is already in PATH
if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
    echo "⚠️  ~/.local/bin is not in your PATH."

    # Offer to add automatically
    echo -n "Do you want me to add it to ~/.bashrc for you? (y/n) "
    read -r yn
    case $yn in
        [Yy]* )
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
            echo "✅ Added to ~/.bashrc. Run 'source ~/.bashrc' or restart your terminal."
            ;;
        * )
            echo "Please add this line to your ~/.bashrc manually:"
            echo 'export PATH="$HOME/.local/bin:$PATH"'
            ;;
    esac
else
    echo "🎉 ~/.local/bin is already in your PATH. You can run 'spai' now!"
fi