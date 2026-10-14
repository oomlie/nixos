# Jellyfin native SSO via the K0lin/jellyfin-plugin-sso plugin.
# Jellyfin 12.1.0 requires plugin >= 5.1.0; we pin v5.1.1.
{
  config,
  pkgs,
  ...
}: let
  version = "5.1.1";
  ssoPlugin = pkgs.stdenvNoCC.mkDerivation {
    pname = "jellyfin-plugin-sso";
    inherit version;
    src = pkgs.fetchurl {
      url = "https://github.com/K0lin/jellyfin-plugin-sso/releases/download/v${version}/sso-authentication_${version}.zip";
      hash = "sha256-2xJrR2O9o6N1T6IQMjL8A+8b+SnP7aNfLprznIdSM7E=";
    };
    nativeBuildInputs = [pkgs.unzip];
    unpackPhase = "unzip -o $src -d plugin";
    installPhase = ''
      mkdir -p $out/SSO-Auth
      cp -r plugin/. $out/SSO-Auth/
    '';
  };
  configFile = "/var/lib/jellyfin/plugins/configurations/SSO-Auth.xml";
  brandingFile = "/var/lib/jellyfin/config/branding.xml";
  branding = pkgs.writeText "jellyfin-branding.xml" ''
    <?xml version="1.0" encoding="utf-8"?>
    <BrandingOptions>
      <LoginDisclaimer>&lt;form action="https://video.daze.lol/sso/OID/start/ratlogin"&gt;&lt;button type="submit" class="raised block emby-button button-submit"&gt;Sign in with ratlogin&lt;/button&gt;&lt;/form&gt;</LoginDisclaimer>
      <CustomCss>.disclaimerContainer { display: block; }</CustomCss>
      <SplashscreenEnabled>false</SplashscreenEnabled>
    </BrandingOptions>
  '';
in {
  # Read by root in the oneshot below; Jellyfin's user has no named group, so
  # keep this root-owned and copy the value into the plugin config.
  sops.secrets."oidc/jellyfin" = {
    sopsFile = ../../secrets/misty.yaml;
    mode = "0400";
  };

  # Install the plugin and seed its config (once) before Jellyfin starts.
  systemd.services.jellyfin-sso-plugin = {
    description = "Install the Jellyfin SSO-Auth plugin and seed its config";
    before = ["jellyfin.service"];
    requiredBy = ["jellyfin.service"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      set -eu
      umask 022
      mkdir -p /var/lib/jellyfin/plugins/configurations
      rm -rf /var/lib/jellyfin/plugins/SSO-Auth
      cp -r ${ssoPlugin}/SSO-Auth /var/lib/jellyfin/plugins/SSO-Auth
      chown -R jellyfin: /var/lib/jellyfin/plugins/SSO-Auth

      # The SSO plugin handles the redirect but does not add a login-page button.
      if [ ! -e ${brandingFile} ]; then
        install -Dm644 ${branding} ${brandingFile}
        chown jellyfin: ${brandingFile}
      fi

      cfg=${configFile}
      mkdir -p "$(dirname "$cfg")"
      if [ ! -e "$cfg" ]; then
        umask 077
        cat > "$cfg" <<EOF
      <?xml version="1.0" encoding="utf-8"?>
      <PluginConfiguration xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
        <SamlConfigs />
        <OidConfigs>
          <item>
            <key>
              <string>ratlogin</string>
            </key>
            <value>
              <PluginConfiguration>
                <OidEndpoint>https://auth.daze.lol</OidEndpoint>
                <OidClientId>jellyfin</OidClientId>
                <OidSecret>$(cat ${config.sops.secrets."oidc/jellyfin".path})</OidSecret>
                <Enabled>true</Enabled>
                <EnableAuthorization>false</EnableAuthorization>
                <EnableAllFolders>true</EnableAllFolders>
                <OidScopes>openid</OidScopes>
                <OidScopes>profile</OidScopes>
                <OidScopes>email</OidScopes>
                <SchemeOverride>https</SchemeOverride>
                <NewPath>true</NewPath>
                <AvatarUrlFormat>@{picture}</AvatarUrlFormat>
              </PluginConfiguration>
            </value>
          </item>
        </OidConfigs>
      </PluginConfiguration>
      EOF
        chown jellyfin: "$cfg"
      fi

      # Existing installations were seeded before avatar sync was enabled.
      if ! grep -qF '<AvatarUrlFormat>@{picture}</AvatarUrlFormat>' "$cfg"; then
        sed -i '\|<NewPath>true</NewPath>|a\                <AvatarUrlFormat>@{picture}</AvatarUrlFormat>' "$cfg"
      fi
    '';
  };
}
