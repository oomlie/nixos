{
  config,
  inputs,
  pkgs,
  ...
}: let
  package = inputs.albedo.packages.${pkgs.stdenv.hostPlatform.system}.albedo;
  routeModels = pkgs.runCommand "albedo-route-models.json" {nativeBuildInputs = [pkgs.jq];} ''
    jq '{
      route: {
        api: "https://route.daze.lol/v1",
        env: ["ROUTE_API_KEY"],
        models: (
          .providers.route.models
          | map({
              key: .id,
              value: {
                id: .id,
                limit: {
                  context: .contextWindow,
                  output: .maxTokens
                },
                modalities: {
                  input: (.input // ["text"])
                }
              }
            })
          | from_entries
        )
      }
    }' ${config.home.file.".pi/agent/models.json".source} > "$out"
  '';
  albedo = pkgs.writeShellApplication {
    name = "albedo";
    runtimeInputs = [pkgs.coreutils pkgs.jq pkgs.libsecret];
    text = ''
      config_dir="''${ALBEDO_HOME:-$HOME/.albedo}"
      config_file="$config_dir/config.json"

      if [[ ! -e "$config_file" ]]; then
        api_key="$(secret-tool lookup service cliproxy host route.daze.lol user molly || true)"
        if [[ -z "$api_key" ]]; then
          echo "albedo: route.daze.lol API key not found in the keyring" >&2
          exit 1
        fi

        umask 077
        mkdir -p "$config_dir"
        temporary="$(mktemp "$config_file.XXXXXX")"
        jq -n --arg api_key "$api_key" '{
          active: "route",
          providers: {
            route: {
              extension: "openai",
              baseUrl: "https://route.daze.lol/v1",
              apiKey: $api_key,
              model: "gpt-5.6-sol",
              protocol: "chat_completions"
            }
          }
        }' > "$temporary"
        mv "$temporary" "$config_file"
      fi

      if [[ ! -e "$config_dir/extensions.json" ]]; then
        umask 077
        printf '%s\n' '{"models":{"refreshHours":0}}' > "$config_dir/extensions.json"
      fi

      exec ${package}/bin/albedo "$@"
    '';
  };
in {
  home.packages = [albedo];
  home.file.".albedo/models.json".source = routeModels;
}
