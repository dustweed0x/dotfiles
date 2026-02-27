#!/usr/bin/env bash
# Instalador modular para Starship
# Recibe: $1 (starship/starship) -> No se usa aquí porque usamos su script oficial.

BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"

# El flag -b le dice al script oficial que lo instale en nuestra carpeta sin usar sudo
curl -sS https://starship.rs/install.sh | sh -s -- -y -b "$BIN_DIR"
