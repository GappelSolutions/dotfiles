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
  };
}
