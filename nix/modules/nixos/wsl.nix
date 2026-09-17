{ ... }:

{
  environment.systemPackages = [];

  # qemu-user emulation so `nix build` can cross-build aarch64-linux
  # derivations (e.g. the work-dash Raspberry Pi image) on this x86_64 box.
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
}
