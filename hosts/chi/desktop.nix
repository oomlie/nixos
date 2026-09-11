{pkgs, ...}: {
  # Fonts: Comic Mono Nerd Font system-wide; Noto for Firefox's default look
  fonts.packages = with pkgs; [
    nerd-fonts.comic-shanns-mono
    noto-fonts
    noto-fonts-color-emoji
  ];
  fonts.fontconfig.defaultFonts = {
    serif = ["ComicShannsMono Nerd Font"];
    sansSerif = ["ComicShannsMono Nerd Font"];
    monospace = ["ComicShannsMono Nerd Font Mono"];
    emoji = ["Noto Color Emoji"];
  };

  # Noctalia's recommended services provide NetworkManager, Bluetooth, UPower,
  # and a power profile service for its integrations.
  programs.noctalia = {
    enable = true;
    recommendedServices.enable = true;
  };

  # Noctalia login UI; its module configures greetd and AccountsService.
  programs.noctalia-greeter = {
    enable = true;
    settings = {
      session.default = "niri";
      keyboard.layout = "us";
      idle.timeout = 300;
    };
  };

  # Niri compositor
  programs.niri = {
    enable = true;
    package = pkgs.niri-unstable;
  };

  # Rotate the internal display from the Framework's accelerometer data.
  services.iio-niri = {
    enable = true;
    extraArgs = ["--monitor" "eDP-1"];
  };

  # XWayland support for X11 apps under niri
  programs.xwayland.enable = true;

  # Sound
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # Bluetooth
  hardware.bluetooth.powerOnBoot = true;

  # XDG desktop portal for native file dialogs under Wine/Ableton
  xdg.portal = {
    enable = true;
    extraPortals = [pkgs.xdg-desktop-portal-gtk];
    config.common.default = "*";
  };
}
