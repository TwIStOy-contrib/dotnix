set -euo pipefail

if [[ $# -ne 1 || -z ${1:-} ]]; then
  echo "usage: rex-sync <ssh-host>" >&2
  exit 2
fi

host=$1
config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/rex"
hs_dir="$HOME/.hammerspoon"
files=(
  init.lua
  actions/init.lua
  actions/pi_split.lua
  actions/swap_next_pane.lua
  font-fit.lua
  display-info.js
)

for file in "${files[@]}"; do
  if [[ ! -r $config_dir/$file ]]; then
    echo "rex-sync: missing $config_dir/$file; run darwin-rebuild first" >&2
    exit 1
  fi
done
if [[ ! -r $hs_dir/focus-font-fit.lua ]]; then
  echo "rex-sync: missing $hs_dir/focus-font-fit.lua; run darwin-rebuild first" >&2
  exit 1
fi

printf 'Syncing Rex config to %s\n' "$host"
ssh "$host" 'mkdir -p "$HOME/.config/rex/actions" "$HOME/.hammerspoon"'
tar -C "$config_dir" -cf - "${files[@]}" |
  ssh "$host" 'tar -C "$HOME/.config/rex" -xf -'
# focus-font-fit.lua is an hs-side script and lives in ~/.hammerspoon/.
tar -C "$hs_dir" -cf - focus-font-fit.lua |
  ssh "$host" 'tar -C "$HOME/.hammerspoon" -xf -'
ssh "$host" bash -s <<'EOF'
set -e
rex config check "$HOME/.config/rex/init.lua"
if [ -S /run/rex/server.sock ]; then
  rex -S unix:///run/rex/server.sock config reload
else
  rex config reload
fi
EOF
