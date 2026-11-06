set -euo pipefail

if [[ $# -ne 1 || -z ${1:-} ]]; then
  echo "usage: rex-sync <ssh-host>" >&2
  exit 2
fi

host=$1
config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/rex"
files=(
  init.lua
  actions/init.lua
  actions/pi_split.lua
  actions/swap_next_pane.lua
  font-fit.lua
  display-info.js
  focus-font-fit.lua
)

for file in "${files[@]}"; do
  if [[ ! -r $config_dir/$file ]]; then
    echo "rex-sync: missing $config_dir/$file; run darwin-rebuild first" >&2
    exit 1
  fi
done

printf 'Syncing Rex config to %s\n' "$host"
ssh "$host" 'mkdir -p "$HOME/.config/rex/actions"'
tar -C "$config_dir" -cf - "${files[@]}" |
  ssh "$host" 'tar -C "$HOME/.config/rex" -xf -'
ssh "$host" bash -s <<'EOF'
set -e
rex config check "$HOME/.config/rex/init.lua"
if [ -S /run/rex/server.sock ]; then
  rex -S unix:///run/rex/server.sock config reload
else
  rex config reload
fi
EOF
