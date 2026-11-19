#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
temporary_dir=$(mktemp -d)
trap 'rm -rf "$temporary_dir"' EXIT

cat > "$temporary_dir/work.sh" <<'EOF'
#!/usr/bin/env bash
printf 'copying path item-one\n'
sleep 2
printf 'building item-two\n' >&2
sleep 2
EOF

log_file=$temporary_dir/install.log
screen_output=$temporary_dir/screen.txt
timeout 10s script -q -e -c "bash '$repo_dir/scripts/install-progress.sh' '$log_file' bash '$temporary_dir/work.sh'" /dev/null > "$screen_output"

grep -q 'Tempo:' "$screen_output"
grep -q '2 itens do Nix' "$screen_output"
grep -q 'copying path item-one' "$log_file"
grep -q 'building item-two' "$log_file"

if bash "$repo_dir/scripts/install-progress.sh" "$log_file" bash -c 'printf "falhou\n" >&2; exit 23' > "$screen_output"; then
  printf 'O erro do comando foi ignorado.\n' >&2
  exit 1
else
  status=$?
fi
[[ $status -eq 23 ]]
grep -q 'falhou' "$log_file"

printf 'Teste do indicador de instalação: OK\n'
