#!/usr/bin/env bash
# ==============================================================================
# DOTFILES INSTALLER & MANAGER
# Instalador interactivo, idempotente, modular y parametrizable.
# ==============================================================================

set -e
trap 'echo -e "\n\e[31m[✘] Error crítico en la línea $LINENO. Revisa install.log para detalles.\e[0m"; exit 1' ERR

# --- VARIABLES GLOBALES ---
DOTFILES_DIR="$HOME/dotfiles"
BACKUP_BASE="$HOME/.dotfiles_backup"
LOCAL_BIN="$HOME/.local/bin"
CONF_FILE="$DOTFILES_DIR/dotfiles.conf"
LOG_FILE="$DOTFILES_DIR/install.log"
THEMES_FILE="$DOTFILES_DIR/themes/themes.json"

# Limpiar log anterior
> "$LOG_FILE"

# --- DISEÑO UI (COLORES) ---
C_CYAN="\e[36m"
C_GREEN="\e[32m"
C_RED="\e[31m"
C_YELLOW="\e[33m"
C_PURPLE="\e[35m"
BOLD="\e[1m"
RESET="\e[0m"

function print_step() { echo -e "\n${C_CYAN}${BOLD}==>${RESET} ${BOLD}$1${RESET}"; }
function print_ok() { echo -e "  ${C_GREEN}[✔]${RESET} $1"; }
function print_info() { echo -e "  ${C_PURPLE}[ℹ]${RESET} $1"; }
function print_warn() { echo -e "  ${C_YELLOW}[!]${RESET} $1"; }
function print_error() { echo -e "  ${C_RED}[✘]${RESET} $1"; }

function run_with_spinner() {
    local msg="$1"
    shift
    echo -ne "  ${C_CYAN}[~]${RESET} $msg... "
    "$@" >> "$LOG_FILE" 2>&1 &
    local pid=$!
    local spin='-\|/'
    local i=0
    while kill -0 $pid 2>/dev/null; do
        i=$(( (i+1) %4 ))
        printf "\b${spin:$i:1}"
        sleep 0.1
    done
    wait $pid
    if [ $? -eq 0 ]; then
        printf "\b \b\r  ${C_GREEN}[✔]${RESET} $msg... Hecho.\n"
    else
        printf "\b \b\r  ${C_RED}[✘]${RESET} $msg... Error! (Revisa install.log)\n"
        exit 1
    fi
}

# --- HEADER VISUAL ---
clear
echo -e "${C_CYAN}${BOLD}"
echo "  ____        _    __ _ _           "
echo " |  _ \  ___ | |_ / _(_) | ___  ___ "
echo " | | | |/ _ \| __| |_| | |/ _ \/ __|"
echo " | |_| | (_) | |_|  _| | |  __/\__ \\"
echo " |____/ \___/ \__|_| |_|_|\___||___/"
echo -e "${RESET}\n    Inicializador Parametrizado v1.0\n"

# --- 1. FUNCIONES CORE (Backups y Promoción) ---

function do_backup() {
    local target="$1"
    if [[ -e "$target" && ! -L "$target" ]]; then
        if [[ ! -d "$BACKUP_BASE/ORIGINAL_STATE" ]]; then
            mkdir -p "$BACKUP_BASE/ORIGINAL_STATE"
            BACKUP_DIR="$BACKUP_BASE/ORIGINAL_STATE"
            print_warn "Guardando estado de fábrica en ORIGINAL_STATE/"
        else
            TIMESTAMP=$(date +%Y%m%d_%H%M%S)
            BACKUP_DIR="$BACKUP_BASE/$TIMESTAMP"
            mkdir -p "$BACKUP_DIR"
        fi
        mv "$target" "$BACKUP_DIR/"
    fi
}

