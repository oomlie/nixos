{
  inputs,
  pkgs,
  ...
}: {
  imports = [inputs.nix-doom-emacs-unstraightened.hmModule];

  programs.doom-emacs = {
    enable = true;
    emacs = pkgs.emacs-pgtk;
    doomDir = ./doom.d;
    experimentalFetchTree = true;
    extraPackages = epkgs: [epkgs.treesit-grammars.with-all-grammars];
  };
}
