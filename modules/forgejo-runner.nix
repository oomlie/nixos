{
  config,
  pkgs,
  lib,
  ...
}: {
  # Forgejo Actions runner for git.daze.lol. It runs jobs natively on halo (the `host` runtime), so a
  # workflow can use the host's Nix instead of a container. Registered once with
  # `forgejo-runner register`; the UUID is not secret and lives here, the token lives in sops.
  sops.secrets."forgejo/runner-token" = {
    sopsFile = ../secrets/halo.yaml;
    restartUnits = ["forgejo-runner-halo.service"];
  };

  # A static user, not the module's DynamicUser: the Nix daemon only accepts connections from
  # `nix.settings.allowed-users`, and a transient dynamic user cannot be listed there (halo's pubnix
  # module narrows that list to root, molly and @tilde). Without this, every `nix` step in a job dies
  # with "cannot open connection to remote store 'daemon': Connection reset by peer".
  users.users.forgejo-runner = {
    isSystemUser = true;
    group = "forgejo-runner";
    home = "/var/lib/forgejo-runner/halo";
  };
  users.groups.forgejo-runner = {};
  nix.settings.allowed-users = ["forgejo-runner"];

  systemd.services.forgejo-runner-halo.serviceConfig = {
    DynamicUser = lib.mkForce false;
    User = lib.mkForce "forgejo-runner";
    Group = lib.mkForce "forgejo-runner";
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
