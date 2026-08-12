{
  config,
  pkgs,
  khalNextEventRead,
  weatherDc,
  ...
}: let
  colors = config.lib.stylix.colors;
in {
  home.packages = [pkgs.ironbar];

  xdg.configFile."ironbar/config.json".text = builtins.toJSON {
    position = "top";
    anchor_to_edges = true;
    height = 44;
    start = [
      {
        type = "custom";
        class = "tablet-controls";
        bar = [
          {
            type = "button";
            label = "󰀻";
            tooltip = "Applications";
            on_click = "!vicinae vicinae://toggle";
          }
          {
            type = "button";
            label = "󰕰";
            tooltip = "Overview";
            on_click = "!niri msg action toggle-overview";
          }
          {
            type = "button";
            label = "󰌌";
            tooltip = "On-screen keyboard";
            on_click = "!systemctl --user kill --signal=RTMIN tablet-keyboard.service";
          }
          {
            type = "button";
            label = "󰅖";
            tooltip = "Close window";
            on_click = "!niri msg action close-window";
          }
          {
            type = "button";
            label = "󰌾";
            tooltip = "Lock";
            on_click = "!swaylock";
          }
        ];
      }
      {
        type = "workspaces";
        format = "{index}";
        sort = "index";
        on_scroll_up = "niri msg action focus-workspace-up";
        on_scroll_down = "niri msg action focus-workspace-down";
      }
      {
        type = "focused";
        show_icon = false;
        truncate = {
          mode = "end";
          max_length = 25;
        };
      }
      {
        type = "music";
        format = "{title} / {artist}";
        show_status_icon = true;
        icon_size = 16;
        cover_image_size = 128;
        marquee = {
          enable = true;
          max_length = 40;
          scroll_speed = 0.5;
          on_hover = "pause";
        };
        truncate_popup_title = {
          mode = "end";
          max_length = 60;
        };
        icons = {
          play = "";
          pause = "";
          prev = "󰒮";
          next = "󰒭";
          volume = "󰕾";
          track = "󰎈";
          album = "󰀥";
          artist = "󰠃";
        };
      }
    ];
    center = [
      {
        type = "clock";
        format = "%m/%d %I:%M %p";
      }
      {
        type = "script";
        name = "khal";
        cmd = "${khalNextEventRead}";
        mode = "poll";
        interval = 60000;
        tooltip = "Next upcoming event from khal";
        on_click_left = "foot -e ikhal";
      }
    ];
    end = [
      {
        type = "volume";
        name = "mic";
        show_sinks = false;
        format = "{icon} {percentage}%";
        mute_format = "󰍭 muted";
        icons.mic_volume = "󰍬";
        icons.mic_muted = "󰍭";
        on_click_middle = "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
      }
      {
        type = "volume";
        show_sources = false;
        format = "{icon} {percentage}%";
        mute_format = "󰖁 muted";
        icons.muted = "󰖁";
        on_click_middle = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
      }
      {
        type = "battery";
        show_icon = false;
        format = "󰁹";
        tooltip = "{{30000:echo \"$(cat /sys/class/power_supply/BAT1/capacity)% ($(cat /sys/class/power_supply/BAT1/status))\"}}";
        profiles = {
          charging = {
            when = {
              percent = 100;
              charging = true;
            };
            format = "󰂄";
          };
          p90 = {
            when = {
              percent = 90;
              charging = false;
            };
            format = "󰂂";
          };
          p70 = {
            when = {
              percent = 70;
              charging = false;
            };
            format = "󰂀";
          };
          p50 = {
            when = {
              percent = 50;
              charging = false;
            };
            format = "󰁾";
          };
          warning = {
            when = {
              percent = 30;
              charging = false;
            };
            format = "󰁼";
          };
          critical = {
            when = {
              percent = 15;
              charging = false;
            };
            format = "󰁺";
          };
        };
      }
      {
        type = "script";
        name = "weather";
        cmd = "${weatherDc}/bin/weather-dc";
        mode = "poll";
        interval = 600000;
        tooltip = "Washington, DC";
      }
      {
        type = "tray";
        icon_size = 18;
      }
    ];
  };

  xdg.configFile."ironbar/style.css".text = ''
    * {
      font-family: "${config.stylix.fonts.monospace.name}";
      font-size: 13px;
    }

    .bar {
      background-color: #${colors.base00};
      color: #${colors.base05};
    }

    #bar button {
      background: none;
      border: none;
      border-radius: 0;
      box-shadow: none;
      min-width: 0;
      min-height: 0;
      padding: 0 12px;
    }

    .tablet-controls button {
      min-width: 44px;
      min-height: 44px;
      padding: 0;
      font-size: 18px;
    }

    .workspaces .item.focused {
      color: #${colors.base0D};
    }

    .music .contents .icon {
      color: #${colors.base0B};
      padding-right: 4px;
    }

    .popup-music {
      background-color: #${colors.base00};
      border: 1px solid #${colors.base02};
      border-radius: 8px;
      padding: 12px;
    }

    .popup-music .album-art {
      border-radius: 4px;
      margin-right: 12px;
    }

    .popup-music .title .label {
      color: #${colors.base05};
      font-weight: bold;
    }

    .popup-music .album .label,
    .popup-music .artist .label {
      color: #${colors.base04};
    }

    .popup-music .controls button {
      background: none;
      border: none;
      box-shadow: none;
      color: #${colors.base05};
      padding: 4px 10px;
    }

    .popup-music .controls button:hover {
      color: #${colors.base0D};
    }

    .popup-music .volume .slider,
    .popup-music .progress .slider {
      min-height: 4px;
    }

    .popup-music .volume .slider trough,
    .popup-music .progress .slider trough {
      background-color: #${colors.base02};
      border-radius: 2px;
    }

    .popup-music .volume .slider highlight,
    .popup-music .progress .slider highlight {
      background-color: #${colors.base0D};
      border-radius: 2px;
    }

    .popup-music .progress .label {
      color: #${colors.base04};
    }

    .battery.warning,
    .battery.profile-warning {
      color: #${colors.base0A};
    }

    .battery.critical,
    .battery.profile-critical {
      color: #${colors.base08};
    }
  '';
}
