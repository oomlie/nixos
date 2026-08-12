{
  lib,
  appimageTools,
}: let
  pname = "jagex-launcher";
  version = "0.0.27";
  src = ./jagex-launcher-beta-linux-x86_64.AppImage;
  appimageContents = appimageTools.extract {inherit pname version src;};
in
  appimageTools.wrapType2 {
    inherit pname version src;

    extraPkgs = pkgs: [pkgs.libsecret];

    # The launcher runs RuneLite as a child AppImage; FUSE mounts don't work
    # inside the FHS sandbox, so tell the AppImage runtime to extract instead.
    profile = ''
      export APPIMAGE_EXTRACT_AND_RUN=1
    '';

    extraInstallCommands = ''
      install -Dm444 ${appimageContents}/jagex-launcher.desktop -t $out/share/applications
      substituteInPlace $out/share/applications/jagex-launcher.desktop \
        --replace-fail 'Exec=AppRun --no-sandbox %U' 'Exec=${pname} --no-sandbox %U'
      install -Dm444 ${appimageContents}/usr/share/icons/hicolor/512x512/apps/jagex-launcher.png \
        -t $out/share/icons/hicolor/512x512/apps
    '';

    meta = {
      description = "Jagex Launcher (RuneScape Hub)";
      homepage = "https://www.jagex.com/";
      license = lib.licenses.unfree;
      platforms = ["x86_64-linux"];
      mainProgram = pname;
    };
  }
