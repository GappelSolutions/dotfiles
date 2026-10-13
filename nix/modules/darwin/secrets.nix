{
  age.identityPaths = [
    "/Users/cgpp/.age/master.key"
  ];

  age.secrets = {
    ssh-github-personal = {
      file = ../../secrets/ssh-github-personal.age;
      path = "/Users/cgpp/.ssh/id_ed25519";
      owner = "cgpp";
      mode = "600";
    };
    ssh-github-work = {
      file = ../../secrets/ssh-github-work.age;
      path = "/Users/cgpp/.ssh/id_ed25519_work";
      owner = "cgpp";
      mode = "600";
    };
    ssh-azure = {
      file = ../../secrets/ssh-azure.age;
      path = "/Users/cgpp/.ssh/id_azure_rsa";
      owner = "cgpp";
      mode = "600";
    };
    pgpass = {
      file = ../../secrets/pgpass.age;
      path = "/Users/cgpp/.pgpass";
      owner = "cgpp";
      mode = "600";
    };
    # The paths ~/.claude/ensor.md documents
    ensor-dns-admin = {
      file = ../../secrets/ensor-dns-admin.age;
      path = "/Users/cgpp/.secrets/ensor/dns-admin";
      owner = "cgpp";
      mode = "600";
    };
    ensor-pve-root = {
      file = ../../secrets/pve-root-password.age;
      path = "/Users/cgpp/.secrets/ensor/pve-root";
      owner = "cgpp";
      mode = "600";
    };
    # Work config, kept out of this public repo
    work-zsh = {
      file = ../../secrets/work-zsh.age;
      path = "/Users/cgpp/.work.zsh";
      owner = "cgpp";
    };
  };
}
