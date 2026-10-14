_: {
  projectRootFile = "flake.nix";

  programs = {
    alejandra.enable = true;
    statix.enable = true;
    deadnix.enable = true;
  };

  settings.global.excludes = [
    "flake.lock"
    "hosts/*/hardware-configuration.nix"
    "secrets/*"
  ];
}
