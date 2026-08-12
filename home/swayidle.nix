{
  config,
  pkgs,
  ...
}: let
  lock = "${pkgs.systemd}/bin/systemctl --user start noctalia.service && ${config.programs.noctalia.package}/bin/noctalia msg session lock";
  niri = "${config.programs.niri.package}/bin/niri msg action";
in {
  services.swayidle = {
    enable = true;
    systemdTargets = ["niri.service"];
    events.before-sleep = lock;
    timeouts = [
      {
        timeout = 600;
        command = lock;
      }
      {
        timeout = 630;
        command = "${niri} power-off-monitors";
        resumeCommand = "${niri} power-on-monitors";
      }
    ];
  };
}
