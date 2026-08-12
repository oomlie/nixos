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

      osd.kinds = {
        volume = false;
        brightness = false;
        wifi = false;
        bluetooth = false;
        power_profile = false;
        caffeine = false;
        nightlight = false;
        dnd = false;
        lock_keys = false;
        keyboard_layout = false;
        privacy = false;
      };

      lockscreen = {
        enabled = true;
        blurred_desktop = true;
      };

      nightlight.enabled = false;
      idle.behavior = {
        lock.enabled = false;
        screen-off.enabled = false;
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
        thickness = 44;
        margin_ends = 12;
        margin_edge = 8;
        padding = 12;
        widget_spacing = 6;
        reserve_space = true;
        start = [
          "launcher"
          "workspaces"
        ];
        center = ["clock"];
        end = [
          "media"
          "tray"
          "notifications"
          "clipboard"
          "network"
          "bluetooth"
          "volume"
          "brightness"
          "battery"
          "control-center"
          "session"
        ];
      };

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
