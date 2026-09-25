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

      OPENCODE_API_KEY="$(secret-tool lookup service opencode host opencode.ai user molly || true)"
      if [[ -n "$OPENCODE_API_KEY" ]]; then
        export OPENCODE_API_KEY
      else
        echo "opencode: OpenCode Go/Zen API key not found in the keyring; opencode-go/* models unavailable" >&2
      fi

      OPENROUTER_API_KEY="$(secret-tool lookup service openrouter host openrouter.ai user molly || true)"
      if [[ -n "$OPENROUTER_API_KEY" ]]; then
        export OPENROUTER_API_KEY
      else
        echo "opencode: OpenRouter API key not found in the keyring; openrouter/* models unavailable" >&2
      fi

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
      enabled_providers = ["route" "openrouter" "opencode-go"];
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
        route = {
          name = "route.daze.lol";
          npm = "@ai-sdk/openai";
          options = {
            baseURL = "https://route.daze.lol/v1";
            apiKey = "{env:ROUTE_API_KEY}";
          };
          models = let
            explicitModels = {
              "claude-haiku-4-5-20251001" = {
                name = "Claude 4.5 Haiku";
                attachment = true;
                reasoning = true;
                modalities = {
                  input = ["text" "image"];
                  output = ["text"];
                };
                limit = {
                  context = 200000;
                  output = 64000;
                };
              };
              "claude-sonnet-4-5-20250929" = {
                name = "Claude 4.5 Sonnet";
                attachment = true;
                reasoning = true;
                modalities = {
                  input = ["text" "image"];
                  output = ["text"];
                };
                limit = {
                  context = 200000;
                  output = 64000;
                };
              };
              "claude-sonnet-4-6" = {
                name = "Claude 4.6 Sonnet";
                attachment = true;
                reasoning = true;
                modalities = {
                  input = ["text" "image"];
                  output = ["text"];
                };
                limit = {
                  context = 200000;
                  output = 64000;
                };
              };
              "claude-opus-4-6" = {
                name = "Claude 4.6 Opus";
                attachment = true;
                reasoning = true;
                modalities = {
                  input = ["text" "image"];
                  output = ["text"];
                };
                limit = {
                  context = 1000000;
                  output = 128000;
                };
              };
              "claude-opus-4-7" = {
                name = "Claude Opus 4.7";
                attachment = true;
                reasoning = true;
                modalities = {
                  input = ["text" "image"];
                  output = ["text"];
                };
                limit = {
                  context = 1000000;
                  output = 128000;
                };
              };
              "claude-opus-4-8" = {
                name = "Claude Opus 4.8";
                attachment = true;
                reasoning = true;
                modalities = {
                  input = ["text" "image"];
                  output = ["text"];
                };
                limit = {
                  context = 1000000;
                  output = 128000;
                };
              };
              "claude-opus-5" = {
                name = "Claude Opus 5";
                attachment = true;
                reasoning = true;
                modalities = {
                  input = ["text" "image"];
                  output = ["text"];
                };
                limit = {
                  context = 1000000;
                  output = 128000;
                };
              };
              "claude-sonnet-5" = {
                name = "Claude Sonnet 5";
                attachment = true;
                reasoning = true;
                modalities = {
                  input = ["text" "image"];
                  output = ["text"];
                };
                limit = {
                  context = 1000000;
                  output = 128000;
                };
              };
              "claude-fable-5" = {
                name = "Claude Fable 5";
                attachment = true;
                reasoning = true;
                modalities = {
                  input = ["text" "image"];
                  output = ["text"];
                };
                limit = {
                  context = 1000000;
                  output = 128000;
                };
              };
              "claude-opus-4-5-20251101" = {
                name = "Claude 4.5 Opus";
                attachment = true;
                reasoning = true;
                modalities = {
                  input = ["text" "image"];
                  output = ["text"];
                };
                limit = {
                  context = 200000;
                  output = 64000;
                };
              };
              "claude-opus-4-1-20250805" = {
                name = "Claude 4.1 Opus";
                attachment = true;
                reasoning = true;
                modalities = {
                  input = ["text" "image"];
                  output = ["text"];
                };
                limit = {
                  context = 200000;
                  output = 32000;
                };
              };
              "claude-opus-4-20250514" = {
                name = "Claude 4 Opus";
                attachment = true;
                reasoning = true;
                modalities = {
                  input = ["text" "image"];
                  output = ["text"];
                };
                limit = {
                  context = 200000;
                  output = 32000;
                };
              };
              "claude-sonnet-4-20250514" = {
                name = "Claude 4 Sonnet";
                attachment = true;
                reasoning = true;
                modalities = {
                  input = ["text" "image"];
                  output = ["text"];
                };
                limit = {
                  context = 200000;
                  output = 64000;
                };
              };
              "claude-3-7-sonnet-20250219" = {
                name = "Claude 3.7 Sonnet";
                attachment = true;
                reasoning = true;
                modalities = {
                  input = ["text" "image"];
                  output = ["text"];
                };
                limit = {
                  context = 128000;
                  output = 8192;
                };
              };
              "claude-3-5-haiku-20241022" = {
                name = "Claude 3.5 Haiku";
                attachment = false;
                reasoning = false;
                modalities = {
                  input = ["text"];
                  output = ["text"];
                };
                limit = {
                  context = 128000;
                  output = 8192;
                };
              };
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
              "deepseek-platform-flash" = {
                name = "DeepSeek V4.1 Flash (Platform)";
                attachment = true;
                reasoning = true;
                modalities = {
                  input = ["text" "image"];
                  output = ["text"];
                };
                limit = {
                  context = 1048576;
                  output = 393216;
                };
              };
              "deepseek-platform-v4-pro" = {
                name = "DeepSeek V4 Pro (Platform)";
                attachment = false;
                reasoning = true;
                modalities = {
                  input = ["text"];
                  output = ["text"];
                };
                limit = {
                  context = 1048576;
                  output = 393216;
                };
              };
              "gpt-5.5" = {
                name = "GPT-5.5";
                attachment = true;
                reasoning = true;
                modalities = {
                  input = ["text" "image"];
                  output = ["text"];
                };
                limit = {
                  context = 272000;
                  output = 128000;
                };
              };
              "gpt-5.3-codex-spark" = {
                name = "GPT-5.3 Codex Spark";
                attachment = true;
                reasoning = true;
                modalities = {
                  input = ["text" "image" "pdf"];
                  output = ["text"];
                };
                limit = {
                  context = 128000;
                  input = 100000;
                  output = 32000;
                };
              };
              "codex-auto-review" = {
                name = "Codex Auto Review";
                attachment = true;
                reasoning = true;
                modalities = {
                  input = ["text" "image"];
                  output = ["text"];
                };
                limit = {
                  context = 272000;
                  output = 128000;
                };
              };
              "grok-4.6" = {
                name = "Grok 4.6";
                attachment = true;
                reasoning = true;
                modalities = {
                  input = ["text" "image" "pdf"];
                  output = ["text"];
                };
                limit = {
                  context = 500000;
                  output = 500000;
                };
              };
              "grok-4.5" = {
                name = "Grok 4.5";
                attachment = true;
                reasoning = true;
                modalities = {
                  input = ["text" "image" "pdf"];
                  output = ["text"];
                };
                limit = {
                  context = 500000;
                  output = 500000;
                };
              };
              "grok-4.3" = {
                name = "Grok 4.3";
                attachment = true;
                reasoning = true;
                modalities = {
                  input = ["text" "image" "pdf"];
                  output = ["text"];
                };
                limit = {
                  context = 1000000;
                  output = 30000;
                };
              };
              "grok-build-0.1" = {
                name = "Grok Build 0.1";
                attachment = true;
                reasoning = true;
                modalities = {
                  input = ["text" "image" "pdf"];
                  output = ["text"];
                };
                limit = {
                  context = 256000;
                  output = 256000;
                };
              };
              "grok-4.20-0309-reasoning" = {
                name = "Grok 4.20 0309 Reasoning";
                attachment = true;
                reasoning = true;
                modalities = {
                  input = ["text" "image"];
                  output = ["text"];
                };
                limit = {
                  context = 2000000;
                  output = 65536;
                };
              };
              "grok-4.20-0309-non-reasoning" = {
                name = "Grok 4.20 0309 Non Reasoning";
                attachment = true;
                reasoning = false;
                modalities = {
                  input = ["text" "image"];
                  output = ["text"];
                };
                limit = {
                  context = 2000000;
                  output = 65536;
                };
              };
              "grok-4.20-multi-agent-0309" = {
                name = "Grok 4.20 Multi Agent 0309";
                attachment = true;
                reasoning = true;
                modalities = {
                  input = ["text" "image"];
                  output = ["text"];
                };
                limit = {
                  context = 2000000;
                  output = 65536;
                };
              };
              "grok-3-mini" = {
                name = "Grok 3 Mini";
                attachment = false;
                reasoning = true;
                modalities = {
                  input = ["text"];
                  output = ["text"];
                };
                limit = {
                  context = 131072;
                  output = 32768;
                };
              };
              "grok-3-mini-fast" = {
                name = "Grok 3 Mini Fast";
                attachment = false;
                reasoning = true;
                modalities = {
                  input = ["text"];
                  output = ["text"];
                };
                limit = {
                  context = 131072;
                  output = 32768;
                };
              };
              "grok-composer-2.5-fast" = {
                name = "Composer 2.5 Fast";
                attachment = false;
                reasoning = false;
                modalities = {
                  input = ["text"];
                  output = ["text"];
                };
                limit = {
                  context = 200000;
                  output = 32768;
                };
              };
              k3 = {
                name = "Kimi K3 (1M)";
                attachment = true;
                reasoning = true;
                limit = {
                  context = 1048576;
                  output = 32768;
                };
              };
              "k3-256k" = {
                name = "Kimi K3 (256K)";
                attachment = true;
                reasoning = true;
                limit = {
                  context = 262144;
                  output = 32768;
                };
              };
              "kimi-for-coding" = {
                name = "Kimi K2.7 Code";
                attachment = true;
                reasoning = true;
                limit = {
                  context = 262144;
                  output = 32768;
                };
              };
              "kimi-for-coding-highspeed" = {
                name = "Kimi K2.7 Code HighSpeed";
                attachment = true;
                reasoning = true;
                limit = {
                  context = 262144;
                  output = 32768;
                };
              };
              "qwen-audio-3.0-realtime-plus" = {
                name = "Qwen Audio 3.0 Realtime Plus";
                reasoning = false;
              };
              "qwen-audio-3.0-tts-plus" = {
                name = "Qwen Audio 3.0 TTS Plus";
                reasoning = false;
              };
              "gemini-3.1-flash-image" = {
                name = "gemini-3.1-flash-image";
                reasoning = false;
              };
              "gpt-image-1.5" = {
                name = "gpt-image-1.5";
                reasoning = false;
              };
              "gpt-image-2" = {
                name = "gpt-image-2";
                reasoning = false;
              };
              "grok-imagine-image" = {
                name = "grok-imagine-image";
                reasoning = false;
              };
              "grok-imagine-image-2.0" = {
                name = "grok-imagine-image-2.0";
                reasoning = false;
              };
              "grok-imagine-image-quality" = {
                name = "grok-imagine-image-quality";
                reasoning = false;
              };
              "grok-imagine-video" = {
                name = "grok-imagine-video";
                reasoning = false;
              };
              "grok-imagine-video-1.5" = {
                name = "grok-imagine-video-1.5";
                reasoning = false;
              };
              "grok-imagine-video-1.5-preview" = {
                name = "grok-imagine-video-1.5-preview";
                reasoning = false;
              };
              "wan2.7-image" = {
                name = "wan2.7-image";
                reasoning = false;
              };
              "wan2.7-image-pro" = {
                name = "wan2.7-image-pro";
                reasoning = false;
              };
            };
          in
            explicitModels
            // lib.genAttrs
            (lib.subtractLists (builtins.attrNames explicitModels) [
              "claude-3-5-haiku-20241022"
              "claude-3-7-sonnet-20250219"
              "claude-fable-5"
              "claude-fable-5-1"
              "claude-haiku-4-5-20251001"
              "claude-opus-4-20250514"
              "claude-opus-4-1-20250805"
              "claude-opus-4-5-20251101"
              "claude-opus-4-6-thinking"
              "claude-opus-4-7"
              "claude-opus-4-8"
              "claude-opus-5"
              "claude-sonnet-4-20250514"
              "claude-sonnet-4-5-20250929"
              "deepseek-v4-flash-0731"
              "deepseek-v4-pro"
              "gemini-3-flash"
              "gemini-3.1-flash-lite"
              "gemini-3.1-pro-low"
              "gemini-3.6-flash-high"
              "gemini-3.7-flash-high"
              "gemini-3.8-flash-high"
              "gemini-pro-agent"
              "glm-5.2"
              "gpt-6-astra"
              "gpt-oss-120b-medium"
              "qwen3.6-flash"
              "qwen3.7-max"
              "qwen3.7-plus"
              "qwen3.8-flash"
              "qwen3.8-max"
            ])
            (id: {
              name = id;
              reasoning = true;
            });
        };
        openrouter = {
          name = "OpenRouter";
          options = {
            apiKey = "sk-or-v1-REDACTED-ROTATED-20261014";
          };
          models = {
            "deepseek/deepseek-v4-flash" = {
              name = "DeepSeek V4 Flash";
              attachment = false;
              reasoning = true;
              modalities = {
                input = ["text"];
                output = ["text"];
              };
              limit = {
                context = 1048576;
                output = 393216;
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
