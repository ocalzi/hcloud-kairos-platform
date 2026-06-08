# Worker/role-specific servers live here. The gateway is in gateway.tf for
# visibility — it owns DNAT, the default route, and is the first node to
# come up.
#
# Two-phase boot for every node spawned via this module:
#   1. tofu apply  -> Hetzner creates the VM with the Kairos ISO attached.
#                     The throwaway disk image (debian-13) lets the VM PXE-boot
#                     the CD-ROM. Kairos auto-installer wipes the disk, writes
#                     itself, and powers the VM off.
#   2. hcloud-postinstall scans for VMs in `off` state with a Kairos ISO
#      attached, runs `hcloud server detach-iso` + `hcloud server poweron`,
#      and the VM comes back up booted from disk.
#
# Without step 2 the VM stays off forever — Hetzner has no opinion about what
# you do after Kairos powers itself off, and the ISO stays mounted so a manual
# reboot would just re-run the installer.
