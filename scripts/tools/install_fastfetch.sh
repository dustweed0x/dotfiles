#!/usr/bin/env bash
# Instalador modular para Fastfetch

REPO="$1" # fastfetch-cli/fastfetch
BIN_DIR="$HOME/.local/bin"
TMP_DIR=$(mktemp -d)
ARCH=$(uname -m)

case "$ARCH" in
    x86_64) PATTERN="linux-amd64.tar.gz" ;;
    aarch64) PATTERN="linux-aarch64.tar.gz" ;;
    *) echo "Arquitectura $ARCH no soportada para Fastfetch"; exit 1 ;;
esac

# Obtener URL del último release
URL=$(curl -s "https://api.github.com/repos/$REPO/releases/latest" | jq -r ".assets[] | select(.name | test(\"$PATTERN\")) | .browser_download_url" | head -n 1)

if [[ -z "$URL" || "$URL" == "null" ]]; then 
    echo "Error obteniendo URL de Fastfetch"; rm -rf "$TMP_DIR"; exit 1; 
fi

# Descargar y extraer
wget -qO "$TMP_DIR/fastfetch.tar.gz" "$URL"
tar -xzf "$TMP_DIR/fastfetch.tar.gz" -C "$TMP_DIR"

# Mover el binario 'fastfetch' (suele venir dentro de una carpeta usr/bin/ o similar)
mv "$TMP_DIR/usr/bin/fastfetch" "$BIN_DIR/" || \
mv "$TMP_DIR/fastfetch" "$BIN_DIR/" || \
find "$TMP_DIR" -type f -name "fastfetch" -exec mv {} "$BIN_DIR/" \; # Fallback
chmod +x "$BIN_DIR/fastfetch"

# Limpieza
rm -rf "$TMP_DIR"
