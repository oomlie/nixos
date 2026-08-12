_: {
  programs = {
    zsh = {
      enable = true;
      # Skip compaudit security scan (~15ms/shell); keep dump freshness check
      completionInit = "autoload -U compinit && compinit -u";
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      history = {
        size = 50000;
        ignoreDups = true;
        share = true;
      };
    };

    starship.enable = true;

    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    fzf.enable = true;
    zoxide.enable = true;
    bat.enable = true;
    eza = {
      enable = true;
      icons = "auto";
    };
    nnn.enable = true;
  };
}
