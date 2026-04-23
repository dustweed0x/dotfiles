#!/usr/bin/env bash
# Instalador modular para Yazi

REPO="$1" # Ej: sxyazi/yazi
BIN_DIR="$HOME/.local/bin"
TMP_DIR=$(mktemp -d)
ARCH=$(uname -m)

case "$ARCH" in
    x86_64) PATTERN="x86_64.*linux.*gnu.zip" ;;
    aarch64) PATTERN="aarch64.*linux.*gnu.zip" ;;
    *) echo "Arquitectura $ARCH no soportada para Yazi"; exit 1 ;;
esac

# 2. Consultar API de GitHub por el último release
URL=$(curl -s "https://api.github.com/repos/$REPO/releases/latest" | jq -r ".assets[] | select(.name | test(\"$PATTERN\")) | .browser_download_url" | head -n 1)

if [[ -z "$URL" ]]; then echo "Error obteniendo URL de Yazi"; exit 1; fi

# 3. Descargar, descomprimir y mover
wget -qO "$TMP_DIR/yazi.zip" "$URL"
unzip -q "$TMP_DIR/yazi.zip" -d "$TMP_DIR"

# Mover los binarios 'yazi' y 'ya' de la ubicación esperada
mv "$TMP_DIR/yazi" "$BIN_DIR/" || find "$TMP_DIR" -type f -name "yazi" -exec mv {} "$BIN_DIR/" \;
mv "$TMP_DIR/ya" "$BIN_DIR/" || find "$TMP_DIR" -type f -name "ya" -exec mv {} "$BIN_DIR/" \;

chmod +x "$BIN_DIR/yazi" "$BIN_DIR/ya"

# 4. Limpieza
rm -rf "$TMP_DIR"
