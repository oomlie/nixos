{
  config,
  pkgs,
  ...
}: {
  # Forgejo Actions runner for git.daze.lol. It runs jobs natively on halo (the `host` runtime), so a
  # workflow can use the host's Nix instead of a container. Registered once with
  # `forgejo-runner register`; the UUID is not secret and lives here, the token lives in sops.
  sops.secrets."forgejo/runner-token" = {
    sopsFile = ../secrets/halo.yaml;
    restartUnits = ["forgejo-runner-halo.service"];
  };

  services.forgejo-runner.instances.halo = {
    enable = true;
    # The module's default set, plus nix: jobs run natively, so `nix flake check` on the host is the
    # whole point. (`gitMinimal` is always present.)
    hostPackages = with pkgs; [
      bash
      coreutils
      curl
      gawk
      gnused
      nodejs
      wget
      nix
      git
    ];
    settings = {
      # `host` also selects the host runtime automatically, so jobs are not containerised.
      runner.labels = ["ubuntu-latest:host"];
      server.connections.default = {
        url = "https://git.daze.lol";
        uuid = "b5795db1-1674-4350-9f6d-79c90aba2c53";
      };
    };
    secrets.server.connections.default.token_url = config.sops.secrets."forgejo/runner-token".path;
  };
}
