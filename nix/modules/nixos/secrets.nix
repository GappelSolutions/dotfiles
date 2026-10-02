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
    # Work config, kept out of this public repo
    work-zsh = {
      file = ../../secrets/work-zsh.age;
      path = "/home/cgpp/.work.zsh";
      owner = "cgpp";
    };
    lazyops-config = {
      file = ../../secrets/lazyops-config.age;
      path = "/home/cgpp/.config/lazyops/config.toml";
      owner = "cgpp";
    };
  };
}
