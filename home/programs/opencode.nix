{lib, ...}: {
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
}
