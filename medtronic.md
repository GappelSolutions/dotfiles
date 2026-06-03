# Medtronic CareLink in the NixOS Windows VM

Working setup for the MiniMed/CareLink Blue Adapter inside the Dockur Windows VM on NixOS.

## Windows SSH

Windows must have OpenSSH Server installed and running:

```powershell
Get-Service sshd
Get-NetTCPConnection -LocalPort 22 -State Listen
```

Docker Compose must expose Windows SSH:

```yaml
ports:
  - 127.0.0.1:2222:22/tcp
```

Host login:

```sh
ssh cgpp@127.0.0.1 -p 2222
```

Run Windows PowerShell from Linux:

```sh
ssh cgpp@127.0.0.1 -p 2222 powershell.exe -NoProfile
```

If SSH fails after VM boot, wait 30 seconds and retry.

## Current Fix

Do not pass the adapter through as raw USB. Raw `usb-host` makes Windows see the CP210x device, but the COM port fails to open.

Use QEMU `usb-serial` backed by the Linux host serial device instead:

```yaml
environment:
  ARGUMENTS: "-rtc base=localtime,clock=host,driftfix=slew -chardev serial,id=medtronic,path=/dev/ttyUSB0 -device usb-serial,chardev=medtronic,serial=fa245e596e45ec11ad72d7e6461fcfc8"
devices:
  - /dev/ttyUSB0:/dev/ttyUSB0
```

Actual file on the host:

```text
/home/cgpp/.config/windows/docker-compose.yml
```

Repo-managed source for the NixOS desktop host:

```text
windows/.config/windows/docker-compose.yml
nix/modules/desktop/windows-vm.nix
nix/modules/desktop/home-windows-vm.nix
```

The base Windows VM starts without the adapter:

```sh
winup
# or
cgpp-windows start --no-rdp
```

Start with CareLink serial passthrough only after the adapter exists as `/dev/ttyUSB0`:

```sh
winusb
# or
cgpp-windows start --usb --no-rdp
```

Start with CareLink serial passthrough and open RDP:

```sh
winrdp-usb
# or
cgpp-windows start --usb
```

On NixOS, the Home Manager module creates an untracked env file on first activation:

```sh
~/.config/windows/.env
```

The default file only sets `WINDOWS_USERNAME=cgpp`. If `WINDOWS_PASSWORD` is omitted, Dockurr uses its built-in initial password behavior.

## Restored Windows Images

The recovery flow restores the Windows VM from a backed-up `data.img`:

```sh
cgpp-windows restore --image /path/to/data.img
cgpp-windows start --usb
```

Do not symlink `~/.windows/data.img`. Dockur/QEMU can treat the symlink itself
as the disk image. Use the restore command so the active image is a real file:
hard link when possible, otherwise sparse/reflink copy or rsync.

## Why This Works

The Medtronic stick is physically:

```text
10c4:ea60 Silicon Labs CP210x UART Bridge
```

CareLink accepts adapter IDs including:

```text
10c4:ea60
0403:6001
```

Raw CP210x passthrough (`-device usb-host,vendorid=0x10c4,productid=0xea60`) detected the device but Windows could not open the serial port.

QEMU `usb-serial` exposes an FTDI-style USB serial device (`VID_0403&PID_6001`) to Windows while the Linux host handles the real CP210x serial line. CareLink accepts that and the COM port opens.

Expected Windows state:

```text
USB Serial Converter
USB Serial Port (COM5)
Instance ID contains VID_0403&PID_6001
COM5 OPEN ok
```

## Recovery

If CareLink stops finding the adapter:

```sh
windown
ls -l /dev/ttyUSB* /dev/serial/by-id/*
lsusb | rg '10c4|ea60|Silicon'
winrdp-usb
```

If `/dev/ttyUSB0` is missing, unplug and replug the Blue Adapter, then start the VM again.

Inside Windows, verify:

```powershell
Get-PnpDevice -PresentOnly | ? {
  $_.InstanceId -match 'VID_0403|PID_6001|VID_10C4|PID_EA60' -or
  $_.FriendlyName -match 'USB Serial|CP210|Silicon|FTDI|COM'
}

[System.IO.Ports.SerialPort]::GetPortNames()
```

Do not switch back to raw `usb-host` unless testing a new QEMU/driver version.
