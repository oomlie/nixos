_: {
  # Nix settings
  nix.settings.experimental-features = ["nix-command" "flakes"];
  nix.settings.auto-optimise-store = true;
  # 256 MiB download buffer: fewer stalls on large fetches (games, toolchains)
  nix.settings.download-buffer-size = 268435456;

  # Locale
  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Firewall
  networking.firewall.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Overlays
  nixpkgs.overlays = [
    (_final: prev: {
      # Sideband + Kivy compatibility fix for Python 3.14 (removed ast.Str & read-only nix store)
      sideband = let
        kivyPatched = prev.python3Packages.kivy.overridePythonAttrs (old: {
          postPatch =
            (old.postPatch or "")
            + ''
              substituteInPlace kivy/lang/parser.py \
                --replace-fail 'if isinstance(n, ast.Str):' 'if False:'
            '';
        });
      in
        (prev.sideband.override {
          python3Packages =
            prev.python3Packages
            // {
              kivy = kivyPatched;
            };
        })
        .overridePythonAttrs (old: {
          doCheck = false;
          dependencies = map (dep:
            if (dep.pname or "") == "kivy"
            then kivyPatched
            else dep)
          old.dependencies;
          postPatch =
            (old.postPatch or "")
            + ''
              echo "def python314_kivy_patch(): pass" > sbapp/compat.py
            '';
        });

      # Update nomadnet to 1.2.8 with relaxed dependencies
      # nixpkgs has rns 1.3.8 / lxmf 1.0.1 but nomadnet 1.2.8 wants >=1.4.1 / >=1.1.0
      nomadnet = prev.python3Packages.buildPythonPackage {
        pname = "nomadnet";
        version = "1.2.8";
        pyproject = true;
        __structuredAttrs = true;
        src = prev.fetchPypi {
          pname = "nomadnet";
          version = "1.2.8";
          hash = "sha256-6RQsbUIruRc2r+br62GArjRQTst7xrR5R1YFVvjroeE=";
        };
        build-system = [prev.python3Packages.setuptools];
        dependencies = with prev.python3Packages; [
          rns
          lxmf
          msgpack
          urwid
          qrcode
        ];
        doCheck = false;
        pythonImportsCheck = ["nomadnet"];
        postPatch = ''
          # Remove version constraints for rns and lxmf in setup.py
          substituteInPlace setup.py \
            --replace '"rns>=1.4.1"' '"rns"' \
            --replace '"lxmf>=1.1.0"' '"lxmf"'
        '';
        pythonRuntimeDepsCheck = false;
        meta = with prev.lib; {
          description = "Off-grid, resilient mesh communication";
          homepage = "https://github.com/markqvist/NomadNet";
          license = licenses.gpl3Only;
          maintainers = with maintainers; [drupol fab];
          mainProgram = "nomadnet";
        };
      };
    })
  ];
}
