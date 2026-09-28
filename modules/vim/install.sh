#!/usr/bin/env bash
set -euo pipefail
source "${ROOT_DIR}/lib/common.sh"

VIMRC_DEST="${HOME}/.vimrc"
# El vimrc manda undo/swap/backup a estos directorios: si no existen, Vim no
# guarda el historial de deshacer y deja los .swp junto al fichero.
VIM_DIRS=("${HOME}/.vim/undo" "${HOME}/.vim/swap" "${HOME}/.vim/backup")

# --- check previo: ¿está vim en esta máquina? -------------------------------
if command_exists vim; then
  ok "vim ya está instalado ($(vim --version 2>/dev/null | head -n1))"
else
  warn "vim no está instalado en esta máquina."
  if command_exists apt-get; then
    PKG_CMD="sudo apt-get update && sudo apt-get install -y vim"
  elif command_exists dnf; then
    PKG_CMD="sudo dnf install -y vim-enhanced"
  elif command_exists brew; then
    PKG_CMD="brew install vim"
  else
    PKG_CMD=""
  fi

  if [ -z "$PKG_CMD" ]; then
    warn "No reconozco el gestor de paquetes: instala vim a mano. Copio igualmente la config."
  elif is_dry_run; then
    info "ejecutaría: ${PKG_CMD}"
  elif confirm "¿Instalar vim con '${PKG_CMD}'?"; then
    bash -c "$PKG_CMD"
    ok "vim instalado"
  else
    warn "Instalación de vim cancelada. Copio igualmente la config."
  fi
fi

# --- configuración ----------------------------------------------------------
ensure_copy "${MODULE_DIR}/vimrc" "$VIMRC_DEST"

for d in "${VIM_DIRS[@]}"; do
  if is_dry_run; then
    info "crearía: ${d}"
  else
    mkdir -p "$d"
  fi
done
is_dry_run || ok "directorios creados: ~/.vim/{undo,swap,backup}"

# En un VPS sin entorno gráfico Vim suele venir sin +clipboard: la opción
# clipboard=unnamed no falla, simplemente no tiene efecto.
if command_exists vim && ! vim --version 2>/dev/null | grep -q '+clipboard'; then
  info "este vim no tiene +clipboard: yank/put no llegarán al portapapeles del sistema (normal en un VPS)"
fi
