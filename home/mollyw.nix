{...}: {
  imports = [
    ./programs/helix.nix
    ./programs/git.nix
    ./programs/vscodium.nix
    ./programs/firefox.nix
    ./programs/zsh.nix
    ./programs/starship.nix
    ./programs/direnv.nix
    ./programs/fzf.nix
    ./programs/zoxide.nix
    ./programs/bat.nix
    ./programs/eza.nix
    ./programs/btop.nix
    ./programs/ghostty.nix
    ./programs/plasma.nix
    ./programs/opencode.nix
    ./programs/discord.nix
    ./programs/mpv.nix
    ./programs/niri
    ./programs/vicinae.nix
  ];

  home = {
    username = "mollyw";
    homeDirectory = "/home/mollyw";
  };

  programs.home-manager.enable = true;

  # stateVersion is a compatibility pin — do not change on every upgrade
  home.stateVersion = "26.05";
}
