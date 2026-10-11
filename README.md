# kp-manager

Hardened backup and sync manager for KeePass (`.kdbx`) databases across your PC, a USB flash drive, a NAS (CIFS/SMB) and Google Drive (rclone).

- one instance at a time (`flock`)
- SHA-256 verified copies, written atomically (temp file, verify, move)
- cleanup trap: unmounts and unlocks even on crash or Ctrl+C
- timestamped backups (`Database_YYYYMMDD_HHMMSS.kdbx`), restore, prune, dry run
- never opens or decrypts the database

## Install (user level, no root)

```bash
curl -fsSL https://raw.githubusercontent.com/LukasChaloupecky/kp-manager/main/install.sh | bash
```

This puts `kp-manager` in `~/.local/bin` and the man page in `~/.local/share/man/man1`.
If `~/.local/bin` is not in your `PATH`, the installer tells you the line to add to `~/.bashrc`.

Update: run the same command again. Pin a version with `... | bash -s -- --ref v2.0.0`.

Uninstall (your settings and logs are kept):

```bash
curl -fsSL https://raw.githubusercontent.com/LukasChaloupecky/kp-manager/main/install.sh | bash -s -- --uninstall
```

## Requirements

Bash 4.4+, `flock` and `sha256sum` (util-linux, coreutils). Per feature: `rclone` (Google Drive),
`mount.cifs` from `cifs-utils` plus `sudo` (NAS mounting), `lsblk` (USB menu).

## Quick start

```bash
kp-manager init          # setup wizard, tests the connections
kp-manager backup-pc
kp-manager update-flash
kp-manager --dry-run update-nas
man kp-manager
```
## Note

For devices such as a phone, it is recommended to synchronize your desktop with the device using Syncthing.
