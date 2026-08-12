{
  config,
  wallpaper,
  ...
}: {
  programs.niri.settings = {
    input = {
      keyboard.xkb.layout = "us";
      touchpad = {
        tap = true;
        natural-scroll = true;
      };
    };

    layout = {
      gaps = 12;
      center-focused-column = "never";
      default-column-width.proportion = 0.5;
      focus-ring = {
        width = 4;
        active.color = "#${config.lib.stylix.colors.base0D}";
        inactive.color = "#${config.lib.stylix.colors.base03}";
      };
      border.enable = false;
    };

    window-rules = [
      {
        matches = [{app-id = "net-runelite-launcher-Launcher";}];
        open-floating = true;
      }
    ];

    spawn-at-startup = [
      {argv = ["swaybg" "--image" "${wallpaper}"];}
      {argv = ["mako"];}
      {argv = ["xwayland-satellite"];}
      {argv = ["ironbar"];}
    ];

    screenshot-path = "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png";

    binds = {
      "Mod+Shift+Slash".action.show-hotkey-overlay = [];

      "Mod+Return" = {
        hotkey-overlay.title = "Open Terminal: foot";
        action.spawn = "foot";
      };
      "Mod+D" = {
        hotkey-overlay.title = "Run Application: vicinae";
        action.spawn = ["vicinae" "vicinae://toggle"];
      };
      "Mod+O" = {
        repeat = false;
        hotkey-overlay.title = "Open Overview";
        action.toggle-overview = [];
      };
      "Mod+Shift+K" = {
        repeat = false;
        hotkey-overlay.title = "Toggle On-Screen Keyboard";
        action.spawn = ["systemctl" "--user" "kill" "--signal=RTMIN" "tablet-keyboard.service"];
      };
      "Mod+Shift+W" = {
        hotkey-overlay.title = "Wi-Fi Networks: nmtui";
        action.spawn = ["foot" "-e" "nmtui"];
      };
      "Super+Alt+L" = {
        hotkey-overlay.title = "Lock Screen: swaylock";
        action.spawn = "swaylock";
      };

      "Mod+Q" = {
        repeat = false;
        action.close-window = [];
      };

      "Mod+Left".action.focus-column-left = [];
      "Mod+Down".action.focus-window-down = [];
      "Mod+Up".action.focus-window-up = [];
      "Mod+Right".action.focus-column-right = [];
      "Mod+H".action.focus-column-left = [];
      "Mod+J".action.focus-window-down = [];
      "Mod+K".action.focus-window-up = [];
      "Mod+L".action.focus-column-right = [];

      "Mod+Ctrl+Left".action.move-column-left = [];
      "Mod+Ctrl+Down".action.move-window-down = [];
      "Mod+Ctrl+Up".action.move-window-up = [];
      "Mod+Ctrl+Right".action.move-column-right = [];
      "Mod+Ctrl+H".action.move-column-left = [];
      "Mod+Ctrl+J".action.move-window-down = [];
      "Mod+Ctrl+K".action.move-window-up = [];
      "Mod+Ctrl+L".action.move-column-right = [];

      "Mod+Shift+Left".action.focus-monitor-left = [];
      "Mod+Shift+Right".action.focus-monitor-right = [];

      "Mod+Page_Down".action.focus-workspace-down = [];
      "Mod+Page_Up".action.focus-workspace-up = [];
      "Mod+Ctrl+Page_Down".action.move-column-to-workspace-down = [];
      "Mod+Ctrl+Page_Up".action.move-column-to-workspace-up = [];

      "Mod+1".action.focus-workspace = 1;
      "Mod+2".action.focus-workspace = 2;
      "Mod+3".action.focus-workspace = 3;
      "Mod+4".action.focus-workspace = 4;
      "Mod+5".action.focus-workspace = 5;
      "Mod+6".action.focus-workspace = 6;
      "Mod+7".action.focus-workspace = 7;
      "Mod+8".action.focus-workspace = 8;
      "Mod+9".action.focus-workspace = 9;
      "Mod+Ctrl+1".action.move-column-to-workspace = 1;
      "Mod+Ctrl+2".action.move-column-to-workspace = 2;
      "Mod+Ctrl+3".action.move-column-to-workspace = 3;
      "Mod+Ctrl+4".action.move-column-to-workspace = 4;
      "Mod+Ctrl+5".action.move-column-to-workspace = 5;
      "Mod+Ctrl+6".action.move-column-to-workspace = 6;
      "Mod+Ctrl+7".action.move-column-to-workspace = 7;
      "Mod+Ctrl+8".action.move-column-to-workspace = 8;
      "Mod+Ctrl+9".action.move-column-to-workspace = 9;

      "Mod+R".action.switch-preset-column-width = [];
      "Mod+Shift+R".action.switch-preset-column-width-back = [];

      "Mod+F".action.maximize-column = [];
      "Mod+Shift+F".action.fullscreen-window = [];

      "Mod+V".action.toggle-window-floating = [];
      "Mod+Shift+V".action.switch-focus-between-floating-and-tiling = [];

      "XF86AudioRaiseVolume" = {
        allow-when-locked = true;
        action.spawn-sh = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1+ -l 1.0";
      };
      "XF86AudioLowerVolume" = {
        allow-when-locked = true;
        action.spawn-sh = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1-";
      };
      "XF86AudioMute" = {
        allow-when-locked = true;
        action.spawn-sh = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
      };
      "XF86AudioMicMute" = {
        allow-when-locked = true;
        action.spawn-sh = "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
      };

      "XF86AudioPlay" = {
        allow-when-locked = true;
        action.spawn-sh = "playerctl play-pause";
      };
      "XF86AudioPause" = {
        allow-when-locked = true;
        action.spawn-sh = "playerctl play-pause";
      };
      "XF86AudioPrev" = {
        allow-when-locked = true;
        action.spawn-sh = "playerctl previous";
      };
      "XF86AudioNext" = {
        allow-when-locked = true;
        action.spawn-sh = "playerctl next";
      };

      "XF86MonBrightnessUp" = {
        allow-when-locked = true;
        action.spawn = ["brightnessctl" "--class=backlight" "set" "+10%"];
      };
      "XF86MonBrightnessDown" = {
        allow-when-locked = true;
        action.spawn = ["brightnessctl" "--class=backlight" "set" "10%-"];
      };

      "Print".action.screenshot = [];
      "Ctrl+Print".action.screenshot-screen = [];
      "Alt+Print".action.screenshot-window = [];

      "Mod+Shift+E".action.quit = [];
    };
  };
}
