#!/usr/bin/env bash
set -euo pipefail
source "${ROOT_DIR}/lib/common.sh"

HERDR_INSTALLER="https://herdr.dev/install.sh"
CONFIG_DEST="${HOME}/.config/herdr/config.toml"

# --- check previo: ¿está herdr en esta máquina? -----------------------------
if command_exists herdr; then
  HERDR_PRESENT=1
  ok "herdr ya está instalado ($(herdr --version 2>/dev/null || echo 'versión desconocida'))"
else
  HERDR_PRESENT=0
  warn "herdr no está instalado en esta máquina."
fi

# --- qué quiere hacer el usuario -------------------------------------------
# Por defecto: si ya está instalado, solo configurar; si no, instalar y configurar.
if [ "$HERDR_PRESENT" = "1" ]; then DEFAULT_ACTION="2"; else DEFAULT_ACTION="3"; fi

if [ "${ASSUME_YES:-0}" = "1" ]; then
  ACTION="$DEFAULT_ACTION"
  info "modo -y: usando la acción por defecto (${DEFAULT_ACTION})"
else
  echo
  echo "¿Qué quieres hacer con herdr?"
  if [ "$HERDR_PRESENT" = "1" ]; then
    echo "  1) Instalar    — reinstalar/actualizar el binario (instalador oficial)"
  else
    echo "  1) Instalar    — descargar el binario (instalador oficial)"
  fi
  echo "  2) Configurar  — config.toml + integración con Claude Code"
  echo "  3) Ambos"
  read -r -p "Elige [1/2/3] (por defecto ${DEFAULT_ACTION}): " reply
  ACTION="${reply:-$DEFAULT_ACTION}"
fi

case "$ACTION" in
  1|i|instalar)   DO_INSTALL=1; DO_CONFIG=0 ;;
  2|c|configurar) DO_INSTALL=0; DO_CONFIG=1 ;;
  3|a|ambos)      DO_INSTALL=1; DO_CONFIG=1 ;;
  *) err "Opción no válida: ${ACTION}"; exit 1 ;;
esac

# --- instalación ------------------------------------------------------------
if [ "$DO_INSTALL" = "1" ]; then
  if [ "$HERDR_PRESENT" = "1" ] && [ "$DO_CONFIG" = "1" ]; then
    info "herdr ya está instalado: me salto la instalación"
  elif is_dry_run; then
    info "ejecutaría: curl -fsSL ${HERDR_INSTALLER} | sh"
  elif confirm "Se va a descargar y ejecutar el instalador oficial de herdr (${HERDR_INSTALLER}). ¿Continuar?"; then
    curl -fsSL "$HERDR_INSTALLER" | sh
    hash -r 2>/dev/null || true
    if command_exists herdr; then
      HERDR_PRESENT=1
      ok "herdr instalado ($(herdr --version 2>/dev/null || echo 'versión desconocida'))"
    else
      warn "El instalador terminó pero 'herdr' no está en el PATH: abre una shell nueva o revisa ~/.local/bin."
    fi
  else
    warn "Instalación de herdr cancelada"
  fi
fi

# --- configuración ----------------------------------------------------------
if [ "$DO_CONFIG" = "1" ]; then
  ensure_copy "${MODULE_DIR}/config.toml" "$CONFIG_DEST"

  if [ "$HERDR_PRESENT" = "1" ]; then
    if is_dry_run; then
      info "ejecutaría: herdr integration install claude"
    else
      herdr integration install claude
      ok "integración de herdr con Claude Code instalada"
    fi
  else
    warn "Sin el binario no puedo registrar la integración."
    warn "Cuando tengas herdr instalado, ejecuta: herdr integration install claude"
    warn "Guía de instalación (pensada para que la siga un agente IA): https://herdr.dev/agent-guide.md"
  fi
fi
