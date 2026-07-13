{pkgs, ...}: {
  home.packages = with pkgs; [
    cliphist
    wl-clipboard
    playerctl
    brightnessctl
    xwayland-satellite
  ];

  xdg.configFile."niri/config.kdl".source = ./config.kdl;
}
