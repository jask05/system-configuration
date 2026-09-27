#!/usr/bin/env bash
set -euo pipefail
source "${ROOT_DIR}/lib/common.sh"

if ! command_exists herdr; then
  warn "herdr no está instalado en esta máquina."
  warn "Guía de instalación (pensada para que la siga un agente IA): https://herdr.dev/agent-guide.md"
  if ! confirm "¿Continuar solo para dejar preparado el config.toml?"; then
    exit 0
  fi
fi

ensure_copy "${MODULE_DIR}/config.toml" "${HOME}/.config/herdr/config.toml"

if command_exists herdr; then
  if is_dry_run; then
    info "ejecutaría: herdr integration install claude"
  else
    herdr integration install claude
    ok "integración de herdr con Claude Code instalada"
  fi
else
  warn "Cuando tengas herdr instalado, ejecuta: herdr integration install claude"
fi
