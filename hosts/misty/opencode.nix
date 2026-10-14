# Interactive opencode coding agent over SSH for alys and molly, dialing the
# route.daze.lol gateway. The route-models plugin discovers every model the
# gateway serves, so none are hardcoded here. Each user's route key stays out
# of the store: a wrapper exports it from the SOPS-rendered secret at run time.
{
  config,
  pkgs,
  ...
}: let
  pluginPath = ../../home/opencode/plugins/route-models.js;

  configFile = pkgs.writeText "opencode.json" (builtins.toJSON {
    model = "route/gpt-5.6-sol";
    small_model = "route/gpt-5.6-luna";
    provider.route = {
      npm = "@ai-sdk/openai";
      options = {
        baseURL = "https://route.daze.lol/v1";
        apiKey = "{env:ROUTE_API_KEY}";
      };
    };
    plugin = ["${pluginPath}"];
  });

  opencodeFor = secretName:
    pkgs.writeShellApplication {
      name = "opencode";
      runtimeInputs = [pkgs.coreutils];
      text = ''
        export ROUTE_API_KEY="$(cat ${config.sops.secrets.${secretName}.path})"
        exec ${pkgs.opencode}/bin/opencode "$@"
      '';
    };

  opencodeConfig = user: {
    description = "Write ${user}'s opencode configuration";
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = user;
    };
    script = ''
      install -d -m 0700 "/home/${user}/.config/opencode"
      install -m 0600 ${configFile} "/home/${user}/.config/opencode/opencode.json"
    '';
  };
in {
  users.users.alys.packages = [(opencodeFor "alys-route-api-key")];
  users.users.molly.packages = [(opencodeFor "molly-route-api-key")];

  systemd.services.alys-opencode-config = opencodeConfig "alys";
  systemd.services.molly-opencode-config = opencodeConfig "molly";

  sops.secrets."molly-route-api-key" = {
    sopsFile = ../../secrets/misty.yaml;
    key = "route/api-key";
    owner = "molly";
    mode = "0400";
    restartUnits = ["molly-opencode-config.service"];
  };
}
