#!/usr/bin/env bash
# Instalador modular para Eza

REPO="$1"
BIN_DIR="$HOME/.local/bin"
TMP_DIR=$(mktemp -d)

ARCH=$(uname -m)
case "$ARCH" in
    x86_64) PATTERN="x86_64.*linux.*gnu.tar.gz" ;;
    aarch64) PATTERN="aarch64.*linux.*gnu.tar.gz" ;;
    *) echo "Arquitectura $ARCH no soportada para Eza"; exit 1 ;;
esac

URL=$(curl -s "https://api.github.com/repos/$REPO/releases/latest" | jq -r ".assets[] | select(.name | test(\"$PATTERN\")) | .browser_download_url" | head -n 1)

wget -qO "$TMP_DIR/eza.tar.gz" "$URL"
tar -xzf "$TMP_DIR/eza.tar.gz" -C "$TMP_DIR"

# Eza a veces se extrae directo o dentro de una carpeta, lo buscamos
find "$TMP_DIR" -type f -name "eza" -exec mv {} "$BIN_DIR/" \;
chmod +x "$BIN_DIR/eza"

rm -rf "$TMP_DIR"
