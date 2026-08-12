{
  config,
  pkgs,
  ...
}: let
  colors = config.lib.stylix.colors;
  style = pkgs.writeText "swayosd.css" ''
    window {
      border-radius: 12px;
      border: 2px solid #${colors.base0D};
      background: #${colors.base00};
      color: #${colors.base05};
      font-family: "${config.stylix.fonts.sansSerif.name}";
    }

    progressbar trough {
      background: #${colors.base02};
    }

    progressbar progress {
      background: #${colors.base0D};
    }
  '';
in {
  services.swayosd = {
    enable = true;
    stylePath = style;
  };
}
