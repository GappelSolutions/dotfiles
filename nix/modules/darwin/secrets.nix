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
  };
}
