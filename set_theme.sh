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
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEMES_FILE="$DOTFILES_DIR/themes/themes.json"

# Validar que jq esté instalado
if ! command -v jq >/dev/null 2>&1; then
    echo "[✘] Error: 'jq' no está instalado. Ejecuta ./install.sh primero."
    exit 1
fi

# Extraer todos los colores del JSON en una sola llamada
THEME_DATA=$(jq -r ".[] | select(.name==\"$THEME_NAME\")" "$THEMES_FILE")

if [[ -z "$THEME_DATA" || "$THEME_DATA" == "null" ]]; then
    echo "[✘] Error: No se encontró el tema '$THEME_NAME' en themes.json"
    exit 1
fi

BG=$(echo "$THEME_DATA" | jq -r ".background")
FG=$(echo "$THEME_DATA" | jq -r ".foreground")
ACCENT=$(echo "$THEME_DATA" | jq -r ".purple") # Tomamos el purple como acento según tu config anterior

echo "[ℹ] Aplicando tema: $THEME_NAME..."

# ------------------------------------------------------------------------------
# 1. ACTUALIZAR STARSHIP (starship.toml)
# Inyecta la paleta completa dinámicamente usando una marca de sección
# ------------------------------------------------------------------------------
STARSHIP_CONF="$DOTFILES_DIR/configs/starship/starship.toml"
if [[ -f "$STARSHIP_CONF" ]]; then
    # Cambiar el nombre de la paleta activa
    sed -i "s/palette = '.*/palette = '$THEME_NAME'/" "$STARSHIP_CONF"
    
    # Extraer colores individuales
    C_BLUE=$(echo "$THEME_DATA" | jq -r ".blue")
    C_BBLUE=$(echo "$THEME_DATA" | jq -r ".brightBlue")
    C_PURPLE=$(echo "$THEME_DATA" | jq -r ".purple")
    C_CYAN=$(echo "$THEME_DATA" | jq -r ".cyan")
    C_BLACK=$(echo "$THEME_DATA" | jq -r ".black")
    C_WHITE=$(echo "$THEME_DATA" | jq -r ".foreground")
    C_GREEN=$(echo "$THEME_DATA" | jq -r ".green")
    C_RED=$(echo "$THEME_DATA" | jq -r ".red")
    C_YELLOW=$(echo "$THEME_DATA" | jq -r ".yellow")
    C_BCYAN=$(echo "$THEME_DATA" | jq -r ".brightCyan")
    C_BPURPLE=$(echo "$THEME_DATA" | jq -r ".brightPurple")

    # Crear bloque de paleta
    PALETTE_BLOCK="[palettes.\"$THEME_NAME\"]\nbg_os      = '$C_BBLUE'\nbg_session = '$C_BLUE'\nbg_path    = '$C_PURPLE'\nbg_git     = '$C_CYAN'\ntext_dark  = '$C_BLACK'\ntext_light = '$C_WHITE'\nsuccess    = '$C_GREEN'\nerror      = '$C_RED'\nwarning    = '$C_YELLOW'\nlang_node  = '$C_GREEN'\nlang_py    = '$C_YELLOW'\nlang_go    = '$C_BCYAN'\ncloud      = '$C_BPURPLE'"

    # Cortar el archivo en la marca y añadir la nueva paleta
    sed -i '/# PALETA GENERADA (NO EDITAR MANUALMENTE)/q' "$STARSHIP_CONF"
    echo -e "$PALETTE_BLOCK" >> "$STARSHIP_CONF"
    
    echo "  [✔] Starship actualizado a $THEME_NAME (Paleta regenerada)"
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

# ------------------------------------------------------------------------------
# 4. ACTUALIZAR VS CODE (Opcional)
# ------------------------------------------------------------------------------
VSCODE_CONF="$DOTFILES_DIR/configs/vscode/settings.json"
if [[ -f "$VSCODE_CONF" && -f "$DOTFILES_DIR/.vscode_sync_enabled" ]]; then
    if [[ ! -s "$VSCODE_CONF" ]]; then echo "{}" > "$VSCODE_CONF"; fi
    
    TEMP_SETTINGS=$(jq --arg bg "$BG" --arg fg "$FG" --arg acc "$ACCENT" \
        '. + {"workbench.colorCustomizations": {
            "statusBar.background": $acc,
            "statusBar.foreground": "#ffffff",
            "terminal.background": $bg,
            "terminal.foreground": $fg,
            "activityBar.background": $bg
        }}' "$VSCODE_CONF")
    
    echo "$TEMP_SETTINGS" > "$VSCODE_CONF"
    echo "  [✔] VS Code actualizado con colores de $THEME_NAME"
else
    # Si estaba activado antes y ahora no, podemos limpiar si existe el archivo
    if [[ -f "$VSCODE_CONF" ]]; then
        # Solo lo limpiamos si el usuario borró el archivo de marca manualmente
        if [[ ! -f "$DOTFILES_DIR/.vscode_sync_enabled" ]]; then
             jq 'del(."workbench.colorCustomizations")' "$VSCODE_CONF" > "${VSCODE_CONF}.tmp" && mv "${VSCODE_CONF}.tmp" "$VSCODE_CONF"
        fi
    fi
fi

echo "[✔] ¡Tema inyectado con éxito! Reinicia tu terminal o ejecuta 'exec zsh' para ver los cambios."
