# Single source of truth for the fleet, including Clan services and deployment.
{
  machines = {
    chi = {
      tags = ["desktop"];
    };
    halo = {
      tags = ["server" "public"];
    };
    misty = {
      tags = ["server" "media"];
    };
  };

  instances.mycelium.roles.peer.machines = {
    chi = {};
    halo = {};
    misty = {};
  };

  instances.p2p-ssh-iroh.roles.server.machines = {
    halo = {};
    misty = {};
  };

  # Encrypted, deduplicated backups of chi and halo state to misty. The paths
  # are declared with clan.core.state on each client.
  instances.borgbackup.roles = {
    client.machines = {
      chi = {};
      halo = {};
    };
    server.machines.misty = {};
  };
}
