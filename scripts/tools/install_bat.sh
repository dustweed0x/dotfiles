#!/usr/bin/env bash
# Instalador modular para Bat

REPO="$1" # sharkdp/bat
BIN_DIR="$HOME/.local/bin"
TMP_DIR=$(mktemp -d)
ARCH=$(uname -m)

case "$ARCH" in
    x86_64) PATTERN="x86_64.*linux.*gnu.tar.gz" ;;
    aarch64) PATTERN="aarch64.*linux.*gnu.tar.gz" ;;
    *) echo "Arquitectura $ARCH no soportada para Bat"; exit 1 ;;
esac

URL=$(curl -s "https://api.github.com/repos/$REPO/releases/latest" | jq -r ".assets[] | select(.name | test(\"$PATTERN\")) | .browser_download_url" | head -n 1)

if [[ -z "$URL" || "$URL" == "null" ]]; then 
    echo "Error obteniendo URL de Bat"; rm -rf "$TMP_DIR"; exit 1; 
fi

wget -qO "$TMP_DIR/bat.tar.gz" "$URL"
tar -xzf "$TMP_DIR/bat.tar.gz" -C "$TMP_DIR"

# Mover el binario 'bat' de la ubicación esperada (generalmente dentro de la carpeta extraída)
# Esto asume que el binario está en la raíz del tar.gz o en un subdirectorio predecible.
# Si el binario está en un subdirectorio como 'bat-vX.Y.Z/bat', se necesitaría un 'find' más específico
mv "$TMP_DIR/bat" "$BIN_DIR/" || \
find "$TMP_DIR" -type f -name "bat" -exec mv {} "$BIN_DIR/" \; # Fallback si no está en la raíz

chmod +x "$BIN_DIR/bat" # Asegurarse de que el binario sea ejecutable

rm -rf "$TMP_DIR"
