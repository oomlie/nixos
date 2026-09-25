{
  lib,
  stdenvNoCC,
  fetchurl,
  autoPatchelfHook,
  fd,
  makeWrapper,
  ripgrep,
  uv,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "prime-agent";
  version = "0.9.5";

  src = fetchurl {
    url = "https://pub-728493de92a943e2a9b2d17b4719f318.r2.dev/releases/v${finalAttrs.version}/prime-agent-${finalAttrs.version}-linux-x64.tar.gz";
    hash = "sha256-vEsO15HR6LO11qlSSaYDBtlXn8DWA45dfYLwaNgfAI0=";
  };
  sourceRoot = ".";

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];

  dontBuild = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/bin" "$out/lib/prime-agent"
    cp -r ./* "$out/lib/prime-agent/"
    makeWrapper "$out/lib/prime-agent/prime-agent" "$out/bin/prime-agent" \
      --prefix PATH : ${lib.makeBinPath [fd ripgrep uv]} \
      --set-default PI_SKIP_VERSION_CHECK 1

    runHook postInstall
  '';

  meta = {
    description = "Coding agent with a persistent Python control environment";
    homepage = "https://github.com/PrimeIntellect-ai/prime-agent";
    license = lib.licenses.mit;
    mainProgram = "prime-agent";
    platforms = ["x86_64-linux"];
    sourceProvenance = with lib.sourceTypes; [binaryNativeCode];
  };
})
