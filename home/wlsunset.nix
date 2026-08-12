{pkgs, ...}: {
  services.wlsunset = {
    enable = true;
    latitude = 38.9072;
    longitude = -77.0369;
    temperature = {
      day = 6500;
      night = 4000;
    };
    systemdTarget = "niri.service";
  };

  programs.niri.settings.binds."Mod+Shift+N" = {
    repeat = false;
    hotkey-overlay.title = "Cycle Night Light Mode";
    action.spawn = [
      "${pkgs.systemd}/bin/systemctl"
      "--user"
      "kill"
      "--signal=USR1"
      "wlsunset.service"
    ];
  };
}
