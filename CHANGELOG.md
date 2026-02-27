# Changelog
Todos los cambios notables de este proyecto se documentarán en este archivo.

El formato está basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.0.0/),
y este proyecto se adhiere a [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-02-25
### 🚀 Añadido (Added)
- **Arquitectura Base**: Inicialización del repositorio modular `dotfiles` con separación lógica entre configuración (`configs/`), variables (`dotfiles.conf`), instaladores (`scripts/`) y temas (`themes/`).
- **Orquestador Principal (`install.sh`)**: Script Bash robusto con soporte interactivo y desatendido.
  - Opciones CLI: `--install`, `--update`, `--restore`, `--promote`, `--theme`, `--auto`.
  - Detección inteligente de OS (Debian/Ubuntu/RHEL/AlmaLinux) y Arquitectura de CPU (`x86_64`, `aarch64`).
  - Interfaz visual limpia con *spinners* de carga y volcado de errores a `install.log`.
- **Sistema de Backups Rotativos**: 
  - Creación de `ORIGINAL_STATE` en la primera ejecución.
  - Backups incrementales con *timestamp* (`YYYYMMDD_HHMMSS`) antes de modificar enlaces.
  - Módulo interactivo de Rollback (`--restore`) para regresar a configuraciones anteriores.
- **Inyección Dinámica de Temas (`set_theme.sh`)**: Motor basado en `jq` y `sed` que lee de `themes.json` e inyecta colores HEX en los archivos enlazados sin usar plantillas destructivas.
  - Temas iniciales incluidos: *Lovelace*, *Doom Peacock*, *Retrowave*.
- **Gestor de Binarios Modulares**: Scripts individuales en `scripts/tools/` que consultan la API de GitHub Releases para descargar la última versión y extraerla en `~/.local/bin/`.
  - Soportados: `zellij`, `starship`, `yazi`, `fastfetch`, `bat`, `eza`, `zoxide`, `redial`.
- **Promoción de Nodos (`--promote`)**: Utilidad para convertir un servidor remoto (lectura) en un entorno de origen (escritura Git) generando llaves SSH automáticamente.
- **Archivos de Configuración Incluidos**:
  - `zsh`: `.zshrc` limpio y estandarizado.
  - `zellij`: `config.kdl` y layout `bitcooking.kdl`.
  - `starship`: `starship.toml` adaptado a temas dinámicos.
  - `fastfetch`: `config.jsonc` y logo ASCII (`bitcoin_logo.txt`).
  - `yazi`: `theme.toml`.
  - `ssh`: Configuración de host base (`config`).
  - `windows-terminal`: Respaldos de `settings.json` y `bitcoin_logo.png` (en carpeta `assets/`).
- **Motor Genérico de Clonación Git (`GIT_CLONES`)**: Añadida una nueva matriz en la configuración para gestionar frameworks y plugins.
  - Soporta clonación inicial y actualizaciones (`git pull`) automáticas.
  - Instalación limpia de Oh My Zsh y sus plugins sin depender de scripts externos destructivos.

### 🔧 Modificado (Changed)
- **Estandarización de Rutas**: Los binarios manuales se movieron de `~/apps/` a `~/.local/bin/` para evitar problemas de permisos con `sudo`.
- **Rutas Absolutas**: Los recursos estáticos (ej. logos de Fastfetch) ahora apuntan a `~/.config/fastfetch/` en lugar de carpetas externas.
- **Generador de Scaffolding (`--add-tool`)**: Integrada la capacidad de generar autoinstaladores modulares para nuevos binarios de GitHub directamente desde el orquestador, inyectando código base con regex adaptable a arquitecturas y actualizando las variables globales automáticamente.
