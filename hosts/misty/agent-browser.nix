# Proof-of-concept agent browser: one declarative NixOS MicroVM on misty with
# Chromium and Playwright, reachable only over SSH through misty. The guest
# shares misty's read-only /nix/store, keeps its work in a persistent volume,
# and is firewalled off the LAN and Mycelium (only public internet egress).
#
# ponytail: fixed single VM, no orchestration. Add a second identical `microvm.vms`
# entry (or a scheduling layer) only if one proves insufficient.
{
  inputs,
  pkgs,
  ...
}: let
  keys = import ../../keys.nix;
  # QEMU user (SLiRP) networking: no host bridge/NAT to maintain. The guest
  # sees the host as 10.0.2.2 and DNS at 10.0.2.3.
  guestDns = "10.0.2.3";
in {
  imports = [inputs.microvm.nixosModules.host];

  microvm.vms.agent-browser.config = {
    system.stateVersion = "26.05";
    networking.hostName = "agent-browser";

    microvm = {
      hypervisor = "qemu";
      vcpu = 4;
      mem = 12288;
      interfaces = [
        {
          type = "user";
          id = "agent-net";
          mac = "02:00:00:00:77:01";
        }
      ];
      # SSH is forwarded to misty's loopback only; remote access goes through
      # misty's sshd (ProxyJump).
      forwardPorts = [
        {
          from = "host";
          host.address = "127.0.0.1";
          host.port = 10022;
          guest.port = 22;
        }
      ];
      volumes = [
        {
          image = "/var/lib/microvms/agent-browser/workspace.img";
          mountPoint = "/workspace";
          size = 65536;
          autoCreate = true;
        }
      ];
    };

    # DHCP comes from SLiRP; systemd-networkd is enabled by microvm.optimize.
    systemd.network.enable = true;

    users.users.agent = {
      isNormalUser = true;
      extraGroups = ["wheel"];
      openssh.authorizedKeys.keys = [keys.molly];
    };
    # Disposable sandbox: let the agent administer its own guest.
    security.sudo.wheelNeedsPassword = false;

    services.openssh = {
      enable = true;
      settings.PermitRootLogin = "no";
      # Keep the host identity stable across restarts; the guest root is
      # read-only, so the key lives on the persistent workspace volume.
      hostKeys = [
        {
          type = "ed25519";
          path = "/workspace/ssh/ssh_host_ed25519_key";
        }
      ];
    };

    systemd.services.agent-browser-host-keys = {
      description = "Generate the agent-browser SSH host key on the workspace volume";
      before = ["sshd.service"];
      requiredBy = ["sshd.service"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        ${pkgs.coreutils}/bin/install -d -m 0700 /workspace/ssh
        if [ ! -f /workspace/ssh/ssh_host_ed25519_key ]; then
          ${pkgs.openssh}/bin/ssh-keygen -t ed25519 -N "" -f /workspace/ssh/ssh_host_ed25519_key
        fi
      '';
    };

    networking.firewall.allowedTCPPorts = [22];
    # Use nftables so the egress guard below applies (the default backend is
    # iptables unless nftables is enabled).
    networking.nftables.enable = true;

    environment.sessionVariables = {
      PLAYWRIGHT_BROWSERS_PATH = "${pkgs.playwright-driver.browsers}";
      # `require("playwright-core")` resolves without a local install.
      NODE_PATH = "/workspace/node_modules";
    };
    environment.systemPackages = with pkgs; [
      chromium
      playwright-driver
      nodejs
      python3
      git
      jq
    ];

    # The workspace volume mounts root-owned; hand it to the agent user and make
    # the Playwright driver importable.
    systemd.tmpfiles.rules = [
      "d /workspace 0775 agent users -"
      "d /workspace/node_modules 0775 agent users -"
      "L+ /workspace/node_modules/playwright-core - - - - ${pkgs.playwright-driver}"
    ];

    # Egress guard: a browser agent can reach any URL, so block the private
    # ranges (LAN, Mycelium, link-local) except the SLiRP DNS/gateway subnet,
    # which keeps internal services out of reach without breaking internet
    # access or DNS.
    networking.nftables.tables.agent-egress = {
      family = "inet";
      content = ''
        chain output {
          type filter hook output priority 0; policy accept;
          # Replies to connections we accepted (incl. the forwarded SSH) pass.
          ct state established,related accept
          # Allow only the SLiRP DNS service, then block new connections to the
          # host loopback alias (10.0.2.2) and every private/overlay range.
          ip daddr ${guestDns} accept
          ip daddr 10.0.2.2 drop
          ip daddr { 10.0.0.0/8, 100.64.0.0/10, 172.16.0.0/12, 192.168.0.0/16, 169.254.0.0/16 } drop
          ip6 daddr { 400::/7, fc00::/7, fe80::/10 } drop
        }
      '';
    };
  };
}
