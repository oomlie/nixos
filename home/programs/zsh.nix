{lib, ...}: {
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    history = {
      size = 50000;
      ignoreDups = true;
      share = true;
    };

    # Keep the terminal title in sync with the working directory
    initContent = lib.mkOrder 1000 ''
      function title_precmd_hook() {
        print -Pn "\e]0;$(pwd)\a"
      }
      precmd_functions+=title_precmd_hook
    '';
  };
}
