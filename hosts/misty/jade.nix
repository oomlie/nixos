# Jade: a standalone niri agent whose runtime lives on misty and dials the
# niri server on halo over iroh (worker.mode: remote). Her shell/file tools run
# locally on misty via an embedded tool host.
{
  config,
  inputs,
  pkgs,
  ...
}: let
  niri = pkgs.callPackage ../../pkgs/niri/package.nix {src = inputs.niri-src;};
  jadeHome = "/var/lib/jade";
  # Endpoint ticket printed by the halo niri server at boot. Refresh here if the
  # server's ticket rotates (the endpoint id is stable; the relay address is
  # what changes).
  ticket = "endpointad65q2zbjiywbrtcrc2nbrspxvo5bg5k3pae5dbnjdtqq3jcndawuayaenuhi5dqom5c6l3vonstcljrfzzgk3dbpexg4mbonfzg62bonruw42zof4aqacszbafyjrqdaeadguiwekcmmay";
in {
  sops.secrets."route/api-key" = {
    sopsFile = ../../secrets/misty.yaml;
    owner = "jade";
    group = "jade";
    mode = "0400";
  };
  sops.secrets."niri/iroh-token" = {
    sopsFile = ../../secrets/misty.yaml;
    owner = "jade";
    group = "jade";
    mode = "0400";
  };
  sops.secrets."openrouter/api-key" = {
    sopsFile = ../../secrets/misty.yaml;
    owner = "jade";
    group = "jade";
    mode = "0400";
    restartUnits = ["jade.service"];
  };

  systemd.tmpfiles.rules = [
    "d ${jadeHome} 0750 jade jade - -"
    "d ${jadeHome}/app 0750 jade jade - -"
    "d ${jadeHome}/home 0750 jade jade - -"
  ];

  systemd.services.jade = {
    description = "Jade (niri standalone agent on misty)";
    after = ["network-online.target"];
    wants = ["network-online.target"];
    wantedBy = ["multi-user.target"];
    # Shell/tool environment for the embedded tool host: a shell for npm, plus
    # the tools Jade's shell commands expect (ssh, git, etc.).
    path = with pkgs; [
      nodejs
      bashInteractive
      coreutils
      gnused
      gnugrep
      findutils
      git
      openssh
      curl
      jq
      dnsutils
      procps
    ];
    preStart = ''
      if [ ! -e ${jadeHome}/app/.stamp ] || [ "$(cat ${jadeHome}/app/.stamp 2>/dev/null)" != "${niri}" ]; then
        rm -rf ${jadeHome}/app
        cp -r ${niri} ${jadeHome}/app
        chmod -R u+w ${jadeHome}/app
        printf '%s' "${niri}" >${jadeHome}/app/.stamp
      fi

      umask 077
      cat >${jadeHome}/agent.yaml <<EOF
      id: jade
      name: Jade
      port: 3991
      home: ${jadeHome}/home
      client: local
      workspace: ${jadeHome}/home
      model:
        provider: openai
        name: mistral-small-latest
        thinking: true
        baseUrl: https://route.daze.lol/v1
        apiKey: "$(cat ${config.sops.secrets."route/api-key".path})"
      embedding:
        name: google/gemini-embedding-2-preview
        baseUrl: https://openrouter.ai/api/v1
        apiKey: "$(cat ${config.sops.secrets."openrouter/api-key".path})"
        dimensions: 3072
      server:
        iroh:
          ticket: ${ticket}
          token: "$(cat ${config.sops.secrets."niri/iroh-token".path})"
      EOF
    '';
    serviceConfig = {
      Type = "simple";
      User = "jade";
      Group = "jade";
      WorkingDirectory = "${jadeHome}/app";
      ExecStart = "${pkgs.nodejs}/lib/node_modules/npm/bin/npm-cli.js run start:standalone --ignore-scripts --workspace @niri/runtime -- --config ${jadeHome}/agent.yaml";
      Restart = "on-failure";
      RestartSec = "10";
      NoNewPrivileges = true;
      PrivateTmp = true;
    };
  };
}
