{pkgs ? import <nixpkgs> {config.allowUnfree = true;}}:
pkgs.mkShellNoCC {
  packages = [(pkgs.callPackage ./package.nix {})];
}
