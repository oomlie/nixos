{
  description = "NixOS configurations for chi and halo";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    albedo = {
      url = "git+https://tangled.org/okami.mom/albedo";
    };
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

    # Tangled: git server (knot) and CI runner (spindle) for halo
    tangled = {
      url = "git+https://tangled.org/tangled.sh/core";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Tranquil PDS (halo). Keep its own nixpkgs pin so we get cache hits
    # from tranquil.cachix.org instead of rebuilding from source.
    tranquil = {
      url = "git+https://tangled.org/tranquil.farm/tranquil-pds";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
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
    ...
  }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {inherit system;};
    primeAgent = pkgs.callPackage ./pkgs/prime-agent/package.nix {};
    treefmtEval = treefmt-nix.lib.evalModule pkgs ./treefmt.nix;
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
  in {
    nixosConfigurations = {
      # Framework 12 laptop (desktop)
      chi = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs;};
        modules = [
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
            home-manager.extraSpecialArgs = {inherit inputs;};
            home-manager.sharedModules = [
              stylix.homeModules.stylix
              niri.homeModules.stylix
              inputs.noctalia.homeModules.default
              inputs.hunk.homeManagerModules.default
            ];
            home-manager.users.mollyw = import ./home;
          }
        ];
      };

      # Strix Halo server
      halo = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs;};
        modules = [
          ./modules/common.nix
          ./hosts/halo/configuration.nix
          home-manager.nixosModules.home-manager
          inputs.sops-nix.nixosModules.sops
          inputs.tranquil.nixosModules.default
          {
            home-manager.backupCommand = homeManagerBackup;
            home-manager.extraSpecialArgs = {inherit inputs;};
          }
        ];
      };
    };

    formatter.${system} = treefmtEval.config.build.wrapper;
    packages.${system}.prime-agent = primeAgent;
    devShells.${system}.default = pkgs.mkShellNoCC {packages = [primeAgent];};
    checks.${system}.formatting = treefmtEval.config.build.check self;
  };
}
