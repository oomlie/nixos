{
  lib,
  pkgs,
  ...
}: let
  package = pkgs.callPackage ../pkgs/polytoken/package.nix {};
  routeModelNames = [
    "claude-3-5-haiku-20241022"
    "claude-3-7-sonnet-20250219"
    "claude-fable-5"
    "claude-haiku-4-5-20251001"
    "claude-opus-4-1-20250805"
    "claude-opus-4-20250514"
    "claude-opus-4-5-20251101"
    "claude-opus-4-6"
    "claude-opus-4-6-thinking"
    "claude-opus-4-7"
    "claude-opus-4-8"
    "claude-opus-5"
    "claude-sonnet-4-20250514"
    "claude-sonnet-4-5-20250929"
    "claude-sonnet-4-6"
    "claude-sonnet-5"
    "codex-auto-review"
    "gemini-3-flash"
    "gemini-3-flash-agent"
    "gemini-3.1-flash-lite"
    "gemini-3.1-pro-low"
    "gemini-3.5-flash-extra-low"
    "gemini-3.5-flash-low"
    "gemini-3.6-flash-high"
    "gemini-3.7-flash-high"
    "gemini-pro-agent"
    "gpt-5.3-codex-spark"
    "gpt-5.4"
    "gpt-5.4-mini"
    "gpt-5.5"
    "gpt-5.6-luna"
    "gpt-5.6-sol"
    "gpt-5.6-terra"
    "gpt-oss-120b-medium"
    "grok-3-mini"
    "grok-3-mini-fast"
    "grok-4.20-0309-non-reasoning"
    "grok-4.20-0309-reasoning"
    "grok-4.20-multi-agent-0309"
    "grok-4.3"
    "grok-4.5"
    "grok-4.6"
    "grok-build-0.1"
    "grok-composer-2.5-fast"
    "k3"
    "k3-256k"
    "kimi-for-coding"
    "kimi-for-coding-highspeed"
    "kimi-k2"
    "kimi-k2-thinking"
    "kimi-k2.5"
    "kimi-k2.6"
    "kimi-k2.7-code"
    "kimi-k2.7-code-highspeed"
    "kimi-k3"
    "kimi-k3-256k"
    "qwen-audio-3.0-realtime-plus"
    "qwen-audio-3.0-tts-plus"
    "qwen3.6-flash"
    "qwen3.7-max"
    "qwen3.7-plus"
    "qwen3.8-flash"
    "qwen3.8-max"
  ];
  routeModelOverrides = {
    "gpt-5.6-sol" = {
      context_window = 372000;
      max_tokens = 128000;
      max_output_tokens_per_turn = 128000;
      supports_vision = true;
    };
    "gpt-5.6-luna" = {
      context_window = 372000;
      max_tokens = 128000;
      max_output_tokens_per_turn = 128000;
      supports_vision = true;
    };
    "gpt-5.6-terra" = {
      context_window = 372000;
      max_tokens = 128000;
      max_output_tokens_per_turn = 128000;
      supports_vision = true;
    };
  };
  routeModel = name:
    {
      provider = "route";
      provider_name = name;
      variant =
        if lib.hasPrefix "claude-" name
        then "claude"
        else if lib.hasPrefix "gemini-" name
        then "gemini"
        else if lib.hasPrefix "gpt-" name || lib.hasPrefix "codex-" name
        then "openai"
        else "other";
      class =
        if
          lib.any (lib.flip lib.hasInfix name) [
            "fast"
            "flash"
            "haiku"
            "luna"
            "mini"
            "spark"
          ]
        then "mini"
        else "full";
      context_window = 128000;
      max_tokens = 8192;
      max_output_tokens_per_turn = 8192;
      supports_vision = false;
    }
    // (routeModelOverrides.${name} or {});
  config = {
    version = 3;
    defaults = {
      full = "gpt-5.6-sol";
      mini = "gpt-5.6-luna";
    };
    providers.route = {
      kind.type = "custom_open_ai_compatible";
      url = "https://route.daze.lol/v1";
      auth = {
        type = "static_key";
        key = "\${ROUTE_API_KEY}";
        format = "bearer_token";
      };
    };
    models = lib.genAttrs routeModelNames routeModel;
    updates.automatic_check = false;
  };
  polytoken = pkgs.writeShellApplication {
    name = "polytoken";
    runtimeInputs = [pkgs.libsecret];
    text = ''
      ROUTE_API_KEY="$(secret-tool lookup service cliproxy host route.daze.lol user molly)"
      if [[ -z "$ROUTE_API_KEY" ]]; then
        echo "polytoken: route.daze.lol API key not found in the keyring" >&2
        exit 1
      fi
      export ROUTE_API_KEY

      exec ${package}/bin/polytoken "$@"
    '';
  };
in {
  xdg.configFile."polytoken/config.json".text = builtins.toJSON config;
  home.packages = [polytoken];
}
