{
  lib,
  buildNpmPackage,
  src,
}: let
  npmDepsHash = "sha256-y52sv5vqcDkEhQ30ZCHP3jC73LBCgGbp9Amv5eRCf10=";
in
  buildNpmPackage {
    pname = "niri";
    version = "1.0.0";

    inherit src;

    inherit npmDepsHash;

    # Strip the non-standard `refusal`/`reasoning_content` assistant fields
    # before replaying history to strict OpenAI-compatible endpoints (e.g.
    # Mistral), which reject them with 422. See the patch header for details.
    patches = [./patches/0001-strip-nonstandard-assistant-fields.patch];

    # Ship the fully built tree (node_modules + dist) so the systemd unit can
    # copy it into a writable StateDirectory. niri writes state relative to its
    # checkout, so it cannot run from a read-only store path.
    installPhase = ''
      runHook preInstall
      mkdir -p "$out"
      cp -r . "$out/"
      runHook postInstall
    '';

    meta = with lib; {
      description = "niri: an agent harness";
      license = licenses.isc;
      mainProgram = "niri";
    };
  }
