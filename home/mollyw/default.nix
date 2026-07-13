# Home-manager entry point for mollyw.
# Program config lives in one file per program under ./programs.
{
  imports = [
    # Desktop programs
    ./programs/firefox.nix
    ./programs/ghostty.nix
    ./programs/plasma.nix

    # Editors
    ./programs/helix.nix
    ./programs/vscodium.nix
    ./programs/opencode.nix

    # CLI programs
    ./programs/bat.nix
    ./programs/btop.nix
    ./programs/direnv.nix
    ./programs/eza.nix
    ./programs/fzf.nix
    ./programs/git.nix
    ./programs/starship.nix
    ./programs/zoxide.nix
    ./programs/zsh.nix
  ];

  home = {
    username = "mollyw";
    homeDirectory = "/home/mollyw";
  };

  programs.home-manager.enable = true;

  # stateVersion is a compatibility pin — do not change on every upgrade
  home.stateVersion = "26.05";
}
