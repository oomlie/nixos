{lib, ...}: let
  inherit (lib) concatStrings;

  # Symbol-only module (no version text)
  ss = symbol: style: {
    inherit symbol;
    format = "[$symbol ](${style})";
  };
  ssv = symbol: style: {
    inherit symbol;
    format = "via [$symbol](${style})";
  };
in {
  programs.starship = {
    enable = true;
    settings = {
      add_newline = true;

      format = concatStrings [
        "[╭╴](238)$os"
        "$all$character"
      ];

      # ── Second line ──────────────────────────────────────────
      character = {
        success_symbol = "[╰─](238)";
        error_symbol = "[╰─](bold red)";
      };

      cmd_duration = {
        format = "[  $duration]($style)";
        show_milliseconds = false;
        style = "yellow";
      };

      # ── First line ───────────────────────────────────────────
      os = {
        style = "bold white";
        format = "[$symbol]($style) ";
        symbols = {
          NixOS = "";
        };
      };

      username = {
        style_user = "white";
        style_root = "black";
        format = "[$user]($style) ";
        show_always = true;
      };

      directory = {
        truncation_length = 8;
        truncate_to_repo = true;
        home_symbol = "󰋞 ";
        read_only_style = "197";
        read_only = "  ";
        format = "at [$path]($style)[$read_only]($read_only_style) ";

        substitutions = {
          "󰋞 /Documents" = "󰈙 ";
          "󰋞 /documents" = "󰈙 ";

          "󰋞 /Downloads" = " ";
          "󰋞 /downloads" = " ";

          "󰋞 /Music" = " ";
          "󰋞 /Pictures" = " ";
          "󰋞 /Videos" = " ";

          "󰋞 /.config" = " ";
        };
      };

      # ── Language modules (symbol only, no version) ───────────
      container = ss " 󰏖" "yellow dimmed";
      python = ss "" "yellow";
      nodejs = ss " " "yellow";
      lua = ss "󰢱 " "blue";
      rust = ss "" "red";
      java = ss " " "red";
      c = ss " " "blue";
      golang = ss "" "blue";
      docker_context = ss " " "blue";

      nix_shell = ssv " " "blue";

      git_branch = {
        symbol = "󰊢 ";
        format = "on [$symbol$branch]($style) ";
        truncation_length = 4;
        truncation_symbol = "…/";
        style = "bold green";
      };
      git_status = {
        format = "[\\($all_status$ahead_behind\\)]($style) ";
        style = "bold green";
        conflicted = "🏳";
        up_to_date = " ";
        untracked = " ";
        ahead = "⇡\${count}";
        diverged = "⇕⇡\${ahead_count}⇣\${behind_count}";
        behind = "⇣\${count}";
        stashed = "󰏗 ";
        modified = " ";
        staged = "[++\\($count\\)](green)";
        renamed = "󰖷 ";
        deleted = " ";
      };

      battery.disabled = true;
    };
  };
}
