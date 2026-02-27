#!/usr/bin/env bash
# ==============================================================================
# THEME INJECTOR
# Lee de themes.json y aplica modificaciones a los archivos de configuración
# ==============================================================================

if [[ -z "$1" ]]; then
    echo "Uso: ./set_theme.sh \"Nombre del Tema\""
    exit 1
fi

THEME_NAME="$1"
DOTFILES_DIR="$HOME/dotfiles"
THEMES_FILE="$DOTFILES_DIR/themes/themes.json"

# Validar que jq esté instalado
if ! command -v jq >/dev/null 2>&1; then
    echo "[✘] Error: 'jq' no está instalado. Ejecuta ./install.sh primero."
    exit 1
fi

# Extraer colores del JSON (Ejemplos)
BG=$(jq -r ".[] | select(.name==\"$THEME_NAME\") | .background" "$THEMES_FILE")
FG=$(jq -r ".[] | select(.name==\"$THEME_NAME\") | .foreground" "$THEMES_FILE")
ACCENT=$(jq -r ".[] | select(.name==\"$THEME_NAME\") | .purple" "$THEMES_FILE") # Tomamos el purple como acento según tu config anterior

if [[ -z "$BG" || "$BG" == "null" ]]; then
    echo "[✘] Error: No se encontró el tema '$THEME_NAME' en themes.json"
    exit 1
fi

echo "[ℹ] Aplicando tema: $THEME_NAME..."

# ------------------------------------------------------------------------------
# 1. ACTUALIZAR STARSHIP (starship.toml)
# Asume que en tu starship.toml hay una línea exacta: palette = 'lo_que_sea'
# ------------------------------------------------------------------------------
STARSHIP_CONF="$DOTFILES_DIR/configs/starship/starship.toml"
if [[ -f "$STARSHIP_CONF" ]]; then
    # Cambiar el nombre de la paleta activa
    sed -i "s/palette = '.*/palette = '$THEME_NAME'/" "$STARSHIP_CONF"
    echo "  [✔] Starship actualizado a $THEME_NAME"
fi

# ------------------------------------------------------------------------------
# 2. ACTUALIZAR ZELLIJ (config.kdl)
# Asume que tienes: theme "lo_que_sea"
# ------------------------------------------------------------------------------
ZELLIJ_CONF="$DOTFILES_DIR/configs/zellij/config.kdl"
if [[ -f "$ZELLIJ_CONF" ]]; then
    sed -i "s/theme \".*/theme \"$THEME_NAME\"/" "$ZELLIJ_CONF"
    echo "  [✔] Zellij actualizado a $THEME_NAME"
fi

# ------------------------------------------------------------------------------
# 3. ACTUALIZAR SCRIPT DE ZSH (Tu barra Crypto en .zshrc)
# Podemos inyectar el código Hex directamente si configuramos el .zshrc para leerlo
# ------------------------------------------------------------------------------
ZSHRC_CONF="$DOTFILES_DIR/configs/zsh/zshrc"
if [[ -f "$ZSHRC_CONF" ]]; then
    # Busca la variable C_ETH= y le inyecta el nuevo color
    sed -i "s/C_ETH=\"\\\e\[38;2;.*m\"/C_ETH=\"\\\e\[38;2;$(echo "$ACCENT" | sed 's/#//')m\"/" "$ZSHRC_CONF"
    echo "  [✔] Colores de barra Zsh actualizados"
fi

echo "[✔] ¡Tema inyectado con éxito! Reinicia tu terminal o ejecuta 'exec zsh' para ver los cambios."
