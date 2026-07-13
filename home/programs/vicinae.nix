{
  # App launcher + clipboard-history UI for the niri session
  programs.vicinae = {
    enable = true;
    systemd.enable = true;
    settings.window.opacity = 0.85;
  };
}
