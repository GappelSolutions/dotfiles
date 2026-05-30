# Minimal NixOS Desktop Plan

Goal: create a small, declarative NixOS desktop beside the existing Omarchy
install. It should feel like Caelestia's main frontend, but only copy the
functional shell surface we need. No broad Omarchy clone, no desktop app bundle,
and no hidden imperative setup beyond first-boot authentication.

## Current Machine Facts

- Host today: `cgpp-t14`, Lenovo ThinkPad T14 Gen 1.
- Disk: `/dev/nvme0n1`, 238.5 GB WDC NVMe.
- Existing boot: UEFI, Secure Boot disabled, Limine boots Omarchy/Arch.
- Existing layout: `/dev/nvme0n1p1` is a 2 GB ESP mounted at `/boot`;
  `/dev/nvme0n1p2` is a full-disk LUKS container with Btrfs subvolumes.
- Free space inside Omarchy Btrfs: about 147 GB.
- Target for NixOS dual boot: 64 GB carved out from the current LUKS/Btrfs
  partition after backup, from a live environment.

Do not resize this partition from the running Omarchy system. The first
destructive step is an offline backup and shrink operation from a live USB.

## Sources To Follow

- Caelestia shell is a Quickshell + Hyprland shell. It is not Waybar.
- The Caelestia flake exposes `packages.<system>.with-cli` and a Home Manager
  module at `homeManagerModules.default`.
- The shell expects practical desktop helpers: NetworkManager/nmcli,
  brightnessctl, ddcutil, app2unit, PipeWire, fonts, screenshot tooling, and
  Caelestia CLI for full functionality.
- Vimjoyer takeaways to encode here:
  - keep config in Git before risky edits;
  - distinguish rebuild, update, rollback, and garbage collection;
  - prefer declarative config over imperative installs;
  - use modules instead of a giant flake;
  - do not over-engineer before the desktop can boot and authenticate;
  - move toward flake-parts/dendritic-style modules only when it removes glue.

## Architecture Direction

Keep the existing host split and add a new host family:

```text
nix/
  flake.nix
  hosts/
    macbook/          # nix-darwin workstation
    dev/              # thin NixOS dev VM/server
    desktop/
      cgpp-t14/
        configuration.nix
        hardware-configuration.nix
        home.nix
        disko.nix     # later, only after partition policy is final
  modules/
    shared/           # CLI, dotfiles, editor, git, agent workflow
    nixos/            # base NixOS services
    desktop/          # graphical NixOS modules
      hyprland.nix
      caelestia.nix
      networking.nix
      audio.nix
      bluetooth.nix
      printing.nix
      power.nix
      input.nix
      browser-auth.nix
      agent.nix
      windows-vm.nix
```

`shared` stays portable. `desktop` owns everything that assumes Wayland,
systemd user sessions, laptop hardware, Bluetooth, printers, browser auth, or
Hyprland.

## Minimal Desktop Surface

System services:

- `networking.networkmanager.enable = true` for Wi-Fi and `nmcli`/`nmtui`.
- `hardware.bluetooth.enable = true` and `services.blueman.enable = true`.
- `services.printing.enable = true`, plus Avahi for network printers.
- `security.rtkit.enable = true`, PipeWire, WirePlumber, ALSA and Pulse compat.
- `services.power-profiles-daemon.enable = true` first; add TLP only if needed.
- `services.upower.enable = true` for battery reporting.
- `services.fwupd.enable = true` for firmware updates.
- `services.hardware.bolt.enable = true` for Thunderbolt/USB-C docks.
- `hardware.i2c.enable = true` and `ddcutil` for external monitor controls.
- `programs.hyprland.enable = true` with a small user config.
- XDG portals for Hyprland screen sharing and browser auth.

User/session packages:

- Caelestia shell with CLI through its Home Manager module.
- A terminal, `nmtui`, Zen browser, GitHub CLI, Codex CLI, Neovim, Zellij, and
  the existing shared CLI module.
- `wl-clipboard` and `cliphist` for clipboard history.
- `brightnessctl`, `pamixer`, `playerctl`, and `swayosd` or Caelestia IPC for
  Lenovo function keys and feedback.
- Keep file managers, media apps, chat apps, office suites, and branded webapps
  out until explicitly needed.

Windows/CareLink workload:

- Keep the Dockur Windows VM because CareLink currently needs it.
- Manage the compose file from `windows/.config/windows/docker-compose.yml`.
- Use Docker for this workload, because the current known-good setup is Dockur
  Windows with KVM, TUN, and QEMU arguments.
- Do not commit the Windows password. Runtime secrets live in
  `~/.config/windows/.env`.
