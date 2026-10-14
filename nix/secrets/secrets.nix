# Agenix secrets configuration
#
# This file declares which public keys can decrypt each secret.
# The master key is your age identity - keep the private key safe!
#
# To get your public key from your master.key:
#   age-keygen -y ~/.age/master.key
#
# Then replace the placeholder below with your actual public key.

let
  # Your age master public key (replace this after running bootstrap)
  masterKey = "age1g6lu0x2sgal3gzegdgmwz4rgcr6phg3kpm8mnrk7cwvs7kpfpp0qh75uvl";

  # You can add additional keys for other machines if needed
  # machine2 = "age1...";
in
{
  # SSH Keys
  "ssh-github-personal.age".publicKeys = [ masterKey ];
  "ssh-github-work.age".publicKeys = [ masterKey ];
  "ssh-azure.age".publicKeys = [ masterKey ];

  # Tokens
  "azure-devops-pat.age".publicKeys = [ masterKey ];

  # Proxmox root password, pve1 (ers-srvprox-001, 172.25.65.5)
  "pve-root-password.age".publicKeys = [ masterKey ];

  # sudo password of ens-admin on the ensor DNS/DHCP host (simsandbox01, 172.25.64.10)
  "ensor-dns-admin.age".publicKeys = [ masterKey ];

  # Copies of Watcher_GDM server/secrets/{gap,dashboard}-env.age; re-copy after rotating there
  "ensor-gap-env.age".publicKeys = [ masterKey ];
  "ensor-dashboard-env.age".publicKeys = [ masterKey ];

  # Postgres logins, deployed as ~/.pgpass
  "pgpass.age".publicKeys = [ masterKey ];

  # Work config, kept out of this public repo
  "work-zsh.age".publicKeys = [ masterKey ];
  # OpenBao root tokens per oc context (`<context>=<token>` lines), read by `kbao` in work-zsh
  "openbao-tokens.age".publicKeys = [ masterKey ];
  "lazyops-config.age".publicKeys = [ masterKey ];
}
