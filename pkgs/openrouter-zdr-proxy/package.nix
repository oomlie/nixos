{
  lib,
  makeWrapper,
  python3,
  stdenvNoCC,
}:
stdenvNoCC.mkDerivation {
  pname = "openrouter-zdr-proxy";
  version = "1.0.0";
  src = ./proxy.py;
  dontUnpack = true;
  nativeBuildInputs = [makeWrapper];

  installPhase = ''
    runHook preInstall
    install -Dm0644 "$src" "$out/libexec/openrouter-zdr-proxy.py"
    makeWrapper ${python3}/bin/python3 "$out/bin/openrouter-zdr-proxy" \
      --add-flags "$out/libexec/openrouter-zdr-proxy.py"
    runHook postInstall
  '';

  meta = {
    description = "OpenRouter proxy enforcing ZDR and denying data collection";
    license = lib.licenses.mit;
    mainProgram = "openrouter-zdr-proxy";
  };
}
