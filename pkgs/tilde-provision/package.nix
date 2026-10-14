{
  lib,
  makeWrapper,
  python3,
  stdenvNoCC,
}:
stdenvNoCC.mkDerivation {
  pname = "tilde-provision";
  version = "1.0.0";
  src = ./tilde_provision.py;
  dontUnpack = true;
  nativeBuildInputs = [makeWrapper];

  installPhase = ''
    runHook preInstall
    install -Dm0644 "$src" "$out/libexec/tilde-provision.py"
    makeWrapper ${python3}/bin/python3 "$out/bin/tilde-provision" \
      --add-flags "$out/libexec/tilde-provision.py"
    runHook postInstall
  '';

  meta = {
    description = "daze.lol account provisioning: per-user email forwarding";
    license = lib.licenses.mit;
    mainProgram = "tilde-provision";
  };
}
