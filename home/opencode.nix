{
  inputs,
  lib,
  pkgs,
  giteaCredentialHelper,
  ...
}: let
  models = {
    primary = "route/gpt-5.6-sol";
    small = "route/gpt-5.6-luna";
    worker = "route/gpt-5.6-luna";
  };
  ponytail = pkgs.fetchFromGitHub {
    owner = "DietrichGebert";
    repo = "ponytail";
    rev = "0a4dd63ad4541f4f655c4108a295916f3c1d8fda";
    hash = "sha256-8cYggVltBAlZ/Zj4pl1bOu7mQdZFXCmDGW4RSpvRA+w=";
  };
  opencode = pkgs.writeShellApplication {
    name = "opencode";
    runtimeInputs = [pkgs.libsecret];
    text = ''
      ROUTE_API_KEY="$(secret-tool lookup service cliproxy host route.daze.lol user molly || true)"
      if [[ -z "$ROUTE_API_KEY" ]]; then
        echo "opencode: route.daze.lol API key not found in the keyring" >&2
        exit 1
      fi
      export ROUTE_API_KEY

      DAZE_API_KEY="$ROUTE_API_KEY"
      export DAZE_API_KEY

      FLUX_MCP_TOKEN="$(secret-tool lookup service flux-mcp host kanban-mcp.daze.lol user molly || true)"
      if [[ -z "$FLUX_MCP_TOKEN" ]]; then
        echo "opencode: Flux MCP token not found in the keyring" >&2
        exit 1
      fi
      export FLUX_MCP_TOKEN

      exec ${pkgs.opencode}/bin/opencode "$@"
    '';
  };
in {
  programs.opencode = {
    enable = true;
    package = opencode;

    settings = {
      model = models.primary;
      small_model = models.small;
      enabled_providers = ["route" "daze"];
      references.agent-wiki = {
        path = "./wiki";
        description = "Private, curated cross-session knowledge for durable decisions, preferences, project context, and runbooks. Search it before asking for information that may have been established previously.";
      };
      share = "disabled";
      autoupdate = false;

      agent = {
        general = {
          model = models.worker;
          mode = "subagent";
          permission = {
            edit = "allow";
            bash = "ask";
            external_directory = "ask";
          };
        };
        explore = {
          model = models.worker;
          mode = "subagent";
          permission = {
            edit = "deny";
            bash = "deny";
          };
        };
        scout = {
          model = models.worker;
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

      plugin = [
        ./opencode/plugins/route-models.js
        "${ponytail}/.opencode/plugins/ponytail.mjs"
      ];

      mcp.firecrawl = {
        type = "remote";
        url = "https://mcp.firecrawl.dev/v2/mcp-oauth";
        enabled = true;
      };
      mcp.flux = {
        type = "remote";
        url = "https://kanban-mcp.daze.lol/mcp";
        enabled = true;
        headers.Authorization = "Bearer {env:FLUX_MCP_TOKEN}";
      };

      provider = {
        daze = {
          name = "Daze";
          npm = "@ai-sdk/openai-compatible";
          options = {
            baseURL = "https://route.daze.lol/v1";
            apiKey = "{env:DAZE_API_KEY}";
          };
          models."gemini-4-argon-highGemini" = {
            name = "Gemini 4 Argon HighGemini";
          };
        };
        route = {
          name = "route.daze.lol";
          npm = "@ai-sdk/openai";
          options = {
            baseURL = "https://route.daze.lol/v1";
            apiKey = "{env:ROUTE_API_KEY}";
          };
          models = {
            "gpt-5.6-sol" = {
              name = "GPT-5.6 Sol";
              attachment = true;
              reasoning = true;
              modalities = {
                input = ["text" "image"];
                output = ["text"];
              };
              limit = {
                context = 372000;
                output = 128000;
              };
            };
            "gpt-5.6-luna" = {
              name = "GPT-5.6 Luna";
              attachment = true;
              reasoning = true;
              modalities = {
                input = ["text" "image"];
                output = ["text"];
              };
              limit = {
                context = 372000;
                output = 128000;
              };
            };
            "gpt-5.6-terra" = {
              name = "GPT-5.6 Terra";
              attachment = true;
              reasoning = true;
              modalities = {
                input = ["text" "image"];
                output = ["text"];
              };
              limit = {
                context = 372000;
                output = 128000;
              };
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

  # Keep the mutable wiki checkout outside Home Manager's immutable file links.
  # Never reset or overwrite local changes during activation.
  home.activation.updateAgentWiki = lib.hm.dag.entryAfter ["writeBoundary"] ''
    wikiDir="$HOME/.config/opencode/wiki"
    wikiUrl="https://git.purplish.blue/molly/agent-wiki"
    wikiGit="${pkgs.git}/bin/git -c credential.helper= -c credential.helper=${giteaCredentialHelper}"

    if [[ ! -e "$wikiDir/.git" ]]; then
      if [[ -d "$wikiDir" ]] && [[ -n "$(ls -A "$wikiDir")" ]]; then
        echo "agent-wiki: $wikiDir exists and is not a Git checkout; leaving it unchanged" >&2
      else
        if ! $wikiGit clone "$wikiUrl" "$wikiDir"; then
          echo "agent-wiki: clone failed; the next activation will retry" >&2
        fi
      fi
    elif [[ "$(${pkgs.git}/bin/git -C "$wikiDir" remote get-url origin)" != "$wikiUrl" ]]; then
      echo "agent-wiki: unexpected origin; leaving $wikiDir unchanged" >&2
    elif [[ -n "$(${pkgs.git}/bin/git -C "$wikiDir" status --porcelain)" ]]; then
      echo "agent-wiki: local changes present; skipping automatic pull" >&2
    elif [[ "$(${pkgs.git}/bin/git -C "$wikiDir" branch --show-current)" != main ]]; then
      echo "agent-wiki: not on main; skipping automatic pull" >&2
    elif ! $wikiGit -C "$wikiDir" pull --ff-only origin main; then
      echo "agent-wiki: fast-forward pull failed; leaving the checkout unchanged" >&2
    fi
  '';

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
