{
  config,
  pkgs,
  ...
}: let
  lock = "${pkgs.swaylock}/bin/swaylock -f";
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
