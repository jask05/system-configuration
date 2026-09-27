#!/usr/bin/env bash
set -euo pipefail
source "${ROOT_DIR}/lib/common.sh"

if command_exists atuin; then
  ok "atuin ya está instalado ($(atuin --version 2>/dev/null || echo versión desconocida))"
  exit 0
fi

if is_dry_run; then
  info "ejecutaría: curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh"
  exit 0
fi

if ! confirm "Se va a descargar y ejecutar el instalador oficial de atuin (https://setup.atuin.sh). ¿Continuar?"; then
  warn "Instalación de atuin cancelada"
  exit 0
fi

curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh
ok "atuin instalado. El propio instalador añade su init a tu ~/.bashrc o ~/.zshrc: revisa esos ficheros tras esto."
