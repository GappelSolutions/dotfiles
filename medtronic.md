# Medtronic CareLink in Omarchy Windows VM

Working setup for the MiniMed/CareLink Blue Adapter inside the Dockur Windows VM on Omarchy.

## Omarchy Windows SSH

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

This is restart-persistent because it is in Docker Compose. The adapter must exist as `/dev/ttyUSB0` before the VM starts.

On NixOS, set the password in an untracked env file before starting:

```sh
cp ~/dev/misc/dotfiles/windows/.config/windows/.env.example ~/.config/windows/.env
nvim ~/.config/windows/.env
chmod 600 ~/.config/windows/.env
winup
```

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
omarchy-windows-vm stop
ls -l /dev/ttyUSB* /dev/serial/by-id/*
lsusb | rg '10c4|ea60|Silicon'
omarchy-windows-vm start
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
