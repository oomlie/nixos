{
  lib,
  buildNpmPackage,
  makeWrapper,
  nodejs_22,
  python3,
  src,
}: let
  version = "0.1.0";

  # Frontend (Vite/React). Separate package.json from the server.
  web = buildNpmPackage {
    pname = "pds-operator-web";
    inherit version;
    nodejs = nodejs_22;
    src = "${src}/web";
    npmDepsHash = "sha256-fzbiQnmms7KouiTai0qfoSkp/pw5iYN9Pr2WCmSuhuE=";
    npmBuildScript = "build";
    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -r dist $out/dist
      runHook postInstall
    '';
  };
in
  buildNpmPackage {
    pname = "pds-operator";
    inherit version;

    nodejs = nodejs_22;
    src = "${src}/server";
    npmDepsHash = "sha256-rhNekgOLnIcBBJVM/mJFC2+XmslgDA3glD+s7kdJIP8=";

    # better-sqlite3 has no cacheable prebuild here; compile it from source
    # against the same Node used at runtime (otherwise it fails to dlopen).
    nativeBuildInputs = [makeWrapper python3];
    npm_config_build_from_source = "true";

    # Mirror the upstream runtime layout: <root>/server/dist + <root>/web/dist.
    installPhase = ''
      runHook preInstall

      root=$out/lib/pds-operator
      mkdir -p $root/server $root/web
      cp -r dist package.json $root/server/
      cp labelers.json.example $root/server/labelers.json
      cp -r ${web}/dist $root/web/dist

      npm prune --omit=dev
      cp -r node_modules $root/server/node_modules

      makeWrapper ${nodejs_22}/bin/node $out/bin/pds-operator \
        --add-flags "$root/server/dist/index.js"

      runHook postInstall
    '';

    meta = {
      description = "Self-hosted admin dashboard for an atproto PDS";
      homepage = "https://tangled.org/brookie.blog/pds-operator";
      license = lib.licenses.mit;
      mainProgram = "pds-operator";
      platforms = lib.platforms.linux;
    };
  }
