set shell := ["bash", "-uc"]

alias yu := yukikaze

host := `hostname -s`
system := if os() == "macos" { "macos" } else { "nixos" }

default:
  @echo "System: {{system}}, Host: {{host}}"
  @{{just_executable()}} {{host}}

check:
  {{just_executable()}} ci-{{host}}

LCNDWWYVTFMFX use_nom="yes" details="yes": (_macos_rebuild "LCNDWWYVTFMFX" use_nom details)

ci-LCNDWWYVTFMFX: (_macos_build "LCNDWWYVTFMFX" "no" "yes")

yukikaze use_nom="yes" details="yes": (_macos_rebuild "yukikaze" use_nom details)

ci-yukikaze: (_macos_build "yukikaze" "no" "yes")

poi use_nom="yes" details="yes": (_nixos_rebuild "poi" use_nom details)

ci-poi: (_nixos_build "poi" "no" "yes")

taihou use_nom="yes" details="yes": (_nixos_rebuild "taihou" use_nom details)

ci-taihou: (_nixos_build "taihou" "no" "yes")

_macos_build hostname use_nom="yes" details="no":
  @{{ if use_nom == "yes" { "nom" } else { "nix" } }} build .#darwinConfigurations.{{hostname}}.system --accept-flake-config --extra-experimental-features 'nix-command flakes' {{ if details != "no" { "--show-trace" } else { "" } }}

_nixos_build hostname use_nom="yes" details="no":
  {{ if use_nom == "yes" { "nom" } else { "nix" } }} build .#nixosConfigurations.{{hostname}}.config.system.build.toplevel --accept-flake-config {{ if details != "no" { "--show-trace --verbose" } else { "" } }}

_macos_rebuild hostname use_nom="yes" details="no": (_macos_build hostname use_nom details) && (_macos_switch hostname details)

_nixos_rebuild hostname use_nom="yes" details="no": (_nixos_build hostname use_nom details) && (_nixos_switch hostname details)

_macos_switch hostname details="no": _cleanup_rime_ls_build_prism_bin _cleanup_atuin_config _remove_conflicting_files
  @sudo -E ./result/sw/bin/darwin-rebuild switch --flake .#{{hostname}} {{ if details != "no" { "--show-trace" } else { "" } }}

_nixos_switch hostname details="no": _cleanup_rime_ls_build_prism_bin _cleanup_atuin_config
  @sudo nixos-rebuild switch --flake .#{{hostname}}

_cleanup_rime_ls_build_prism_bin:
  -@rm $HOME/.local/share/rime-ls-files/build/flypy.prism.bin

_cleanup_atuin_config:
  -@rm $HOME/.config/atuin/config.toml

_remove_conflicting_files:
    @sudo rm /etc/zshrc /etc/zprofile

up:
  @nix flake update

push: commit
  @git push

commit:
  -@git add --all
  -@git commit -m '...'

gc:
  # garbage collect all unused nix store entries
  @sudo nix store gc --debug --extra-experimental-features nix-command
  @sudo nix-collect-garbage --delete-old

darwin-set-proxy:
  sudo python3 scripts/darwin-set-proxy.py

fmt:
  @nix fmt -- --exclude "./modules/shared/dotnix/development/languages/.vim-template.*.nix" --exclude "./modules/shared/dotnix/apps/.vim-template:*.nix" --exclude "./modules/darwin/dotnix/.vim-template:*.nix" --exclude "./modules/shared/dotnix/development/languages/.vim-template:*.nix" .

ci-fmt:
  @nix fmt -- --exclude "./modules/shared/dotnix/development/languages/.vim-template.*.nix" --exclude "./modules/shared/dotnix/apps/.vim-template:*.nix" --exclude "./modules/darwin/dotnix/.vim-template:*.nix" --exclude "./modules/shared/dotnix/development/languages/.vim-template:*.nix" --check .

ci-eval:
  @nix run --extra-experimental-features 'nix-command flakes' nixpkgs#nix-eval-jobs -- --flake .

ci: ci-fmt ci-eval
