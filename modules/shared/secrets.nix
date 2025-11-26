{
  self,
  pkgs,
  config,
  inputs,
  dotnix-constants,
  ...
}: let
  inherit (inputs) agenix;
  ageSecret = {
    file,
    owner ? "root",
    mode ? "400",
  }: {
    file = "${self}/secrets/${file}";
    inherit owner mode;
  };
  inherit (dotnix-constants) user;
in {
  environment.systemPackages = [
    agenix.packages."${pkgs.system}".default
  ];

  age.identityPaths = [
    "/etc/ssh/ssh_host_ed25519_key"
    "${config.users.users.${user.name}.home}/.ssh/id_ed25519"
  ];

  age.secrets = {
    "frp-server-auth.toml" = ageSecret {
      file = "frp-server-auth.age";
      owner = user.name;
      mode = "777";
    };
    atuin-key = ageSecret {
      file = "atuin-key.age";
      owner = user.name;
    };
    atuin-client-config = ageSecret {
      file = "atuin-client-config.age";
      owner = user.name;
    };
    ssh-remote-host-config = ageSecret {
      file = "ssh-remote-hosts.age";
      owner = user.name;
    };
    copilot-gpt4-service-env = ageSecret {
      file = "copilot-gpt4-service-env.age";
      owner = user.name;
    };
    chatgpt-next-web-env = ageSecret {
      file = "chatgpt-next-web.age";
      owner = user.name;
    };
    wildcard-api-key = ageSecret {
      file = "wildcard-api-key.age";
      owner = user.name;
    };
    claude-api-key = ageSecret {
      file = "claude-api-key.age";
      owner = user.name;
    };
    luee-net-api-key = ageSecret {
      file = "luee-net-api-key.age";
      owner = user.name;
    };
    github-cli-access-token = ageSecret {
      file = "github-cli-access-token.age";
      owner = user.name;
    };
    tailscale-oauth-key = ageSecret {
      file = "tailscale-oauth-key.age";
      owner = user.name;
    };
    tailscale-auth-key = ageSecret {
      file = "tailscale-auth-key.age";
      owner = user.name;
    };
    wakatime-cfg =
      (ageSecret {
        file = "wakatime-cfg.age";
        owner = user.name;
      })
      // {
        path = "${config.users.users.${user.name}.home}/.wakatime.cfg";
      };
    github-actions-runner-token = ageSecret {
      file = "github-actions-runner-token.age";
      owner = user.name;
    };
    bot-ssh-private-key = ageSecret {
      file = "bot-ssh-private-key.age";
      owner = user.name;
      mode = "444";
    };
    openrouter-api-key = ageSecret {
      file = "openrouter-api-key.age";
      owner = user.name;
    };
    telegram-bot = ageSecret {
      file = "telegram-bot.age";
      owner = user.name;
    };
  };
}
