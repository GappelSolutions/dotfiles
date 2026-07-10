{ lib, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")
    ./common.nix
  ];

  image.baseName = lib.mkForce "minix";
}