function do_restore() {
    print_step "Modo Rollback (Restauración)"
    if [[ ! -d "$BACKUP_BASE" ]]; then print_error "No hay respaldos."; exit 1; fi
    
    select backup_dir in "$BACKUP_BASE"/* "Cancelar"; do
        if [[ "$backup_dir" == "Cancelar" ]]; then exit 0; fi
        if [[ -n "$backup_dir" ]]; then
            print_info "Restaurando desde $(basename "$backup_dir")..."
            for item in "${SYMLINKS[@]}"; do
                IFS='|' read -r _ dest_path <<< "$item"
                dest_path=$(eval echo "$dest_path")
                [[ -L "$dest_path" ]] && rm -f "$dest_path"
            done
            cp -r "$backup_dir/"* "$HOME/" 2>/dev/null || true
            print_ok "Restauración completada. Reinicia tu terminal."
            exit 0
        fi
    done
}

function do_promote() {
    print_step "Promover a Nodo Origen (Escritura Git)"
    read -p "Ingresa tu usuario de GitHub: " git_user
    read -p "Ingresa tu email de GitHub: " git_email
    
    git config --global user.name "$git_user"
    git config --global user.email "$git_email"
    cd "$DOTFILES_DIR" && git remote set-url origin "git@github.com:$git_user/dotfiles.git"
    
    if [[ ! -f "$HOME/.ssh/id_ed25519" ]]; then
        ssh-keygen -t ed25519 -C "$git_email" -f "$HOME/.ssh/id_ed25519" -N "" >/dev/null 2>&1
        print_ok "Llave SSH generada. Agrega esto a GitHub:"
        echo -e "${C_YELLOW}$(cat $HOME/.ssh/id_ed25519.pub)${RESET}"
    else
        print_info "Llave SSH ya existente."
    fi
    exit 0
}

function do_add_tool() {
    local tool_name="$1"
    local repo="$2"
    local ext="$3"
    local script_path="$DOTFILES_DIR/scripts/tools/install_${tool_name}.sh"

    print_step "Generando instalador modular para $tool_name..."
    
    mkdir -p "$DOTFILES_DIR/scripts/tools"

    # Generar el script con la plantilla inteligente
    cat << 'EOF' > "$script_path"
#!/usr/bin/env bash
# Instalador modular autogenerado para TOOL_NAME_PLACEHOLDER

REPO="$1"
BIN_DIR="$HOME/.local/bin"
TMP_DIR=$(mktemp -d)

ARCH=$(uname -m)
case "$ARCH" in
    x86_64) PATTERN="(x86_64|amd64).*linux.*EXT_PLACEHOLDER" ;;
    aarch64) PATTERN="(aarch64|arm64).*linux.*EXT_PLACEHOLDER" ;;
    *) echo "Arquitectura $ARCH no soportada para TOOL_NAME_PLACEHOLDER"; exit 1 ;;
esac

URL=$(curl -s "https://api.github.com/repos/$REPO/releases/latest" | jq -r ".assets[] | select(.name | test(\"(?i)\$PATTERN\")) | .browser_download_url" | head -n 1)

if [[ -z "$URL" || "$URL" == "null" ]]; then 
    echo "Error: No se encontró un asset compatible con \$PATTERN en GitHub."; rm -rf "$TMP_DIR"; exit 1; 
fi

wget -qO "$TMP_DIR/archivo.EXT_PLACEHOLDER" "$URL"

if [[ "EXT_PLACEHOLDER" == *"zip"* ]]; then
    unzip -q "$TMP_DIR/archivo.EXT_PLACEHOLDER" -d "$TMP_DIR"
else
    tar -xzf "$TMP_DIR/archivo.EXT_PLACEHOLDER" -C "$TMP_DIR"
fi

find "$TMP_DIR" -type f -name "TOOL_NAME_PLACEHOLDER" -exec mv {} "$BIN_DIR/" \;
chmod +x "$BIN_DIR/TOOL_NAME_PLACEHOLDER"

rm -rf "$TMP_DIR"
EOF

    # Reemplazar marcadores dinámicos
    sed -i "s/TOOL_NAME_PLACEHOLDER/$tool_name/g" "$script_path"
    sed -i "s/EXT_PLACEHOLDER/$ext/g" "$script_path"
    chmod +x "$script_path"
    print_ok "Script creado en: scripts/tools/install_${tool_name}.sh"

    # Inyectar en dotfiles.conf dinámicamente
    if grep -q "\"$tool_name|" "$CONF_FILE"; then
        print_warn "La herramienta '$tool_name' ya existe en dotfiles.conf. Omitiendo registro."
    else
        sed -i "/BINARIES=(/a \    \"$tool_name|$repo\"" "$CONF_FILE"
        print_ok "Herramienta '$tool_name' registrada en dotfiles.conf"
    fi
    
    echo -e "\n${C_GREEN}${BOLD}¡Herramienta añadida con éxito al ecosistema!${RESET}"
    exit 0
}

# --- 2. PRERREQUISITOS ---
print_step "Verificando sistema"

if [[ ! -f "$CONF_FILE" ]]; then
    print_error "Falta $CONF_FILE. Abortando."
    exit 1
fi
source "$CONF_FILE"

if ! ping -c 1 github.com &> /dev/null; then
    print_error "No hay conexión a Internet. Verifica tu red."
    exit 1
fi

print_info "Se requieren permisos administrativos (se pedirá clave una vez)."
sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

OS="$(uname -s)"
if [[ -f /etc/os-release ]]; then
    source /etc/os-release
    if [[ "$ID_LIKE" == *"debian"* ]] || [[ "$ID" == "debian" ]] || [[ "$ID" == "ubuntu" ]]; then
        PKG_INSTALL="sudo apt-get install -y"
        PKG_UPDATE="sudo apt-get update -y"
        PKG_CLEAN="sudo apt-get autoremove -y"
    elif [[ "$ID_LIKE" == *"rhel"* ]] || [[ "$ID" == "fedora" ]] || [[ "$ID" == "almalinux" ]]; then
        PKG_INSTALL="sudo dnf install -y"
        PKG_UPDATE="sudo dnf check-update || true"
        PKG_CLEAN="sudo dnf clean all"
    else
        print_error "Sistema Operativo no soportado."
        exit 1
    fi
fi
print_ok "Sistema detectado: $PRETTY_NAME"

run_with_spinner "Instalando dependencias core (jq, git)" eval "$PKG_UPDATE && $PKG_INSTALL jq git"

# --- 3. CONTROL DE PARÁMETROS (CLI FLAGS) ---
ACTION="install"
THEME_CHOICE=""
AUTO_MODE="false"

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --install) ACTION="install" ;;
        --update)  ACTION="update" ;;
        --restore) do_restore ;;
        --promote) do_promote ;;
        --theme)   THEME_CHOICE="$2"; shift ;;
        --auto)    AUTO_MODE="true" ;;
        --add-tool)
            # Validar que al menos envíe nombre y repo
            if [[ -z "$2" || -z "$3" || "$2" == --* || "$3" == --* ]]; then
                print_error "Uso: ./install.sh --add-tool <nombre> <usuario/repo> [extension]"
                exit 1
            fi
            TOOL_NAME="$2"
            REPO="$3"
            EXT="$4"
            # Asignar tar.gz por defecto si no se pasa la extensión
            if [[ -z "$EXT" || "$EXT" == --* ]]; then
                EXT="tar.gz"
                shift 2
            else
                shift 3
            fi
            do_add_tool "$TOOL_NAME" "$REPO" "$EXT"
            ;;
        *) print_error "Parámetro desconocido: $1"; exit 1 ;;
    esac
    shift
done

if [[ "$ACTION" == "update" ]]; then
    print_step "Actualizando Repositorio (--update)"
    cd "$DOTFILES_DIR" && run_with_spinner "Haciendo git pull origin main" git pull origin main
fi

# --- 4. MENÚS INTERACTIVOS Y MODO AUTO ---
declare -A TOOLS_TO_INSTALL

if [[ "$AUTO_MODE" == "false" ]]; then
    print_step "Configuración del Entorno"
    
    # Preguntar por el tema solo si no se pasó por --theme
    if [[ -z "$THEME_CHOICE" ]]; then
        echo -e "${BOLD}¿Qué tema deseas aplicar?${RESET}"
        readarray -t AVAILABLE_THEMES < <(jq -r '.[].name' "$THEMES_FILE")
        
        select theme_opt in "${AVAILABLE_THEMES[@]}"; do
            if [[ -n "$theme_opt" ]]; then
                THEME_CHOICE="$theme_opt"
                print_ok "Tema seleccionado: $THEME_CHOICE"
                break
            else
                echo "Opción inválida."
            fi
        done
    fi

    echo -e "\n${BOLD}¿Qué herramientas binarias deseas descargar? (s/n)${RESET}"
    for item in "${BINARIES[@]}"; do
        IFS='|' read -r tool_name repo_url <<< "$item"
        read -p "  Instalar $tool_name? (Y/n): " choice
        case "$choice" in 
            n|N ) print_warn "Omitido: $tool_name" ;;
            * ) TOOLS_TO_INSTALL["$tool_name"]="$repo_url"; print_ok "Marcado: $tool_name" ;;
        esac
    done
else
    # MODO AUTO: Sin interrupciones
    print_info "Modo Desatendido (--auto) activado."
    if [[ -z "$THEME_CHOICE" ]]; then
        THEME_CHOICE="Doom Peacock" # Tema por defecto si no se especificó otro
        print_info "Tema asignado por defecto: $THEME_CHOICE"
    fi
    for item in "${BINARIES[@]}"; do
        IFS='|' read -r tool_name repo_url <<< "$item"
        TOOLS_TO_INSTALL["$tool_name"]="$repo_url"
    done
fi

# --- 5. EJECUCIÓN DE INSTALACIÓN ---
print_step "Instalando Paquetes del Sistema"
for pkg in "${SYSTEM_PACKAGES[@]}"; do
    if ! command -v "$pkg" >/dev/null 2>&1; then
        run_with_spinner "Paquete: $pkg" eval "$PKG_INSTALL $pkg"
    else
        print_ok "Paquete: $pkg (Ya instalado)"
    fi
done

print_step "Descargando Herramientas Binarias"
mkdir -p "$LOCAL_BIN"
for tool in "${!TOOLS_TO_INSTALL[@]}"; do
    SCRIPT_PATH="$DOTFILES_DIR/scripts/tools/install_${tool}.sh"
    if [[ -x "$SCRIPT_PATH" ]]; then
        run_with_spinner "Instalando $tool" "$SCRIPT_PATH" "${TOOLS_TO_INSTALL[$tool]}"
    else
        print_warn "Falta o no tiene permisos de ejecución: scripts/tools/install_${tool}.sh"
    fi
done

print_step "Clonando Frameworks y Plugins (Git)"
for item in "${GIT_CLONES[@]}"; do
    IFS='|' read -r dest_path repo <<< "$item"
    dest_path=$(eval echo "$dest_path")
    
    if [[ ! -d "$dest_path" ]]; then
        run_with_spinner "Clonando $repo" git clone -q "https://github.com/$repo.git" "$dest_path"
    else
        # Si ya existe y estamos en modo update, lo actualizamos
        if [[ "$ACTION" == "update" ]]; then
            run_with_spinner "Actualizando $repo" git -C "$dest_path" pull -q
        else
            print_ok "$repo (Ya clonado)"
        fi
    fi
done

print_step "Enlazando Configuraciones"
for item in "${SYMLINKS[@]}"; do
    IFS='|' read -r repo_path dest_path <<< "$item"
    dest_path=$(eval echo "$dest_path")
    full_repo_path="$DOTFILES_DIR/$repo_path"
    
    mkdir -p "$(dirname "$dest_path")"
    do_backup "$dest_path"
    
    if [[ ! -L "$dest_path" ]]; then
        ln -s "$full_repo_path" "$dest_path"
        print_ok "Enlazado: $(basename "$dest_path")"
    fi
done

if [[ -n "$THEME_CHOICE" && -x "$DOTFILES_DIR/set_theme.sh" ]]; then
    print_step "Aplicando Tema"
    "$DOTFILES_DIR/set_theme.sh" "$THEME_CHOICE"
fi

print_step "Configuración Final"
run_with_spinner "Limpiando paquetes residuales" eval "$PKG_CLEAN"

if [[ "$SHELL" != *"/zsh" && -x "$(which zsh)" ]]; then
    sudo chsh -s "$(which zsh)" "$USER"
    print_ok "Shell por defecto cambiada a Zsh."
fi

echo -e "\n${C_GREEN}${BOLD}¡INSTALACIÓN COMPLETADA EXITOSAMENTE!${RESET}"
echo -e "Abre una nueva terminal o ejecuta: ${BOLD}exec zsh${RESET}\n"
