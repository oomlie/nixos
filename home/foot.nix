{
  lib,
  config,
  ...
}: {
  programs.foot = {
    enable = true;
    settings = {
      main = {
        font = lib.mkForce "${config.stylix.fonts.monospace.name}:size=11";
        pad = "8x8";
      };
      csd = {
        preferred = "none";
      };
      "colors-dark" = {
        alpha = lib.mkForce 0.92;
      };
      "colors-light" = {
        alpha = lib.mkForce 0.92;
      };
    };
  };
}
