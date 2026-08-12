{
  config,
  pkgs,
  ...
}: let
  niri = "${config.programs.niri.package}/bin/niri";
  touchscreen = "/dev/input/by-path/pci-0000:00:15.1-platform-i2c_designware.1-event";
  tabletGestures = pkgs.writeShellScript "tablet-gestures" ''
    exec ${pkgs.lisgd}/bin/lisgd \
      -d ${touchscreen} \
      -t 120 \
      -m 900 \
      -g "2,LR,L,*,R,${niri} msg action focus-column-left" \
      -g "2,RL,R,*,R,${niri} msg action focus-column-right" \
      -g "2,DU,B,*,R,${niri} msg action toggle-overview"
  '';
in {
  home.packages = [
    pkgs.lisgd
    pkgs.wvkbd
  ];

  systemd.user.services = {
    tablet-keyboard = {
      Unit = {
        Description = "Framework tablet on-screen keyboard";
        PartOf = ["graphical-session.target"];
        After = ["graphical-session.target"];
      };
      Service = {
        ExecStart = "${pkgs.wvkbd}/bin/wvkbd-mobintl --hidden -H 480 -L 360 --fn '${config.stylix.fonts.monospace.name} 20'";
        Restart = "on-failure";
      };
      Install.WantedBy = ["graphical-session.target"];
    };

    tablet-gestures = {
      Unit = {
        Description = "Experimental Framework touchscreen edge gestures";
        PartOf = ["graphical-session.target"];
        After = ["graphical-session.target"];
      };
      Service = {
        ExecStart = tabletGestures;
        Restart = "on-failure";
        RestartSec = 2;
      };
      Install.WantedBy = ["graphical-session.target"];
    };
  };
}
