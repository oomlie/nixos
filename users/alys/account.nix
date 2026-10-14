# Alys (misty only): upload/ops account with a SOPS-managed password. Her
# opencode agent and its route.daze.lol configuration live in hosts/misty/opencode.nix.
{
  config,
  pkgs,
  ...
}: let
  keys = import ../../keys.nix;
in {
  users.users.alys = {
    isNormalUser = true;
    uid = 1002;
    description = "Alys";
    hashedPasswordFile = config.sops.secrets."ssh/alys-password-hash".path;
    openssh.authorizedKeys.keys = [keys.alys];
  };

  services.openssh.extraConfig = ''
    Match User alys
      PasswordAuthentication yes
  '';

  sops.secrets."ssh/alys-password-hash" = {
    sopsFile = ../../secrets/misty.yaml;
    mode = "0400";
    restartUnits = ["alys-password.service" "sshd.service"];
  };
  sops.secrets."alys-route-api-key" = {
    sopsFile = ../../secrets/misty.yaml;
    key = "route/alys-api-key";
    owner = "alys";
    mode = "0400";
    restartUnits = ["alys-opencode-config.service"];
  };

  systemd.services.alys-password = {
    description = "Set the temporary Alys SSH password from SOPS";
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      printf 'alys:%s\n' "$(cat ${config.sops.secrets."ssh/alys-password-hash".path})" \
        | ${pkgs.shadow}/bin/chpasswd -e
    '';
  };
}