- Preserve the Medtronic Blue Adapter fix from `medtronic.md`: pass
  `/dev/ttyUSB0` into QEMU as `usb-serial`, not raw `usb-host`.
- The Windows disk is configured as 64 GB. On the first 64 GB NixOS partition,
  expect disk pressure if the VM image lives in `/home/cgpp/.windows`; moving
  that storage to a later shared/data partition may be necessary.

## Caelestia Policy

Use Caelestia as the main frontend, not as a full borrowed dotfiles universe:

- Depend on `github:caelestia-dots/shell`.
- Use `programs.caelestia.enable = true`.
- Enable `programs.caelestia.cli.enable = true`.
- Start via Home Manager systemd user service unless Hyprland startup proves
  cleaner.
- Keep Caelestia config tiny: battery visibility, wallpaper path, terminal,
  launcher favorites, and theme behavior only.
- Do not copy the whole upstream `caelestia` rice repo.
- Do not port Omarchy Waybar/Walker. Caelestia replaces that surface.

## First Milestone: Dual Boot Bootstrap

Confirmed decisions:

- Hostname: `cgpp-t14-nix`.
- NixOS root encryption: yes, use a separate LUKS partition.
- Bootloader: add systemd-boot for NixOS on the existing ESP and keep Omarchy's
  Limine entry.
- Keyboard layouts: `de,us`, with `de` first and an Alt+Alt toggle.

Success criteria:

1. Omarchy still boots unchanged.
2. NixOS boots from its own 64 GB root partition.
3. First NixOS login can connect to Wi-Fi from TTY or Hyprland.
4. `git`, `gh`, `zen`, and `codex` are available.
5. Browser auth works for GitHub/OpenAI/Codex.
6. The dotfiles repo can be cloned and rebuilt from NixOS.

Safe sequence:

1. Commit/push all dotfiles changes.
2. Back up Omarchy user data and the LUKS header.
3. Boot a NixOS or GParted live USB.
4. Unlock `/dev/nvme0n1p2`.
5. Run `btrfs check --readonly` before resizing.
6. Shrink the Btrfs filesystem by at least 64 GB plus margin.
7. Shrink the LUKS mapping and partition boundary offline.
8. Create a new 64 GB partition for NixOS.
9. Install NixOS using the existing ESP, without formatting `/dev/nvme0n1p1`.
10. Add a new UEFI boot entry for NixOS and keep Limine/Omarchy intact.
11. Boot NixOS, connect Wi-Fi with `nmtui`, clone this repo, and rebuild.

Partitioning is the riskiest part. Prefer a full image backup if possible; at
minimum back up `~/dev`, `~/.ssh`, `~/.config`, browser auth material you care
about, and the LUKS header.

Because this Omarchy machine does not currently have Nix installed, update the
flake lock from the NixOS live environment or the first NixOS boot:

```bash
cd ~/dev/misc/dotfiles/nix
nix flake update
git add flake.lock
```

## First NixOS Config Shape

The initial desktop host should be boring:

```nix
{
  imports = [
    ./hardware-configuration.nix
    ../../../modules/desktop/base.nix
    ../../../modules/desktop/boot.nix
    ../../../modules/desktop/networking.nix
    ../../../modules/desktop/hyprland.nix
    ../../../modules/desktop/audio.nix
    ../../../modules/desktop/bluetooth.nix
    ../../../modules/desktop/printing.nix
    ../../../modules/desktop/power.nix
    ../../../modules/desktop/hardware-lenovo.nix
    ../../../modules/desktop/windows-vm.nix
  ];

  networking.hostName = "cgpp-t14-nix";
  system.stateVersion = "25.11";
}
```

Caelestia and the minimal Hyprland user config live in Home Manager modules:

```text
modules/desktop/home-caelestia.nix
modules/desktop/home-hyprland.nix
modules/desktop/home-windows-vm.nix
```

Use generated `hardware-configuration.nix` for the first install. Move to Disko
only after the manual dual boot has proven itself.

## Agent-First Shell Direction

Do not block the desktop milestone on the zsh-to-xonsh rewrite. Make xonsh a
separate Home Manager module after boot works:

- keep zsh available as a fallback shell;
- introduce `programs.xonsh.enable = true` when packaged cleanly;
- port aliases/functions by workflow, not line-by-line;
- center shell UX around `codex`, `zellij`, project launchers, and reproducible
  repo-local commands;
- avoid shell-managed package installs.

## Remaining Decisions

- Monitor name for Eizo 2740X: capture with `hyprctl monitors` once connected.
- Whether to keep a shared data partition later. Not needed for milestone 1.
