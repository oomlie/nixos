{pkgs, ...}: let
  # route.daze.lol is the only LLM gateway this machine uses. The API key lives in
  # the login keyring and is injected by the wrapper below; `$ROUTE_API_KEY` is
  # resolved by pi at request time.
  #
  # Model metadata mirrors the curation in ./opencode.nix so both agents agree on
  # context windows, output limits, and reasoning support. Models the gateway
  # reports but opencode does not describe fall back to pi's defaults.
  modelMeta = {
    "claude-3-5-haiku-20241022" = {
      name = "Claude 3.5 Haiku";
      contextWindow = 128000;
      maxTokens = 8192;
    };
    "claude-3-7-sonnet-20250219" = {
      name = "Claude 3.7 Sonnet";
      reasoning = true;
      input = ["text" "image"];
      contextWindow = 128000;
      maxTokens = 8192;
    };
    "claude-fable-5" = {
      name = "Claude Fable 5";
      reasoning = true;
      input = ["text" "image"];
      contextWindow = 1000000;
      maxTokens = 128000;
    };
    "claude-fable-5-1" = {
      reasoning = true;
    };
    "claude-haiku-4-5-20251001" = {
      name = "Claude 4.5 Haiku";
      reasoning = true;
      input = ["text" "image"];
      contextWindow = 200000;
      maxTokens = 64000;
    };
    "claude-opus-4-1-20250805" = {
      name = "Claude 4.1 Opus";
      reasoning = true;
      input = ["text" "image"];
      contextWindow = 200000;
      maxTokens = 32000;
    };
    "claude-opus-4-20250514" = {
      name = "Claude 4 Opus";
      reasoning = true;
      input = ["text" "image"];
      contextWindow = 200000;
      maxTokens = 32000;
    };
    "claude-opus-4-5-20251101" = {
      name = "Claude 4.5 Opus";
      reasoning = true;
      input = ["text" "image"];
      contextWindow = 200000;
      maxTokens = 64000;
    };
    "claude-opus-4-6" = {
      name = "Claude 4.6 Opus";
      reasoning = true;
      input = ["text" "image"];
      contextWindow = 1000000;
      maxTokens = 128000;
    };
    "claude-opus-4-6-thinking" = {
      reasoning = true;
    };
    "claude-opus-4-7" = {
      name = "Claude Opus 4.7";
      reasoning = true;
      input = ["text" "image"];
      contextWindow = 1000000;
      maxTokens = 128000;
    };
    "claude-opus-4-8" = {
      name = "Claude Opus 4.8";
      reasoning = true;
      input = ["text" "image"];
      contextWindow = 1000000;
      maxTokens = 128000;
    };
    "claude-opus-5" = {
      name = "Claude Opus 5";
      reasoning = true;
      input = ["text" "image"];
      contextWindow = 1000000;
      maxTokens = 128000;
    };
    "claude-sonnet-4-20250514" = {
      name = "Claude 4 Sonnet";
      reasoning = true;
      input = ["text" "image"];
      contextWindow = 200000;
      maxTokens = 64000;
    };
    "claude-sonnet-4-5-20250929" = {
      name = "Claude 4.5 Sonnet";
      reasoning = true;
      input = ["text" "image"];
      contextWindow = 200000;
      maxTokens = 64000;
    };
    "claude-sonnet-4-6" = {
      name = "Claude 4.6 Sonnet";
      reasoning = true;
      input = ["text" "image"];
      contextWindow = 200000;
      maxTokens = 64000;
    };
    "claude-sonnet-5" = {
      name = "Claude Sonnet 5";
      reasoning = true;
      input = ["text" "image"];
      contextWindow = 1000000;
      maxTokens = 128000;
    };
    "codex-auto-review" = {
      name = "Codex Auto Review";
      reasoning = true;
      input = ["text" "image"];
      contextWindow = 272000;
      maxTokens = 128000;
    };
    "deepseek-platform-flash" = {
      name = "DeepSeek V4.1 Flash (Platform)";
      reasoning = true;
      input = ["text" "image"];
      contextWindow = 1048576;
      maxTokens = 393216;
    };
    "deepseek-platform-v4-pro" = {
      name = "DeepSeek V4 Pro (Platform)";
      reasoning = true;
      contextWindow = 1048576;
      maxTokens = 393216;
    };
    "deepseek-v4-flash-0731" = {
      reasoning = true;
    };
    "deepseek-v4-pro" = {
      reasoning = true;
    };
    "gemini-3-flash" = {
      reasoning = true;
    };
    "gemini-3.1-flash-lite" = {
      reasoning = true;
    };
    "gemini-3.1-pro-low" = {
      reasoning = true;
    };
    "gemini-3.6-flash-high" = {
      reasoning = true;
    };
    "gemini-3.7-flash-high" = {
      reasoning = true;
    };
    "gemini-3.8-flash-high" = {
      reasoning = true;
    };
    "gemini-pro-agent" = {
      reasoning = true;
    };
    "glm-5.2" = {
      reasoning = true;
    };
    "gpt-5.3-codex-spark" = {
      name = "GPT-5.3 Codex Spark";
      reasoning = true;
      input = ["text" "image"];
      contextWindow = 128000;
      maxTokens = 32000;
    };
    "gpt-5.5" = {
      name = "GPT-5.5";
      reasoning = true;
      input = ["text" "image"];
      contextWindow = 272000;
      maxTokens = 128000;
    };
    "gpt-5.6-luna" = {
      name = "GPT-5.6 Luna";
      reasoning = true;
      input = ["text" "image"];
      contextWindow = 372000;
      maxTokens = 128000;
    };
    "gpt-5.6-sol" = {
      name = "GPT-5.6 Sol";
      reasoning = true;
      input = ["text" "image"];
      contextWindow = 372000;
      maxTokens = 128000;
    };
    "gpt-5.6-terra" = {
      name = "GPT-5.6 Terra";
      reasoning = true;
      input = ["text" "image"];
      contextWindow = 372000;
      maxTokens = 128000;
    };
    "gpt-6-astra" = {
      reasoning = true;
    };
    "gpt-oss-120b-medium" = {
      reasoning = true;
    };
    "grok-3-mini" = {
      name = "Grok 3 Mini";
      reasoning = true;
      contextWindow = 131072;
      maxTokens = 32768;
    };
    "grok-3-mini-fast" = {
      name = "Grok 3 Mini Fast";
      reasoning = true;
      contextWindow = 131072;
      maxTokens = 32768;
    };
    "grok-4.20-0309-non-reasoning" = {
      name = "Grok 4.20 0309 Non Reasoning";
      input = ["text" "image"];
      contextWindow = 2000000;
      maxTokens = 65536;
    };
    "grok-4.20-0309-reasoning" = {
      name = "Grok 4.20 0309 Reasoning";
      reasoning = true;
      input = ["text" "image"];
      contextWindow = 2000000;
      maxTokens = 65536;
    };
    "grok-4.20-multi-agent-0309" = {
      name = "Grok 4.20 Multi Agent 0309";
      reasoning = true;
      input = ["text" "image"];
      contextWindow = 2000000;
      maxTokens = 65536;
    };
    "grok-4.3" = {
      name = "Grok 4.3";
      reasoning = true;
      input = ["text" "image"];
      contextWindow = 1000000;
      maxTokens = 30000;
    };
    "grok-4.5" = {
      name = "Grok 4.5";
      reasoning = true;
      input = ["text" "image"];
      contextWindow = 500000;
      maxTokens = 500000;
    };
    "grok-4.6" = {
      name = "Grok 4.6";
      reasoning = true;
      input = ["text" "image"];
      contextWindow = 500000;
      maxTokens = 500000;
    };
    "grok-build-0.1" = {
      name = "Grok Build 0.1";
      reasoning = true;
      input = ["text" "image"];
      contextWindow = 256000;
      maxTokens = 256000;
    };
    "grok-composer-2.5-fast" = {
      name = "Composer 2.5 Fast";
      contextWindow = 200000;
      maxTokens = 32768;
    };
    "k3" = {
      name = "Kimi K3 (1M)";
      reasoning = true;
      input = ["text" "image"];
      contextWindow = 1048576;
      maxTokens = 32768;
    };
    "k3-256k" = {
      name = "Kimi K3 (256K)";
      reasoning = true;
      input = ["text" "image"];
      contextWindow = 262144;
      maxTokens = 32768;
    };
    "kimi-for-coding" = {
      name = "Kimi K2.7 Code";
      reasoning = true;
      input = ["text" "image"];
      contextWindow = 262144;
      maxTokens = 32768;
    };
    "kimi-for-coding-highspeed" = {
      name = "Kimi K2.7 Code HighSpeed";
      reasoning = true;
      input = ["text" "image"];
      contextWindow = 262144;
      maxTokens = 32768;
    };
    "qwen3.6-flash" = {
      reasoning = true;
    };
    "qwen3.7-max" = {
      reasoning = true;
    };
    "qwen3.7-plus" = {
      reasoning = true;
    };
    "qwen3.8-flash" = {
      reasoning = true;
    };
    "qwen3.8-max" = {
      reasoning = true;
    };
  };

  modelIds = [
    "claude-3-5-haiku-20241022"
    "claude-3-7-sonnet-20250219"
    "claude-fable-5"
    "claude-fable-5-1"
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
    "deepseek-platform-flash"
    "deepseek-platform-v4-pro"
    "deepseek-v4-flash-0731"
    "deepseek-v4-pro"
    "gemini-3-flash"
    "gemini-3.1-flash-lite"
    "gemini-3.1-pro-low"
    "gemini-3.5-flash-lite"
    "gemini-3.6-flash-high"
    "gemini-3.7-flash-high"
    "gemini-3.8-flash-high"
    "gemini-pro-agent"
    "glm-5.2"
    "gpt-5.3-codex-spark"
    "gpt-5.5"
    "gpt-5.6-luna"
    "gpt-5.6-sol"
    "gpt-5.6-terra"
    "gpt-6-astra"
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
    "qwen3.6-flash"
    "qwen3.7-max"
    "qwen3.7-plus"
    "qwen3.8-flash"
    "qwen3.8-max"
  ];

  # Not curated in ./opencode.nix, so these keep pi's defaults (128k context,
  # 16k output, no reasoning): gemini-3.5-flash-lite.
  models = map (id: {inherit id;} // (modelMeta.${id} or {})) modelIds;

  # Vendored at 0.85.1; the nixpkgs pin still ships 0.80.3. See
  # ../pkgs/pi-coding-agent/package.nix.
  piPackage = pkgs.callPackage ../pkgs/pi-coding-agent/package.nix {};

  pi = pkgs.writeShellApplication {
    name = "pi";
    runtimeInputs = [pkgs.libsecret];
    text = ''
      ROUTE_API_KEY="$(secret-tool lookup service cliproxy host route.daze.lol user molly)"
      if [[ -z "$ROUTE_API_KEY" ]]; then
        echo "pi: route.daze.lol API key not found in the keyring" >&2
        exit 1
      fi
      export ROUTE_API_KEY

      exec ${piPackage}/bin/pi "$@"
    '';
  };
in {
  home.packages = [pi];

  # pi reads these from ~/.pi/agent/ on every /model invocation; auth.json and
  # sessions stay mutable alongside them.
  home.file.".pi/agent/models.json".text = builtins.toJSON {
    providers.route = {
      name = "route.daze.lol";
      baseUrl = "https://route.daze.lol/v1";
      api = "openai-completions";
      apiKey = "$ROUTE_API_KEY";
      inherit models;
    };
  };

  home.file.".pi/agent/settings.json".text = builtins.toJSON {
    defaultProvider = "route";
    defaultModel = "gpt-5.6-sol";
  };
}
