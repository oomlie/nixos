{
  config,
  lib,
  wallpaper,
  ...
}: {
  programs.noctalia = {
    enable = true;
    systemd.enable = true;
    settings = {
      shell = {
        font_family = config.stylix.fonts.sansSerif.name;
        telemetry_enabled = false;
        panel = {
          transparency_mode = "soft";
          borders = true;
          shadow = true;
          launcher_placement = "floating";
          clipboard_placement = "floating";
          launcher_position = "center";
          clipboard_position = "center";
        };
      };

      theme.mode = "dark";

      wallpaper = {
        enabled = true;
        fill_mode = "crop";
        default.path = "${wallpaper}";
        automation.enabled = false;
      };

      notification.enable_daemon = true;

      lockscreen = {
        enabled = true;
        lock_before_suspend = true;
        blurred_desktop = true;
      };

      shell.polkit_agent = true;

      nightlight = {
        enabled = true;
        temperature_day = 6500;
        temperature_night = 4000;
      };
      calendar.enabled = true;
      idle.behavior = {
        lock = {
          enabled = true;
          timeout = 600;
          action = "lock";
        };
        screen-off = {
          enabled = true;
          timeout = 630;
          action = "screen_off";
        };
      };

      location = {
        latitude = 38.9072;
        longitude = -77.0369;
      };
      weather = {
        enabled = true;
        unit = "fahrenheit";
      };

      bar.main = {
        position = "top";
        thickness = 36;
        margin_ends = 8;
        margin_edge = 8;
        padding = 10;
        widget_spacing = 6;
        radius = 12;
        background_opacity = 0.86;
        border_width = 1.0;
        reserve_space = true;
        auto_hide = false;
        smart_auto_hide = false;
        start = [
          "launcher"
          "workspaces"
        ];
        center = ["clock"];
        end = [
          "tray"
          "notifications"
          "network"
          "volume"
          "battery"
          "control-center"
        ];
      };

      widget.network.show_label = false;

      dock.enabled = false;
      desktop_widgets.enabled = false;
    };
  };

  systemd.user.services.noctalia = {
    Unit = {
      After = lib.mkForce ["niri.service"];
      PartOf = lib.mkForce ["niri.service"];
      ConditionEnvironment = "WAYLAND_DISPLAY";
    };
    Install.WantedBy = lib.mkForce ["niri.service"];
  };
}
