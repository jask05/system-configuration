#!/usr/bin/env bash
# Entry point: menú interactivo (o selección directa por argumentos) para
# aplicar los módulos de este repo en la máquina actual.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export ROOT_DIR
# shellcheck source=lib/common.sh
source "${ROOT_DIR}/lib/common.sh"

DRY_RUN=0
ASSUME_YES=0
LIST_ONLY=0
SELECTED=()

usage() {
  cat <<EOF
Uso: ./install.sh [opciones] [módulos...]

Opciones:
  --dry-run       Muestra lo que haría sin modificar nada
  --yes, -y       No pedir confirmación
  --list          Lista los módulos disponibles y sale
  -h, --help      Esta ayuda

Si no se indican módulos, se muestra un menú interactivo.

Ejemplos:
  ./install.sh                     # menú interactivo
  ./install.sh --dry-run           # menú + simulación
  ./install.sh herdr claude-statusline   # instala directamente esos módulos
  ./install.sh -y herdr            # sin confirmaciones interactivas
EOF
}

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --yes|-y) ASSUME_YES=1 ;;
    --list) LIST_ONLY=1 ;;
    -h|--help) usage; exit 0 ;;
    -*) err "Opción desconocida: $arg"; usage; exit 1 ;;
    *) SELECTED+=("$arg") ;;
  esac
done
export DRY_RUN ASSUME_YES

mapfile -t MODULES < <(find "${ROOT_DIR}/modules" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort)

module_name() { basename "$1"; }
module_desc() {
  local f="$1/MODULE.md"
  if [ -f "$f" ]; then head -n1 "$f" | sed 's/^#\s*//'; else echo "(sin descripción)"; fi
}

if [ ${#MODULES[@]} -eq 0 ]; then
  err "No hay módulos en ${ROOT_DIR}/modules"
  exit 1
fi

if [ "$LIST_ONLY" = "1" ]; then
  for m in "${MODULES[@]}"; do
    printf '%-20s %s\n' "$(module_name "$m")" "$(module_desc "$m")"
  done
  exit 0
fi

if [ ${#SELECTED[@]} -eq 0 ]; then
  echo "Módulos disponibles:"
  i=1
  for m in "${MODULES[@]}"; do
    printf '  %d) %-20s %s\n' "$i" "$(module_name "$m")" "$(module_desc "$m")"
    i=$((i + 1))
  done
  echo
  read -r -p "Elige módulos (números separados por espacio, o 'all'): " choice
  if [ "$choice" = "all" ]; then
    for m in "${MODULES[@]}"; do SELECTED+=("$(module_name "$m")"); done
  else
    for n in $choice; do
      idx=$((n - 1))
      if [ "$idx" -ge 0 ] && [ "$idx" -lt "${#MODULES[@]}" ]; then
        SELECTED+=("$(module_name "${MODULES[$idx]}")")
      else
        warn "Ignorado número inválido: $n"
      fi
    done
  fi
fi

if [ ${#SELECTED[@]} -eq 0 ]; then
  warn "Nada seleccionado, saliendo."
  exit 0
fi

is_dry_run && info "MODO DRY-RUN: no se modificará nada"

for name in "${SELECTED[@]}"; do
  mod_dir="${ROOT_DIR}/modules/${name}"
  script="${mod_dir}/install.sh"
  if [ ! -f "$script" ]; then
    err "Módulo desconocido: ${name}"
    continue
  fi
  echo
  info "== módulo: ${name} =="
  export CURRENT_MODULE="$name"
  export MODULE_DIR="$mod_dir"
  bash "$script"
done

echo
ok "Hecho."
