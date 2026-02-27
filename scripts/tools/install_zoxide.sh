#!/usr/bin/env bash
# Instalador modular para Zoxide

BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"

curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh -s -- -b "$BIN_DIR"
