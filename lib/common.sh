#!/usr/bin/env bash
# Helpers compartidos por install.sh y por cada modules/*/install.sh.
# Se espera que el caller haga `source "${ROOT_DIR}/lib/common.sh"`.

BACKUP_ROOT="${HOME}/.system-configuration-backups"

RED=$'\033[31m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'; BLUE=$'\033[34m'; RESET=$'\033[0m'

info() { printf '%s[info]%s %s\n' "$BLUE" "$RESET" "$*"; }
ok()   { printf '%s[ok]%s %s\n' "$GREEN" "$RESET" "$*"; }
warn() { printf '%s[warn]%s %s\n' "$YELLOW" "$RESET" "$*"; }
err()  { printf '%s[error]%s %s\n' "$RED" "$RESET" "$*" >&2; }

is_dry_run() { [ "${DRY_RUN:-0}" = "1" ]; }

command_exists() { command -v "$1" >/dev/null 2>&1; }

confirm() {
  local prompt="${1:-¿Continuar?}"
  [ "${ASSUME_YES:-0}" = "1" ] && return 0
  local reply
  read -r -p "$prompt [s/N] " reply
  case "$reply" in [sSyY]*) return 0 ;; *) return 1 ;; esac
}

# backup_file <path>: si existe, lo copia a BACKUP_ROOT antes de tocarlo.
backup_file() {
  local target="$1"
  [ -e "$target" ] || return 0
  local module="${CURRENT_MODULE:-misc}"
  local stamp dest
  stamp="$(date +%Y-%m-%d_%H%M%S)"
  dest="${BACKUP_ROOT}/${stamp}_${module}${target}"
  if is_dry_run; then
    info "backup (dry-run): ${target} -> ${dest}"
    return 0
  fi
  mkdir -p "$(dirname "$dest")"
  cp -a "$target" "$dest"
  ok "backup: ${target} -> ${dest}"
}

# ensure_copy <src> <dest> [mode]: backup de dest si existe, luego copia src -> dest.
ensure_copy() {
  local src="$1" dest="$2" mode="${3:-}"
  if is_dry_run; then
    info "copiar (dry-run): ${src} -> ${dest}"
    return 0
  fi
  backup_file "$dest"
  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest"
  [ -n "$mode" ] && chmod "$mode" "$dest"
  ok "copiado: ${dest}"
}

# merge_json_key <json_file> <key> <json_value_literal>: fusiona una clave de primer
# nivel en un JSON existente (lo crea si no existe), con backup previo.
merge_json_key() {
  local file="$1" key="$2" value="$3"
  if is_dry_run; then
    info "merge json (dry-run): ${file} .${key} = ${value}"
    return 0
  fi
  mkdir -p "$(dirname "$file")"
  [ -f "$file" ] || echo '{}' > "$file"
  backup_file "$file"
  if command_exists jq; then
    local tmp
    tmp="$(mktemp)"
    jq --argjson v "$value" ". + {\"${key}\": \$v}" "$file" > "$tmp" && mv "$tmp" "$file"
  else
    python3 - "$file" "$key" "$value" <<'PY'
import json, sys
path, key, value = sys.argv[1], sys.argv[2], sys.argv[3]
with open(path) as f:
    raw = f.read().strip()
data = json.loads(raw) if raw else {}
data[key] = json.loads(value)
with open(path, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
PY
  fi
  ok "actualizado: ${file} (.${key})"
}
