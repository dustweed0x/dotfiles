#!/usr/bin/env bash
# Instalador modular para Redial

REPO="$1"
BIN_DIR="$HOME/.local/bin"
TMP_DIR=$(mktemp -d)

ARCH=$(uname -m)
case "$ARCH" in
    x86_64) PATTERN="linux_amd64\.tar\.gz" ;; # Patrón estándar de Go/Rust para amd64
    aarch64) PATTERN="linux_arm64\.tar\.gz" ;;
    *) echo "Arquitectura $ARCH no soportada para Redial"; exit 1 ;;
esac

URL=$(curl -s "https://api.github.com/repos/$REPO/releases/latest" | jq -r ".assets[] | select(.name | test(\"(?i)$PATTERN\")) | .browser_download_url" | head -n 1)

if [[ -z "$URL" || "$URL" == "null" ]]; then 
    echo "Error obteniendo URL de Redial desde GitHub."; rm -rf "$TMP_DIR"; exit 1; 
fi

wget -qO "$TMP_DIR/redial.tar.gz" "$URL"
tar -xzf "$TMP_DIR/redial.tar.gz" -C "$TMP_DIR"

find "$TMP_DIR" -type f -name "redial" -exec mv {} "$BIN_DIR/" \;
chmod +x "$BIN_DIR/redial"

rm -rf "$TMP_DIR"
