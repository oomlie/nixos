{
  description = "NixOS configuration for chi";

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
              inputs.zen-browser.homeModules.twilight
            ];
            home-manager.users.mollyw = import ./home;
          }
        ];
      };
    };

    formatter.${system} = treefmtEval.config.build.wrapper;
    checks.${system}.formatting = treefmtEval.config.build.check self;
  };
}
