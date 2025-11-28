let
  user = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG92SyvgOOe9pGPGHEY9VbDBWwqaRgm9tg1RJUxlfdCN"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKR85V4/rPx5GRUUI5j+ssL/Mr2ynwMZuPi49yLU7NjJ"
  ];

  # hosts
  poi = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIChh+2JjsSms14xR5l8y2zzyCI5ryzEzeuq9N8wsaEqK";
  yukikaze = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIY8aMFW3F68el/LQyZtONVuEMwJfejRvRdjLTps84f3";
  yamato = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID52VHi3XJl9hfHC/ywRrjV05bKqRvKulbzud/59ekX7";
  taihou = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG9GFpFscLGWnUTbnYb/Y5BrAXRNTxctjTHVVNvS/LfC";
  LCNDWWYVTFMFX = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHztICoKsGrGNfEmdfBBwrxd8KnxMKNfxiYy+5ZzAKll";

  # collections
  desktops = [
    yukikaze
    yamato
    LCNDWWYVTFMFX
  ];
  homeServers = [
    poi
    taihou
  ];

  # helpers
  mkSecrets = list: list ++ user;
in {
  "frp-server-auth.age".publicKeys = mkSecrets (homeServers ++ desktops);
  "atuin-key.age".publicKeys = mkSecrets (homeServers ++ desktops);
  "atuin-client-config.age".publicKeys = mkSecrets (homeServers ++ desktops);
  "ssh-remote-hosts.age".publicKeys = mkSecrets (homeServers ++ desktops);
  "copilot-gpt4-service-env.age".publicKeys = mkSecrets (homeServers ++ desktops);
  "chatgpt-next-web.age".publicKeys = mkSecrets (homeServers ++ desktops);
  "wildcard-api-key.age".publicKeys = mkSecrets (homeServers ++ desktops);
  "claude-api-key.age".publicKeys = mkSecrets (homeServers ++ desktops);
  "luee-net-api-key.age".publicKeys = mkSecrets (homeServers ++ desktops);
  "github-cli-access-token.age".publicKeys = mkSecrets (homeServers ++ desktops);
  "wakatime-cfg.age".publicKeys = mkSecrets (homeServers ++ desktops);
  "tailscale-oauth-key.age".publicKeys = mkSecrets (homeServers ++ desktops);
  "tailscale-auth-key.age".publicKeys = mkSecrets (homeServers ++ desktops);
  "github-actions-runner-token.age".publicKeys = mkSecrets (homeServers ++ desktops);
  "bot-ssh-private-key.age".publicKeys = mkSecrets (homeServers ++ desktops);
  "tesla-password.age".publicKeys = mkSecrets (homeServers ++ desktops);
  "openrouter-api-key.age".publicKeys = mkSecrets (homeServers ++ desktops);
  "telegram-bot.age".publicKeys = mkSecrets (homeServers ++ desktops);
  "ledger-bot-token.age".publicKeys = mkSecrets (homeServers ++ desktops);
}
