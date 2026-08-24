{pkgs, ...}: {
  home = {
    username = "molly";
    homeDirectory = "/home/molly";
    stateVersion = "26.05";
  };

  home.packages = with pkgs; [
    opencode
  ];

  programs.home-manager.enable = true;
}
