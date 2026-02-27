# 🚀 Terminal Dotfiles & Environment Manager

![Bash](https://img.shields.io/badge/Script-Bash-4EAA25?style=for-the-badge&logo=gnu-bash&logoColor=white)
![Zsh](https://img.shields.io/badge/Shell-Zsh-1C2C3E?style=for-the-badge&logo=terminal&logoColor=white)
![Ubuntu](https://img.shields.io/badge/OS-Ubuntu%20%7C%20RHEL-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)
![Git](https://img.shields.io/badge/Version%20Control-Git-F05032?style=for-the-badge&logo=git&logoColor=white)

Un orquestador de *dotfiles* de grado profesional: modular, idempotente y altamente parametrizable. Diseñado para aprovisionar estaciones de trabajo de origen y servidores remotos en segundos. Todo el entorno es gestionado mediante enlaces simbólicos bidireccionales, inyección de temas dinámicos en tiempo real y descarga de binarios nativos auto-gestionados.

---

## ✨ Arquitectura y Detalles Técnicos

Este sistema se aleja de los scripts monolíticos tradicionales para adoptar una arquitectura de **Infraestructura como Código (IaC)** basada en Bash puro (cero dependencias previas):

- **🔄 Sincronización Bidireccional:** No utiliza plantillas destructivas (`.template`). Los archivos reales viven en `configs/` y se vinculan al sistema mediante `ln -s`. Cualquier cambio manual en la terminal se refleja inmediatamente en el repositorio, listo para un `git push`.
- **🎨 Inyección Dinámica de Temas (`sed` + `jq`):** El script `set_theme.sh` lee paletas de colores centralizadas desde un JSON (`themes.json`) e inyecta los valores hexadecimales directamente en los archivos enlazados de Starship, Zellij, Yazi y Zsh, mutando la interfaz al vuelo sin romper la estructura.
- **📦 Resolución Dinámica de Binarios (API GitHub):** Los instaladores modulares consultan la API de GitHub Releases (`/releases/latest`), resuelven la URL de descarga correcta mediante Expresiones Regulares (`regex`) adaptadas a la arquitectura local (`x86_64` vs `aarch64`/`arm64`) y extraen los binarios en `~/.local/bin/` sin requerir `sudo`.
- **🛡️ Sistema de Backups Inteligentes:**
  - **Estado Cero:** En la primera ejecución, salva el estado de fábrica de la máquina en `~/.dotfiles_backup/ORIGINAL_STATE/`.
  - **Incrementales:** Antes de cada actualización o sobreescritura, crea respaldos rotativos con marca de tiempo (`YYYYMMDD_HHMMSS`).
- **🧬 Motor de Scaffolding (`--add-tool`):** Capacidad de auto-programar nuevos módulos de instalación. El orquestador genera scripts de descarga en bash a partir de plantillas y auto-registra las nuevas herramientas en el archivo de configuración.

---

## ⚙️ Archivos de Configuración (El Cerebro)

El comportamiento completo del repositorio es controlado por dos archivos estáticos. **No necesitas modificar la lógica del código** para escalar el sistema.

### 1. `dotfiles.conf`
Archivo de variables Bash que define el estado deseado del sistema en cuatro matrices (arrays):
1. `SYSTEM_PACKAGES`: Lista de paquetes a instalar nativamente vía `apt` o `dnf` (ej. `zsh`, `jq`, `curl`, `ripgrep`).
2. `BINARIES`: Herramientas a compilar/descargar desde GitHub. Formato: `"nombre|usuario/repo"`.
3. `GIT_CLONES`: Repositorios a clonar directamente (ideal para frameworks como Oh My Zsh o plugins). Formato: `"ruta_destino_absoluta|usuario/repo"`.
4. `SYMLINKS`: Mapa de enlaces simbólicos. Formato: `"ruta_relativa_en_repo|ruta_absoluta_en_sistema"`.

### 2. `themes/themes.json`
Diccionario JSON que centraliza las paletas de colores. Para agregar un nuevo tema, simplemente añade un nuevo objeto con la propiedad `"name"` y sus códigos HEX. El instalador lo detectará automáticamente y lo agregará a los menús interactivos.

---

## 🛠️ CLI y Opciones del Orquestador (`install.sh`)

El archivo `install.sh` es el punto de entrada único.

| Comando / Flag | Descripción |
| :--- | :--- |
| `./install.sh` | **Instalación Interactiva.** (Por defecto). Muestra un menú visual leyendo `themes.json` y permite seleccionar herramientas específicas a instalar. |
| `./install.sh --auto` | **Despliegue Desatendido.** Omite preguntas, asume `yes` para todas las herramientas y aplica un tema por defecto. Ideal para aprovisionamiento automatizado (Cloud-Init, Ansible). |
| `./install.sh --update` | **Actualizador.** Ejecuta `git pull origin main`, actualiza paquetes del sistema, descarga nuevos releases de GitHub y sincroniza plugins. |
| `./install.sh --restore` | **Rollback.** Destruye los enlaces simbólicos del repo y te permite restaurar la configuración desde `ORIGINAL_STATE` o backups incrementales. |
| `./install.sh --promote` | **Convertir Nodo (Read-Only a Read-Write).** Configura `git config`, cambia la URL de origin de HTTPS a SSH, y genera/muestra llaves `ed25519` para autorizar el nodo en GitHub. |
| `./install.sh --theme "nombre"` | Aplica un tema específico saltándose el menú interactivo. (Ej: `./install.sh --auto --theme "Lovelace"`). |
| `./install.sh --add-tool "nombre" "user/repo"` | **Generador.** Crea automáticamente un script de instalación en `scripts/tools/` y registra la herramienta en `dotfiles.conf`. Acepta un 3er parámetro opcional para la extensión (ej. `zip`), por defecto es `tar.gz`. |

---

## 🔄 Flujos de Trabajo (Manual de Operaciones)

### A. Inicialización del Equipo Origen (Primer Setup)
Si tienes una máquina con configuraciones existentes que deseas convertir en el repositorio maestro:
1. Crea la estructura base y mueve tus archivos a `configs/`.
2. Crea los enlaces simbólicos de vuelta: `ln -s ~/dotfiles/configs/zsh/zshrc ~/.zshrc` (repite para cada archivo).
3. Inicializa git: `git init && git add . && git commit -m "Init" && git push -u origin main`

### B. Despliegue en Servidor Remoto Virgen
1. Clona vía HTTPS (solo lectura): `git clone https://github.com/TU_USUARIO/dotfiles.git ~/dotfiles`
2. Inicia la instalación: `cd ~/dotfiles && ./install.sh`
3. *Resultado:* Instala `zsh`, `jq`, clona OMZ, baja binarios a `~/.local/bin/`, enlaza configuraciones y aplica el tema.

### C. Agregar una NUEVA Herramienta y sus Configuraciones (Escalabilidad)
Supongamos que decides empezar a usar `fzf` (un buscador de terminal) y quieres que sus configuraciones sean parte permanente de tus *dotfiles* para todos tus servidores.

**Paso 1: Respaldar su configuración en el repo**
Mueve el archivo o carpeta de configuración que acabas de crear en tu equipo hacia el repositorio:
\`\`\`bash
mkdir -p ~/dotfiles/configs/fzf
mv ~/.config/fzf/fzf.conf ~/dotfiles/configs/fzf/fzf.conf
\`\`\`

**Paso 2: Enlazarlo en tu equipo local**
Conecta tu sistema de vuelta al archivo que ahora vive en el repo:
\`\`\`bash
ln -s ~/dotfiles/configs/fzf/fzf.conf ~/.config/fzf/fzf.conf
\`\`\`

**Paso 3: Registrar el enlace en tu Panel de Control**
Abre `~/dotfiles/dotfiles.conf` y añade la ruta a la matriz `SYMLINKS`:
\`\`\`bash
    "configs/fzf/fzf.conf|$HOME/.config/fzf/fzf.conf"
\`\`\`

**Paso 4: Automatizar su Instalación**
¿Cómo se instala esta herramienta?
- **Opción A (Paquete del Sistema):** Si se instala con `apt` o `dnf`, simplemente agrega `"fzf"` al array `SYSTEM_PACKAGES` dentro de `dotfiles.conf`.
- **Opción B (Binario de GitHub):** Si es un release de GitHub, usa el autogenerador. Ejecuta:
  \`\`\`bash
  ./install.sh --add-tool fzf junegunn/fzf
  \`\`\`
  *(Esto escribirá el script modular de descarga por ti y lo registrará en `dotfiles.conf` mágicamente).*

**Paso 5: Subir al repositorio**
Guarda la nueva herramienta en tu historial para que esté disponible globalmente:
\`\`\`bash
git add .
git commit -m "✨ Nueva herramienta añadida: fzf y sus configuraciones"
git push
\`\`\`
A partir de ahora, cuando vayas a cualquiera de tus servidores remotos y ejecutes `./install.sh --update`, el orquestador bajará el binario de `fzf` y creará los enlaces correspondientes automáticamente.

### D. Agregar un Nuevo Tema Visual
Si deseas agregar un esquema de color (ej. "Dracula"):
1. Abre `themes/themes.json`.
2. Añade un nuevo bloque de objeto JSON con `"name": "Dracula"` y todos los códigos hexadecimales requeridos (`background`, `foreground`, `cyan`, etc.).
3. Ejecuta `./install.sh --theme "Dracula"` para probarlo al instante. El menú interactivo de `--install` lo detectará automáticamente a partir de ahora.

### E. Restauración ante Desastres (Rollback)
Si una configuración rompe el sistema:
1. Ejecuta: `./install.sh --restore`
2. Selecciona la marca de tiempo a la cual deseas regresar. El sistema limpiará los enlaces de `~/dotfiles` y restaurará los archivos físicos originales a tus rutas de usuario.

### F. Desinstalación Completa
Para eliminar el ecosistema de *dotfiles* y regresar la máquina a su estado predeterminado:
1. Usa la opción de Rollback: `./install.sh --restore` y selecciona `ORIGINAL_STATE`.
2. Elimina la carpeta de binarios descargados: `rm -rf ~/.local/bin/` (opcional).
3. Elimina el repositorio: `rm -rf ~/dotfiles`

---

## 🚑 Solución de Problemas (Troubleshooting)

- **Error: `jq: command not found` antes del menú:**
  El script intenta instalar `jq` automáticamente. Si tu servidor no tiene acceso a los repositorios de `apt`/`dnf`, el menú fallará. Instala `jq` manualmente o revisa tu conexión.
- **Error: `Permission denied` al hacer `git push` en un remoto:**
  Estás en un servidor configurado como solo-lectura (HTTPS). Ejecuta `./install.sh --promote` para generar una llave SSH, cambiar el origen del repositorio remoto, y agrega esa llave a la configuración de tu cuenta de GitHub.
- **La barra de Zellij o Starship no muestra los iconos correctamente:**
  El instalador Linux no gestiona fuentes en la máquina cliente. Asegúrate de que el emulador de terminal que estás utilizando (Windows Terminal, iTerm2, Alacritty) tenga instalada y configurada una tipografía **Nerd Font** (ej. *DroidSansM Nerd Font*). Tienes respaldos de estas fuentes en la carpeta `assets/fonts/` del repositorio.
- **Un binario descargado de GitHub no se ejecuta (`Exec format error`):**
  La detección de arquitectura (`uname -m`) pudo fallar al coincidir con el *Regex* del script modular. Abre `scripts/tools/install_NOMBRE.sh` y ajusta la variable `PATTERN` para que coincida exactamente con el nombre de archivo que el desarrollador utiliza en GitHub Releases.

---

## 📁 Estructura del Directorio a Extremo Detalle

La jerarquía ha sido estrictamente diseñada para mantener el código (`scripts/`) separado de la configuración (`configs/`) y los datos parametrizados.

```text
dotfiles/
├── install.sh                  # Orquestador principal Bash (CLI, flujos, menús, logs).
├── set_theme.sh                # Motor de inyección dinámica (usa jq y sed).
├── dotfiles.conf               # [CONFIG] Arrays de control: paquetes, binarios, symlinks y clones.
├── CHANGELOG.md                # Registro histórico de versiones y cambios del sistema.
├── install.log                 # Archivo auto-generado con el volcado (stdout/stderr) de las instalaciones.
├── themes/                     
│   └── themes.json             # [DATA] Diccionario central con variables HEX de esquemas de color.
├── configs/                    # [CORE] Archivos reales de configuración (Enlazados al sistema).
│   ├── zsh/                    
│   │   └── zshrc               # Configuración central de Shell, alias y funciones cripto.
│   ├── zellij/                 
│   │   ├── config.kdl          # Configuración base del multiplexor.
│   │   └── layouts/            
│   │       └── bitcooking.kdl  # Interfaz predeterminada de paneles (ej. barra cripto inferior).
│   ├── starship/               
│   │   └── starship.toml       # Prompt universal, configurado para admitir paletas dinámicas.
│   ├── fastfetch/              
│   │   ├── config.jsonc        # Telemetría del sistema OS-aware.
│   │   └── bitcoin_logo.txt    # ASCII Art referenciado con ruta absoluta en jsonc.
│   ├── yazi/                   
│   │   └── theme.toml          # Estilización del explorador de archivos terminal.
│   └── ssh/                    
│       └── config              # Definiciones de host de red y bastiones.
├── scripts/                    # [LÓGICA] Motor del sistema.
│   ├── core/                   # Scripts administrativos internos.
│   │   └── add_tool.sh         # Generador de Scaffolding para automatizar modulos.
│   └── tools/                  # Recetas de descarga para binarios independientes (API GitHub).
│       ├── install_bat.sh      
│       ├── install_eza.sh      
│       ├── install_fastfetch.sh
│       ├── install_redial.sh   
│       ├── install_starship.sh 
│       ├── install_yazi.sh     
│       ├── install_zellij.sh   
│       └── install_zoxide.sh   
└── assets/                     # [CLIENTE] Archivos estáticos que NO se enlazan en sistemas Linux.
    ├── windows-terminal/       
    │   ├── settings.json       # Respaldo de perfiles para el cliente SSH (Host).
    │   └── bitcoin_logo.png    # Icono de perfil de terminal.
    └── fonts/                  
        └── *.ttf               # Respaldos de tipografías DroidSansM Nerd Font.
```
