{pkgs, ...}: {
  imports = [
    ./apps.nix
    ./foot.nix
    ./niri.nix
    ./noctalia.nix
    ./opencode.nix
    ./qutebrowser.nix
    ./shell.nix
    ./satty.nix
    ./stylix.nix
    ./tablet.nix
  ];

  _module.args = {
    wallpaper = ../wallpapers/wp2002041.jpg;

    # Shared credential helper for git.purplish.blue (git + the agent-wiki pull).
    giteaCredentialHelper = pkgs.writeShellScript "git-credential-purplish" ''
      if [[ "''${1:-}" != get ]]; then
        exit 0
      fi

      token="$(${pkgs.libsecret}/bin/secret-tool lookup service gitea host git.purplish.blue user molly)"
      if [[ -z "$token" ]]; then
        exit 1
      fi

      printf '%s\n' "username=molly" "password=$token"
    '';
  };

  home = {
    username = "mollyw";
    homeDirectory = "/home/mollyw";

    packages = with pkgs; [
      # Niri ecosystem
      xwayland-satellite
      equibop

      # Game development
      godot_4
    ];

    # stateVersion is a compatibility pin — do not change on every upgrade
    stateVersion = "26.05";

    sessionPath = ["$HOME/.bun/bin" "$HOME/.npm-global/bin"];
  };

  programs.home-manager.enable = true;
}
