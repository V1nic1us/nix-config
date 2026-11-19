#!/usr/bin/env bash
set -euo pipefail

if (( $# < 2 )); then
  printf 'Uso: install-progress.sh ARQUIVO_DE_LOG COMANDO [ARGUMENTOS...]\n' >&2
  exit 2
fi

log_file=$1
shift
started_at=${INSTALL_STARTED_AT:-$(date +%s)}
: > "$log_file"

elapsed_time() {
  local seconds=$(( $(date +%s) - started_at ))
  printf '%02d:%02d:%02d' "$((seconds / 3600))" "$(((seconds / 60) % 60))" "$((seconds % 60))"
}

count_items() {
  grep -Ec '^(copying path|building )' "$log_file" || true
}

show_progress() {
  local frame=0 bar position items
  while true; do
    bar=''
    for ((position = 0; position < 12; position++)); do
      if (( position >= frame && position < frame + 3 )); then
        bar+='#'
      else
        bar+='.'
      fi
    done
    items=$(count_items)
    printf '\r\033[K[%s] NixOS | Tempo: %s | %s itens do Nix' "$bar" "$(elapsed_time)" "$items"
    frame=$(((frame + 1) % 10))
    sleep 1
  done
}

progress_pid=''
stop_progress() {
  if [[ -n $progress_pid ]]; then
    kill "$progress_pid" 2>/dev/null || true
    wait "$progress_pid" 2>/dev/null || true
    progress_pid=''
    printf '\r\033[K'
  fi
}
trap stop_progress EXIT

if [[ -t 1 ]]; then
  show_progress &
  progress_pid=$!
fi

if "$@" > "$log_file" 2>&1; then
  status=0
else
  status=$?
fi

stop_progress
if (( status == 0 )); then
  printf 'Etapa NixOS concluída em %s; %s itens do Nix processados.\n' "$(elapsed_time)" "$(count_items)"
else
  printf 'Falha na instalação após %s. Consulte %s.\n' "$(elapsed_time)" "$log_file" >&2
fi
exit "$status"
