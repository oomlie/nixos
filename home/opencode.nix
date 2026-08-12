{
  inputs,
  lib,
  pkgs,
  ...
}: {
  programs.opencode = {
    enable = true;

    settings = {
      small_model = "openai/gpt-5.6-luna-fast";
      plugin = ["opencode-kimi-full@1.4.0"];
      share = "disabled";
      autoupdate = false;

      agent = {
        general = {
          model = "openai/gpt-5.6-luna-fast";
          mode = "subagent";
          permission = {
            edit = "allow";
            bash = "ask";
            external_directory = "ask";
          };
        };
        explore = {
          model = "openai/gpt-5.6-luna-fast";
          mode = "subagent";
          permission = {
            edit = "deny";
            bash = "deny";
          };
        };
        scout = {
          model = "openai/gpt-5.6-luna-fast";
          mode = "subagent";
          permission.edit = "deny";
        };
      };

      compaction = {
        auto = true;
        prune = true;
        reserved = 12000;
      };
      watcher.ignore = [
        ".git/**"
        "node_modules/**"
        "result"
        "result-*"
        "dist/**"
        "build/**"
        ".direnv/**"
      ];
      formatter = true;
      lsp = true;

      mcp.firecrawl = {
        type = "remote";
        url = "https://mcp.firecrawl.dev/v2/mcp-oauth";
        enabled = true;
      };

      provider = {
        halo = {
          name = "Strix Halo (halo.daze.lol)";
          npm = "@ai-sdk/openai-compatible";
          options = {
            baseURL = "https://gateway.ai.cloudflare.com/v1/ab50bec72354666a941823793fef426a/halo/custom-halo/v1";
            apiKey = "{env:HALO_API_KEY}";
          };
          models."gpt-oss-120b" = {
            name = "gpt-oss 120B MXFP4 (Strix Halo)";
            attachment = false;
            reasoning = true;
            modalities = {
              input = ["text"];
              output = ["text"];
            };
            options = {};
            limit = {
              context = 131072;
              output = 8192;
            };
          };
        };
        "kimi-for-coding-oauth" = {
          name = "Kimi For Coding (OAuth)";
          npm = "@ai-sdk/openai-compatible";
          options.baseURL = "https://api.kimi.com/coding/v1";
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
                off.reasoning_effort = "off";
                auto.reasoning_effort = "auto";
                low.reasoning_effort = "low";
                medium.reasoning_effort = "medium";
                high.reasoning_effort = "high";
              };
            };
            k3 = {
              name = "Kimi K3";
              attachment = true;
              reasoning = true;
              modalities = {
                input = ["text" "image"];
                output = ["text"];
              };
              options = {};
              variants.max.reasoning_effort = "max";
            };
          };
        };
      };
    };

    tui = {
      diff_style = "auto";
      scroll_speed = 3;
      mouse = true;
      attention = {
        enabled = true;
        notifications = true;
        sound = false;
      };
    };

    context = ./opencode/AGENTS.md;
    agents = ./opencode/agents;
    commands = ./opencode/commands;
    skills.hunk-review = "${inputs.hunk.packages.${pkgs.stdenv.hostPlatform.system}.hunk}/skills/hunk-review";
  };

  # These must be real files: Bun resolves @opencode-ai/plugin relative to
  # their physical path, and store symlinks cannot see the runtime node_modules.
  home.activation.installOpencodeTools = lib.hm.dag.entryAfter ["writeBoundary"] ''
    toolsDir="$HOME/.config/opencode/tools"
    mkdir -p "$toolsDir"
    for f in ${./opencode/tools}/*.ts; do
      install -m 0644 "$f" "$toolsDir/$(basename "$f")"
    done
  '';
}
