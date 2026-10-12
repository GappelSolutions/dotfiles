{ ... }:

{
  environment.systemPackages = [];

  # qemu-user emulation so `nix build` can cross-build aarch64-linux
  # derivations (e.g. the work-dash Raspberry Pi image) on this x86_64 box.
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  # With sparseVhd (win-host/.wslconfig) a trim shrinks ext4.vhdx, so space
  # freed in WSL (nix-gc) goes back to C:. fstrim is on by default but
  # skipped: systemd sees WSL as a container.
  systemd.timers.fstrim.unitConfig.ConditionVirtualization = "";
  systemd.services.fstrim.unitConfig.ConditionVirtualization = "";
}
