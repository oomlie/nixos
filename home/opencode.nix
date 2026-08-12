{lib, ...}: {
  # opencode configuration with Kimi OAuth plugin
  xdg.configFile."opencode/opencode.json".text = builtins.toJSON {
    "$schema" = "https://opencode.ai/config.json";
    plugin = ["opencode-kimi-full"];
    provider = {
      halo = {
        name = "Strix Halo (halo.daze.lol)";
        npm = "@ai-sdk/openai-compatible";
        options = {
          baseURL = "https://gateway.ai.cloudflare.com/v1/ab50bec72354666a941823793fef426a/halo/custom-halo/v1";
          apiKey = "{env:HALO_API_KEY}";
        };
        models = {
          "gpt-oss-120b" = {
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
      };
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
          "k3" = {
            name = "Kimi K3";
            attachment = true;
            reasoning = true;
            modalities = {
              input = ["text" "image"];
              output = ["text"];
            };
            options = {};
            variants = {
              max = {reasoning_effort = "max";};
            };
          };
        };
      };
    };
  };

  # Custom opencode tools must be REAL files under ~/.config/opencode, not
  # store symlinks: opencode's embedded Bun runtime resolves imports relative
  # to the symlink's real path, so `import { tool } from "@opencode-ai/plugin"`
  # fails from /nix/store (no node_modules up that tree). Copy them instead so
  # resolution walks up to ~/.config/opencode/node_modules.
  home.activation.installOpencodeTools = lib.hm.dag.entryAfter ["writeBoundary"] ''
    toolsDir="$HOME/.config/opencode/tools"
    mkdir -p "$toolsDir"
    for f in ${./opencode/tools}/*.ts; do
      install -m 0644 "$f" "$toolsDir/$(basename "$f")"
    done
  '';

  # Install the Kimi plugin once opencode is on PATH; best-effort so a
  # network hiccup during rebuild doesn't fail the activation
  home.activation.installOpencodeKimiPlugin = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if command -v opencode >/dev/null 2>&1 && [ ! -d "$HOME/.config/opencode/plugin/opencode-kimi-full" ]; then
      echo "Installing opencode-kimi-full plugin..."
      opencode plugin opencode-kimi-full --global || echo "warning: opencode-kimi-full install failed, run manually later"
    fi
  '';
}
