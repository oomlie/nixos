{
  inputs,
  lib,
  pkgs,
  ...
}: {
  imports = [];

  nixpkgs = {
    config.allowUnfree = true;
    overlays = [inputs.niri.overlays.niri];
  };

  home = {
    username = "mollyw";
    homeDirectory = "/home/mollyw";

    packages = with pkgs; [
      # Niri ecosystem
      fuzzel
      mako
      swaylock
      xwayland-satellite
      swaybg
      brightnessctl
      playerctl
      equibop
    ];
  };

  programs = {
    home-manager.enable = true;

    helix = {
      enable = true;
      defaultEditor = true;
      settings = {
        editor.line-number = "relative";
      };
    };

    git = {
      enable = true;
      settings = {
        user = {
          name = "molly.computer";
          email = "molly@molly.computer";
        };
        init.defaultBranch = "main";
        push.autoSetupRemote = true;
        pull.rebase = false;
        core.editor = "hx";
      };
    };

    vscodium = {
      enable = true;
      profiles.default = {
        extensions = with pkgs.vscode-extensions; [
          rust-lang.rust-analyzer
          jnoortheen.nix-ide
          tamasfe.even-better-toml
          redhat.vscode-yaml
          yzhang.markdown-all-in-one
          dbaeumer.vscode-eslint
          esbenp.prettier-vscode
          usernamehw.errorlens
          gruntfuggly.todo-tree
          aaron-bond.better-comments
          (pkgs.vscode-utils.buildVscodeExtension {
            pname = "kimi-code";
            version = "0.5.10";
            vscodeExtPublisher = "moonshot-ai";
            vscodeExtName = "kimi-code";
            vscodeExtUniqueId = "moonshot-ai.kimi-code";
            src = pkgs.fetchurl {
              name = "kimi-code.vsix";
              url = "https://open-vsx.org/api/moonshot-ai/kimi-code/linux-x64/0.5.10/file/moonshot-ai.kimi-code-0.5.10@linux-x64.vsix";
              sha256 = "1pfdhbcvbb344mvdmmbymzlw8kzgkw6sxl9frmd9jx76pbgx3w9l";
            };
          })
          (pkgs.vscode-utils.buildVscodeExtension {
            pname = "git-graph";
            version = "1.30.0";
            vscodeExtPublisher = "mhutchie";
            vscodeExtName = "git-graph";
            vscodeExtUniqueId = "mhutchie.git-graph";
            src = pkgs.fetchurl {
              name = "git-graph.vsix";
              url = "https://open-vsx.org/api/mhutchie/git-graph/1.30.0/file/mhutchie.git-graph-1.30.0.vsix";
              sha256 = "0bsmvcxl5jg2qzhxx3mm2ki5xqp79mp2hf333m1ka413nvas7fm6";
            };
          })
        ];
        userSettings = {
          "editor.fontFamily" = lib.mkForce "'ComicShannsMono Nerd Font Mono'";
        };
      };
    };

    # Part H: Firefox declarative profile
    firefox = {
      enable = true;
      profiles.mollyw = {
        id = 0;
        isDefault = true;
        settings = {
          "toolkit.telemetry.enabled" = false;
          "toolkit.telemetry.unified" = false;
          "datareporting.healthreport.uploadEnabled" = false;
          "browser.newtabpage.activity-stream.showSponsored" = false;
          "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
          "extensions.pocket.enabled" = false;
          "browser.toolbars.bookmarks.visibility" = "always";
          "font.name.monospace.x-western" = "ComicShannsMono Nerd Font Mono";
          "font.name.sans-serif.x-western" = "ComicShannsMono Nerd Font";
          "font.name.serif.x-western" = "ComicShannsMono Nerd Font";
        };
        extensions.packages = [
          inputs.firefox-addons.packages.${pkgs.stdenv.hostPlatform.system}.ublock-origin
        ];
      };
    };

    # Part J: zsh + starship
    zsh = {
      enable = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      history = {
        size = 50000;
        ignoreDups = true;
        share = true;
      };
    };
    starship.enable = true;

    # Part J: direnv + nix-direnv
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    # Part J: Shell QoL
    fzf.enable = true;
    zoxide.enable = true;
    bat.enable = true;
    eza = {
      enable = true;
      icons = "auto";
    };

    # Part J: btop
    btop = {
      enable = true;
    };

    # Part J: Foot terminal
    foot = {
      enable = true;
      settings = {
        main = {
          font = lib.mkForce "ComicShannsMono Nerd Font Mono:size=11";
          pad = "8x8";
        };
        colors = {
          alpha = 0.92;
        };
      };
    };
  };


  # opencode configuration with Kimi OAuth plugin
  xdg.configFile."opencode/opencode.json".text = builtins.toJSON {
    "$schema" = "https://opencode.ai/config.json";
    plugin = ["opencode-kimi-full"];
    provider = {
      "kimi-for-coding-oauth" = {
        name = "Kimi For Coding (OAuth)";
        npm = "@ai-sdk/openai-compatible";
        options = {
          baseURL = "https://api.kimi.com/coding/v1";
        };
        models = {
          "kimi-for-coding" = {
            name = "Kimi For Coding";
            attachment = true;
            reasoning = true;
            modalities = {
              input = ["text" "image"];
              output = ["text"];
            };
            options = {};
            variants = {
              off = {reasoning_effort = "off";};
              auto = {reasoning_effort = "auto";};
              low = {reasoning_effort = "low";};
              medium = {reasoning_effort = "medium";};
              high = {reasoning_effort = "high";};
            };
          };
        };
      };
    };
  };

  # Improved Kimi plugin activation script
  home.activation.installOpencodeKimiPlugin = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if command -v opencode >/dev/null 2>&1 && [ ! -d "$HOME/.config/opencode/plugin/opencode-kimi-full" ]; then
      echo "Installing opencode-kimi-full plugin..."
      opencode plugin opencode-kimi-full --global || echo "warning: opencode-kimi-full install failed, run manually later"
    fi
  '';

  # Niri compositor configuration
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
        active.color = "#89b4fa";
        inactive.color = "#45475a";
      };
      border.enable = false;
    };

    spawn-at-startup = [
      { argv = [ "swaybg" "--image" "/home/mollyw/nixos/wallpapers/dogg.jpg" ]; }
      { argv = [ "mako" ]; }
      { argv = [ "xwayland-satellite" ]; }
    ];

    screenshot-path = "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png";

    binds = {
      "Mod+Shift+Slash".action.show-hotkey-overlay = [];

      "Mod+Return" = {
        hotkey-overlay.title = "Open Terminal: foot";
        action.spawn = "foot";
      };
      "Mod+D" = {
        hotkey-overlay.title = "Run Application: fuzzel";
        action.spawn = "fuzzel";
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
        action.spawn = [ "brightnessctl" "--class=backlight" "set" "+10%" ];
      };
      "XF86MonBrightnessDown" = {
        allow-when-locked = true;
        action.spawn = [ "brightnessctl" "--class=backlight" "set" "10%-" ];
      };

      "Print".action.screenshot = [];
      "Ctrl+Print".action.screenshot-screen = [];
      "Alt+Print".action.screenshot-window = [];

      "Mod+Shift+E".action.quit = [];
    };
  };

  # Waybar status bar for niri (styled by Stylix)
  programs.waybar = {
    enable = true;
    systemd.enable = true;
    settings.mainBar = {
      layer = "top";
      position = "top";
      height = 34;
      spacing = 4;
      modules-left = ["niri/workspaces" "niri/window"];
      modules-center = ["clock"];
      modules-right = ["wireplumber" "battery" "network" "tray"];
      "niri/workspaces" = {};
      "niri/window" = {
        max-length = 50;
      };
      clock = {
        format = "{:%Y-%m-%d %H:%M}";
        tooltip-format = "<big>{:%Y %B}</big>\n<tt>{calendar}";
      };
      wireplumber = {
        format = "{volume}%";
        format-muted = "muted";
        on-click = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
      };
      battery = {
        format = "{capacity}% {icon}";
        format-icons = ["" "" "" "" ""];
        states = {
          warning = 30;
          critical = 15;
        };
      };
      network = {
        format-wifi = "{essid} ({signalStrength}%)";
        format-ethernet = "{ipaddr}/{cidr}";
        format-disconnected = "offline";
      };
      tray = {
        spacing = 10;
      };
    };
  };

  # Stylix auto-generated theme from wallpaper
  stylix = {
    enable = true;
    image = ../wallpapers/dogg.jpg;
    fonts = {
      serif = {
        package = pkgs.nerd-fonts.comic-shanns-mono;
        name = "ComicShannsMono Nerd Font";
      };
      sansSerif = {
        package = pkgs.nerd-fonts.comic-shanns-mono;
        name = "ComicShannsMono Nerd Font";
      };
      monospace = {
        package = pkgs.nerd-fonts.comic-shanns-mono;
        name = "ComicShannsMono Nerd Font Mono";
      };
      emoji = {
        package = pkgs.noto-fonts-color-emoji;
        name = "Noto Color Emoji";
      };
    };
    targets = {
      helix.enable = true;
      foot.enable = true;
      btop.enable = true;
      vscode.enable = true;
      firefox = {
        enable = true;
        profileNames = ["mollyw"];
      };
      waybar.enable = true;
      niri.enable = true;
      gtk.enable = true;
    };
  };

  # stateVersion is a compatibility pin — do not change on every upgrade
  home.stateVersion = "26.05";
}
