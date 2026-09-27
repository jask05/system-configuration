#!/usr/bin/env bash
set -euo pipefail
source "${ROOT_DIR}/lib/common.sh"

TARGET="${HOME}/.claude/statusline.sh"

ensure_copy "${MODULE_DIR}/statusline.sh" "$TARGET" 755
merge_json_key "${HOME}/.claude/settings.json" "statusLine" \
  '{"type":"command","command":"~/.claude/statusline.sh"}'
