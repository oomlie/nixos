{pkgs, ...}: {
  # Nix settings
  nix.settings.experimental-features = ["nix-command" "flakes"];
  nix.settings.auto-optimise-store = true;
  # 256 MiB download buffer: fewer stalls on large fetches (games, toolchains)
  nix.settings.download-buffer-size = 268435456;

  # Locale
  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Firewall
  networking.firewall.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

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
}
