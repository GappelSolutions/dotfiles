# NixOS Recovery USB Plan

Goal: rebuild the ThinkPad from a USB stick with minimal manual work. The USB
boots a NixOS recovery environment, installs the current desktop host, restores
the Dockur Windows VM disk image, enables CareLink USB passthrough, and starts
Windows from the restored image.

The only intentionally manual step is destructive disk selection. The installer
must never silently wipe a disk.

## Current Machine State

- Hostname: `cgpp-t14-nix`.
- Target hardware: Lenovo ThinkPad T14 Gen 1.
- Internal disk: `/dev/nvme0n1`, 238.5 GB WDC NVMe.
- Current NixOS host output: `.#cgpp-t14-nix`.
- Fresh-install output: `.#cgpp-t14-recovery`.
- Recovery ISO output: `.#cgpp-recovery-iso`.
- Windows VM: Dockur Windows on Docker/KVM, stored at `~/.windows/data.img`.
- CareLink adapter: Linux sees the real CP210x adapter as `/dev/ttyUSB0`; QEMU
  exposes it to Windows as `usb-serial`, not raw `usb-host`.

## Repo Outputs

From `~/dev/misc/dotfiles/nix`:

```bash
nix build .#nixosConfigurations.cgpp-recovery-iso.config.system.build.isoImage
nix run .#cgpp-install -- tui
nix run .#cgpp-windows -- tui
```

Host outputs:

- `cgpp-t14-nix`: current running ThinkPad config using generated hardware
  UUIDs.
- `cgpp-t14-nix-lite`: same host without Caelestia.
- `cgpp-t14-recovery`: fresh-install config using Disko instead of generated
  UUID hardware config.
- `cgpp-recovery-iso`: graphical recovery ISO with `cgpp-install`,
  `cgpp-windows`, Disko, Docker, Git, Gum, and rsync.

## Recovery Flow

1. Boot the recovery USB.
2. Run `sudo cgpp-install tui`.
3. Mount the USB data partition if needed.
4. Select the internal disk to erase.
5. Select the Windows `data.img` on the USB.
6. Type the exact target disk path to confirm the wipe.
7. Let Disko partition/format/mount the disk and install `.#cgpp-t14-recovery`.
8. Restore the Windows VM image into `/mnt/home/cgpp/.windows/data.img`.
9. Reboot into the installed system.
10. Run `cgpp-windows start --usb` or launch “Windows CareLink”.

The installer creates `~/.windows/windows.boot` so Dockur boots the restored
image instead of downloading or installing a new Windows ISO.

## Windows Restore Rules

- `data.img` must be a real file. Do not use a symlink; Dockur/QEMU can treat
  the symlink itself as a tiny disk image.
- If source and destination are on the same filesystem, use a hard link.
- If not, copy with sparse/reflink support or rsync.
- Remove partial installer downloads from `~/.windows/tmp`.
- Keep runtime credentials in `~/.config/windows/.env`; do not commit them.
- Preserve `windows.rom`, `windows.vars`, and `windows.mac` if they are present
  beside the backup image.

## Disk Layout

Disko layout lives in `nix/disko/cgpp-t14.nix`:

- 2 GiB EFI system partition mounted at `/boot`.
- Remaining space as btrfs labeled `nixos`.
- btrfs subvolumes for `/`, `/home`, and `/nix`.

This layout is intentionally simple. The Windows workload is restored as a VM
image, not installed as a native Windows partition.

## Commands

Build recovery ISO:

```bash
cd ~/dev/misc/dotfiles/nix
nix build .#nixosConfigurations.cgpp-recovery-iso.config.system.build.isoImage
```

Run installer TUI from the ISO or a live Nix shell:

```bash
sudo cgpp-install tui
```

Non-interactive install, still with typed wipe confirmation:

```bash
sudo cgpp-install install \
  --disk /dev/nvme0n1 \
  --image /mnt/CGPP_USB/path/to/data.img
```

Restore Windows only into an already mounted target:

```bash
sudo cgpp-install restore \
  --image /mnt/CGPP_USB/path/to/data.img \
  --target-root /mnt
```

Manage Windows after boot:

```bash
cgpp-windows restore --image /path/to/data.img
cgpp-windows start --usb
cgpp-windows status
cgpp-windows logs
cgpp-windows stop
```

## Safety Policy

- The TUI may discover disks and images automatically.
- Partitioning must require explicit confirmation.
- The USB data partition can be mounted automatically.
- Windows restore can run automatically after the disk is selected.
- Starting Windows with CareLink USB can run automatically once `/dev/ttyUSB0`
  exists.
- The system should prefer recovery from committed repo config over ad hoc live
  commands.
