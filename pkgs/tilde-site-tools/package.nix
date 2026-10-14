{
  lib,
  makeWrapper,
  python3,
  stdenvNoCC,
}: let
  python = python3.withPackages (ps: [ps.feedparser]);
in
  stdenvNoCC.mkDerivation {
    pname = "tilde-site-tools";
    version = "1.0.0";
    src = ./site_tools.py;
    dontUnpack = true;
    nativeBuildInputs = [makeWrapper];

    installPhase = ''
      runHook preInstall
      install -Dm0644 "$src" "$out/libexec/tilde-site-tools.py"
      makeWrapper ${python}/bin/python3 "$out/bin/tilde-site-tools" \
        --add-flags "$out/libexec/tilde-site-tools.py"
      runHook postInstall
    '';

    meta = {
      description = "Static daze.lol member directory and planet generator";
      license = lib.licenses.mit;
      mainProgram = "tilde-site-tools";
    };
  }
