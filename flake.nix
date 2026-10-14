{
  description = "NixOS configuration for chi (laptop), halo (pubnix), and misty (media)";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    noctalia = {
      url = "github:noctalia-dev/noctalia/cachix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    noctalia-greeter = {
      url = "github:noctalia-dev/noctalia-greeter";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hunk = {
      url = "github:modem-dev/hunk";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser = {
      # Twilight artifacts are re-uploaded by the flake's CI, so the package
      # stays reproducible; see the upstream README.
      url = "github:0xc000022070/zen-browser-flake";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };

    # Server fleet (halo + misty)
    disko = {
      url = "github:nix-community/disko/latest";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    clan-core = {
      url = "https://git.clan.lol/clan/clan-core/archive/main.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Declarative MicroVMs (hosts/misty/agent-browser.nix). Pinned directly
    # rather than through tangled so it tracks current nixpkgs.
    microvm = {
      url = "github:microvm-nix/microvm.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Tangled: git server (knot) and CI runner (spindle).
    tangled = {
      url = "git+https://tangled.org/tangled.sh/core";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Tranquil PDS. Keep its own nixpkgs pin so we get cache hits from
    # tranquil.cachix.org instead of rebuilding from source.
    tranquil = {
      url = "git+https://tangled.org/tranquil.farm/tranquil-pds";
    };

    # ratlogin: AT Protocol backed OpenID Connect provider.
    ratlogin = {
      url = "git+https://tangled.org/quilling.dev/ratlogin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # niri harness source (not a flake; packaged in ./pkgs/niri).
    niri-src = {
      url = "git+https://tangled.org/okami.mom/niri";
      flake = false;
    };

    # PDS Operator: admin dashboard for the Tranquil PDS.
    pds-operator = {
      url = "git+https://tangled.org/brookie.blog/pds-operator";
      flake = false;
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    home-manager,
    nixos-hardware,
    treefmt-nix,
    niri,
    stylix,
    clan-core,
    ...
  }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {inherit system;};
    treefmtEval = treefmt-nix.lib.evalModule pkgs ./treefmt.nix;
    myceliumAddresses = nixpkgs.lib.genAttrs ["chi" "halo" "misty"] (
      name:
        nixpkgs.lib.trim (builtins.readFile (./vars/per-machine + "/${name}/mycelium/ip/value"))
    );

    homeManagerBackup = pkgs.writeShellScript "home-manager-backup" ''
      target="$1"
      backup="$target.hm-backup"
      suffix=1

      while [[ -e "$backup" || -L "$backup" ]]; do
        backup="$target.hm-backup.$suffix"
        suffix=$((suffix + 1))
      done

      ${pkgs.coreutils}/bin/mv -- "$target" "$backup"
    '';

    inventory = import ./inventory.nix;

    # Server-side packaged helpers. `niriHarness` is the okami.mom/niri harness
    # package (distinct from the `niri` flake input used by chi).
    niriHarness = pkgs.callPackage ./pkgs/niri/package.nix {src = inputs.niri-src;};
    accountPortal = pkgs.callPackage ./pkgs/account-portal/package.nix {};
    openrouterZdrProxy = pkgs.callPackage ./pkgs/openrouter-zdr-proxy/package.nix {};
    tildeProvision = pkgs.callPackage ./pkgs/tilde-provision/package.nix {};
    tildeSiteTools = pkgs.callPackage ./pkgs/tilde-site-tools/package.nix {};
    pdsOperator = pkgs.callPackage ./pkgs/pds-operator/package.nix {src = inputs.pds-operator;};
    zetaAdapter = pkgs.callPackage ./pkgs/zeta-adapter/package.nix {};
    invidiousOidc = pkgs.callPackage ./pkgs/invidious-oidc/package.nix {};
    clan = clan-core.lib.clan {
      inherit self;
      meta = {
        name = "daze";
        domain = "daze.lol";
      };
      specialArgs = {
        inherit
          accountPortal
          inputs
          invidiousOidc
          openrouterZdrProxy
          pdsOperator
          tildeProvision
          tildeSiteTools
          myceliumAddresses
          zetaAdapter
          ;
        niri = niriHarness;
      };
      inherit inventory;
      machines = {
        chi = {
          nixpkgs.hostPlatform = system;
          imports = [
            ./modules/common.nix
            ./hosts/chi/configuration.nix
            inputs.nix-index-database.nixosModules.default
            nixos-hardware.nixosModules.framework-12-13th-gen-intel
            niri.nixosModules.niri
            inputs.noctalia.nixosModules.default
            inputs.noctalia-greeter.nixosModules.default
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupCommand = homeManagerBackup;
              home-manager.extraSpecialArgs = {inherit inputs myceliumAddresses;};
              home-manager.sharedModules = [
                stylix.homeModules.stylix
                niri.homeModules.stylix
                inputs.noctalia.homeModules.default
                inputs.hunk.homeManagerModules.default
                inputs.zen-browser.homeModules.twilight
              ];
              home-manager.users.mollyw = import ./home;
            }
          ];
        };
        halo = {
          nixpkgs.hostPlatform = system;
          imports = [
            ./modules/common.nix
            ./modules/hardening.nix
            ./modules/pubnix.nix
            ./modules/caddy.nix
            ./modules/auth.nix
            ./modules/account-portal.nix
            ./modules/bluesky-avatar.nix
            ./modules/seerr-login.nix
            ./modules/atproto.nix
            ./modules/registry.nix
            ./modules/apps.nix
            ./modules/route.nix
            ./modules/services.nix
            ./modules/dashboard.nix
            ./modules/romm.nix
            ./modules/pds-operator.nix
            ./modules/zeta.nix
            ./modules/qwen.nix
            ./modules/qwen3-0.6b.nix
            ./modules/tunnel.nix
            ./modules/niri.nix
            ./hosts/halo/configuration.nix
            inputs.tangled.nixosModules.knot
            inputs.tangled.nixosModules.spindle
            inputs.tranquil.nixosModules.default
            inputs.ratlogin.nixosModules.default
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = {inherit inputs;};
              home-manager.users.molly = import ./hosts/halo/home.nix;
            }
          ];
        };
        misty = {
          nixpkgs.hostPlatform = system;
          imports = [./hosts/misty/configuration.nix];
        };
      };
    };
  in {
    nixosConfigurations =
      clan.config.nixosConfigurations
      // {
        misty-installer = nixpkgs.lib.nixosSystem {
          specialArgs = {inherit inputs;};
          modules = [./images/misty-installer.nix];
        };
      };

    inherit (clan.config) nixosModules clanInternals;
    clan = clan.config;

    packages.${system} = {
      niri = niriHarness;
      inherit tildeProvision tildeSiteTools;
      account-portal = accountPortal;
      openrouter-zdr-proxy = openrouterZdrProxy;
      pds-operator = pdsOperator;
      zeta-adapter = zetaAdapter;
      invidious-oidc = invidiousOidc;
      misty-iso = self.nixosConfigurations.misty-installer.config.system.build.isoImage;
    };

    formatter.${system} = treefmtEval.config.build.wrapper;

    checks.${system} = {
      formatting = treefmtEval.config.build.check self;
      account-portal =
        pkgs.runCommand "account-portal-self-test" {
          nativeBuildInputs = [accountPortal];
        } ''
          tilde-requests self-test
          touch $out
        '';
      openrouter-zdr-proxy =
        pkgs.runCommand "openrouter-zdr-proxy-self-test" {
          nativeBuildInputs = [openrouterZdrProxy];
        } ''
          openrouter-zdr-proxy self-test
          touch $out
        '';
      tilde-provision =
        pkgs.runCommand "tilde-provision-self-test" {
          nativeBuildInputs = [tildeProvision];
        } ''
          tilde-provision self-test
          touch $out
        '';
      tilde-site-tools =
        pkgs.runCommand "tilde-site-tools-self-test" {
          nativeBuildInputs = [tildeSiteTools];
        } ''
          tilde-site-tools self-test
          touch $out
        '';
      zeta-adapter =
        pkgs.runCommand "zeta-adapter-self-test" {
          nativeBuildInputs = [zetaAdapter];
        } ''
          zeta-adapter --self-test
          touch $out
        '';
    };

    devShells.${system}.default = pkgs.mkShellNoCC {
      packages = with pkgs; [
        sops
        age
        jq
        clan-core.packages.${system}.clan-cli
        # infra/cloudflare: provider baked in, so `tofu init` needs no registry access.
        (opentofu.withPlugins (p: [p.cloudflare_cloudflare]))
      ];
    };
  };
}
