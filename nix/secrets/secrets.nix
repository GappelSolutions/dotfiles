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
}
