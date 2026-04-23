#!/usr/bin/env bash
# Instalador modular para FZF

REPO="$1"
BIN_DIR="$HOME/.local/bin"

# Clonar el repositorio de fzf en una carpeta temporal para usar su script de instalación
git clone --depth 1 https://github.com/$REPO.git ~/.fzf
~/.fzf/install --bin --64 --no-update-rc --no-bash --no-fish

# Mover el binario al bin_dir y limpiar
mv ~/.fzf/bin/fzf "$BIN_DIR/"
rm -rf ~/.fzf
