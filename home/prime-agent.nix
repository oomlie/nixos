{
  config,
  pkgs,
  ...
}: let
  package = pkgs.callPackage ../pkgs/prime-agent/package.nix {};
  primeAgent = pkgs.writeShellApplication {
    name = "prime-agent";
    runtimeInputs = [pkgs.libsecret];
    text = ''
      ROUTE_API_KEY="$(secret-tool lookup service cliproxy host route.daze.lol user molly || true)"
      if [[ -z "$ROUTE_API_KEY" ]]; then
        echo "prime-agent: route.daze.lol API key not found in the keyring" >&2
        exit 1
      fi
      export ROUTE_API_KEY

      exec ${package}/bin/prime-agent "$@"
    '';
  };
in {
  home.packages = [primeAgent];

  # Prime Agent and Pi use the same custom-provider schema.
  home.file.".prime/agent/models.json".source = config.home.file.".pi/agent/models.json".source;
  home.file.".prime/agent/settings.json".text = builtins.toJSON {
    defaultProvider = "route";
    defaultModel = "gpt-5.6-sol";
  };
}
