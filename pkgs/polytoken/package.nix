{
  lib,
  stdenvNoCC,
  fetchurl,
  installShellFiles,
}: let
  pname = "polytoken";
  version = "0.8.1";
  sources = {
    x86_64-linux = {
      platform = "linux-amd64";
      hash = "sha256-CwSJQJ5+StQHhtgs73vEy6EboJ6V6H2RC3xDF5jU3NY=";
    };
    aarch64-linux = {
      platform = "linux-arm64";
      hash = "sha256-kpjw2agrXwpYxg2jtoDZ/HKq5Wd0JxcIUCZxnNB+lno=";
    };
  };
  source = sources.${stdenvNoCC.hostPlatform.system};
in
  stdenvNoCC.mkDerivation {
    inherit pname version;

    src = fetchurl {
      url = "https://dl.polytoken.dev/${version}/${source.platform}/polytoken";
      inherit (source) hash;
    };

    nativeBuildInputs = [installShellFiles];
    dontUnpack = true;

    installPhase = ''
      runHook preInstall

      install -Dm755 "$src" "$out/bin/polytoken"

      "$out/bin/polytoken" completions bash >polytoken.bash
      "$out/bin/polytoken" completions zsh >polytoken.zsh
      "$out/bin/polytoken" completions fish >polytoken.fish
      installShellCompletion --cmd polytoken \
        --bash polytoken.bash \
        --zsh polytoken.zsh \
        --fish polytoken.fish

      runHook postInstall
    '';

    doInstallCheck = true;
    installCheckPhase = ''
      runHook preInstallCheck
      test "$($out/bin/polytoken --version)" = "polytoken ${version}"
      runHook postInstallCheck
    '';

    meta = {
      description = "Terminal-based AI coding agent";
      homepage = "https://polytoken.dev/";
      downloadPage = "https://docs.polytoken.dev/installation/downloads/";
      license = lib.licenses.unfree;
      mainProgram = "polytoken";
      platforms = builtins.attrNames sources;
      sourceProvenance = [lib.sourceTypes.binaryNativeCode];
    };
  }
