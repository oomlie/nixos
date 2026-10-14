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
  services.displayManager.noctalia-greeter = {
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
    package = pkgs.niri;
  };

  # Rotate the internal display from the Framework's accelerometer data.
  # iio-niri defaults to the first monitor Niri sees (the internal panel here);
  # pin a specific output with extraArgs = ["--monitor" "eDP-1"] if a docked
  # display is enumerated first.
  services.iio-niri.enable = true;

  # Stable name for the internal touchscreen, used by the tablet gesture
  # service, so it does not depend on the kernel's event number or the
  # i2c_designware path.
  services.udev.extraRules = ''
    SUBSYSTEM=="input", KERNEL=="event*", ENV{ID_INPUT_TOUCHSCREEN}=="1", SYMLINK+="input/tablet-touchscreen"
  '';

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
