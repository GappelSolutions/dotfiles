{
  age.identityPaths = [
    "/home/cgpp/.age/master.key"
  ];

  age.secrets = {
    azure-devops-pat = {
      file = ../../secrets/azure-devops-pat.age;
      path = "/home/cgpp/.azure-devops-pat";
      owner = "cgpp";
      mode = "600";
    };
    pgpass = {
      file = ../../secrets/pgpass.age;
      path = "/home/cgpp/.pgpass";
      owner = "cgpp";
      mode = "600";
    };
    # The paths ~/.claude/ensor.md documents
    ensor-dns-admin = {
      file = ../../secrets/ensor-dns-admin.age;
      path = "/home/cgpp/.secrets/ensor/dns-admin";
      owner = "cgpp";
      mode = "600";
    };
    ensor-pve-root = {
      file = ../../secrets/pve-root-password.age;
      path = "/home/cgpp/.secrets/ensor/pve-root";
      owner = "cgpp";
      mode = "600";
    };
    # Work config, kept out of this public repo
    work-zsh = {
      file = ../../secrets/work-zsh.age;
      path = "/home/cgpp/.work.zsh";
      owner = "cgpp";
    };
    openbao-tokens = {
      file = ../../secrets/openbao-tokens.age;
      owner = "cgpp";
      mode = "400";
    };
    lazyops-config = {
      file = ../../secrets/lazyops-config.age;
      path = "/home/cgpp/.config/lazyops/config.toml";
      owner = "cgpp";
    };
  };
}
