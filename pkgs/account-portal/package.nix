{
  lib,
  makeWrapper,
  python3,
  stdenvNoCC,
}:
stdenvNoCC.mkDerivation {
  pname = "tilde-account-portal";
  version = "1.0.0";
  src = ./portal.py;
  dontUnpack = true;
  nativeBuildInputs = [makeWrapper];

  installPhase = ''
    runHook preInstall
    install -Dm0644 "$src" "$out/libexec/tilde-account-portal.py"
    makeWrapper ${python3}/bin/python3 "$out/bin/tilde-requests" \
      --add-flags "$out/libexec/tilde-account-portal.py"
    runHook postInstall
  '';

  meta = {
    description = "Small ratlogin-authenticated pubnix account request portal";
    license = lib.licenses.mit;
    mainProgram = "tilde-requests";
  };
}
