{config, ...}: {
  programs.niri.settings = {
    input = {
      keyboard.xkb.layout = "us";
      touchpad = {
        tap = true;
        natural-scroll = true;
        dwt = true;
        click-method = "clickfinger";
      };
    };

    layout = {
      gaps = 12;
      center-focused-column = "never";
      always-center-single-column = true;
      preset-column-widths = [
        {proportion = 1.0 / 3.0;}
        {proportion = 0.5;}
        {proportion = 2.0 / 3.0;}
        {proportion = 1.0;}
      ];
      default-column-width.proportion = 0.5;
      focus-ring = {
        width = 3;
        active.color = "#${config.lib.stylix.colors.base0D}";
        inactive.color = "#${config.lib.stylix.colors.base03}";
      };
      border.enable = false;
      background-color = "transparent";
    };

    window-rules = [
      {
        geometry-corner-radius = let
          radius = 12.0;
        in {
          top-left = radius;
          top-right = radius;
          bottom-right = radius;
          bottom-left = radius;
        };
        clip-to-geometry = true;
      }
      {
        matches = [
          {
            app-id = "firefox$";
            title = "^Picture-in-Picture$";
          }
        ];
        open-floating = true;
        default-column-width.fixed = 480;
        default-window-height.fixed = 270;
        default-floating-position = {
          x = 24;
          y = 24;
          relative-to = "bottom-right";
        };
      }
      {
        matches = [{app-id = "net-runelite-launcher-Launcher";}];
        open-floating = true;
      }
      {
        matches = [{app-id = "dev.noctalia.Noctalia";}];
        open-floating = true;
        default-column-width.fixed = 1080;
        default-window-height.fixed = 920;
      }
    ];

    layer-rules = [
      {
        matches = [{namespace = "^noctalia-wallpaper";}];
        place-within-backdrop = true;
      }
    ];

    debug.honor-xdg-activation-with-invalid-serial = [];

    spawn-at-startup = [
      {argv = ["xwayland-satellite"];}
    ];

    screenshot-path = "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png";

    binds = {
      "Mod+Shift+Slash".action.show-hotkey-overlay = [];

      "Mod+Return" = {
        hotkey-overlay.title = "Open Terminal: foot";
        action.spawn = "foot";
      };
      "Mod+D" = {
        repeat = false;
        hotkey-overlay.title = "Open Noctalia Launcher";
        action.spawn = ["noctalia" "msg" "panel-toggle" "launcher"];
      };
      "Mod+S" = {
        repeat = false;
        hotkey-overlay.title = "Open Noctalia Control Center";
        action.spawn = ["noctalia" "msg" "panel-toggle" "control-center"];
      };
      "Mod+Shift+Comma" = {
        repeat = false;
        hotkey-overlay.title = "Open Noctalia Settings";
        action.spawn = ["noctalia" "msg" "settings-toggle"];
      };
      "Alt+Tab" = {
        repeat = false;
        hotkey-overlay.title = "Open Noctalia Window Switcher";
        action.spawn = ["noctalia" "msg" "window-switcher"];
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
      "Mod+Shift+N" = {
        repeat = false;
        hotkey-overlay.title = "Toggle Night Light";
        action.spawn = ["noctalia" "msg" "nightlight-toggle"];
      };
      "Mod+Shift+W" = {
        hotkey-overlay.title = "Wi-Fi Networks: nmtui";
        action.spawn = ["foot" "-e" "nmtui"];
      };
      "Super+Alt+L" = {
        repeat = false;
        allow-inhibiting = false;
        hotkey-overlay.title = "Lock Screen: Noctalia";
        action.spawn = ["noctalia" "msg" "session" "lock"];
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

      "Mod+Comma".action.consume-window-into-column = [];
      "Mod+Period".action.expel-window-from-column = [];
      "Mod+BracketLeft".action.consume-or-expel-window-left = [];
      "Mod+BracketRight".action.consume-or-expel-window-right = [];

      "Mod+F".action.maximize-column = [];
      "Mod+Shift+F".action.fullscreen-window = [];
      "Mod+C".action.center-column = [];
      "Mod+W".action.toggle-column-tabbed-display = [];

      "Mod+V".action.toggle-window-floating = [];
      "Mod+Shift+V".action.switch-focus-between-floating-and-tiling = [];

      "Mod+Shift+P" = {
        repeat = false;
        hotkey-overlay.title = "Power Off Monitors";
        action.power-off-monitors = [];
      };
      "Mod+Escape" = {
        repeat = false;
        hotkey-overlay.title = "Release Captured Shortcuts";
        action.toggle-keyboard-shortcuts-inhibit = [];
      };

      "XF86AudioRaiseVolume" = {
        allow-when-locked = true;
        action.spawn = ["noctalia" "msg" "volume-up"];
      };
      "XF86AudioLowerVolume" = {
        allow-when-locked = true;
        action.spawn = ["noctalia" "msg" "volume-down"];
      };
      "XF86AudioMute" = {
        allow-when-locked = true;
        action.spawn = ["noctalia" "msg" "volume-mute"];
      };
      "XF86AudioMicMute" = {
        allow-when-locked = true;
        action.spawn = ["noctalia" "msg" "mic-mute"];
      };

      "XF86AudioPlay" = {
        allow-when-locked = true;
        action.spawn = ["noctalia" "msg" "media" "toggle"];
      };
      "XF86AudioPause" = {
        allow-when-locked = true;
        action.spawn = ["noctalia" "msg" "media" "toggle"];
      };
      "XF86AudioPrev" = {
        allow-when-locked = true;
        action.spawn = ["noctalia" "msg" "media" "previous"];
      };
      "XF86AudioNext" = {
        allow-when-locked = true;
        action.spawn = ["noctalia" "msg" "media" "next"];
      };

      "XF86MonBrightnessUp" = {
        allow-when-locked = true;
        action.spawn = ["noctalia" "msg" "brightness-up"];
      };
      "XF86MonBrightnessDown" = {
        allow-when-locked = true;
        action.spawn = ["noctalia" "msg" "brightness-down"];
      };

      "Print".action.screenshot = [];
      "Ctrl+Print".action.screenshot-screen = [];
      "Alt+Print".action.screenshot-window = [];

      "Mod+Shift+E".action.quit = [];
    };
  };
}
