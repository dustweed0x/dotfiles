#!/usr/bin/env bash
# Instalador modular para Zellij

REPO="$1"
BIN_DIR="$HOME/.local/bin"
TMP_DIR=$(mktemp -d)

ARCH=$(uname -m)
case "$ARCH" in
    x86_64) PATTERN="x86_64.*linux.*tar.gz" ;;
    aarch64) PATTERN="aarch64.*linux.*tar.gz" ;;
    *) echo "Arquitectura $ARCH no soportada para Zellij"; exit 1 ;;
esac

URL=$(curl -s "https://api.github.com/repos/$REPO/releases/latest" | jq -r ".assets[] | select(.name | test(\"$PATTERN\")) | .browser_download_url" | head -n 1)

wget -qO "$TMP_DIR/zellij.tar.gz" "$URL"
tar -xzf "$TMP_DIR/zellij.tar.gz" -C "$TMP_DIR"

mv "$TMP_DIR/zellij" "$BIN_DIR/"
chmod +x "$BIN_DIR/zellij"

rm -rf "$TMP_DIR"
