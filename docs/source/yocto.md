# Yocto

The Yocto / EDF flow (AMD's Embedded Development Framework) is the announced successor to
PetaLinux. It can be built for these reference designs with the cross-platform `build.py`
runner at the root of the repository.

```{note}
For 2025.2 both the PetaLinux and Yocto flows are supported and produce an equivalent
image. From the next tool version onward, the PetaLinux flow for this repository will be retired
and Yocto will be the only supported flow — see [build instructions](build_instructions).
```

## Requirements

To build the Yocto projects you will need a physical or virtual machine running one of the
[supported Linux distributions], with the Vitis Core Development Kit installed — the flow uses
`xsct`/`sdtgen` (which ship with Vitis) to generate a System Device Tree from the Vivado XSA. You
also need [Google's repo tool](https://gerrit.googlesource.com/git-repo/) on your `PATH`.

```{attention}
You cannot build the Yocto projects in the Windows operating system. Windows users
are advised to use a Linux virtual machine to build the Yocto projects.
```

## How to build

The build runner locates and sources the Vivado and Vitis settings itself, so there is no
need to source them by hand; you only need [Google's repo tool](https://gerrit.googlesource.com/git-repo/)
on your `PATH` (see Requirements above).

1. From a command terminal, clone the Git repository (with its submodules) and `cd` into it:
   ```
   git clone --recurse-submodules https://github.com/fpgadeveloper/zynqmp-hailo-ai.git
   cd zynqmp-hailo-ai
   ```
2. Build the Yocto image for your target by running the following command, replacing
   `<target>` with one of the target design labels listed in the
   [build instructions](build_instructions.md):
   ```
   ./build.sh yocto --target <target>
   ```

This command launches the corresponding Vivado build if that project has not already been
built and its hardware exported. The first build of a target downloads several GB of sources
(`repo sync`) and runs bitbake; most recipes are pulled from the public AMD sstate-cache
mirror, but the Hailo runtime recipes (`libhailort`, `hailortcli`, the TAPPAS post-processes)
and the parts of the GStreamer/qt5 stack that depend on them build from source. Subsequent
builds are incremental. The output products are gathered into `Yocto/<target>/images/linux/`:

| File | Description |
| --- | --- |
| `BOOT.BIN` | Boot image (FSBL + bitstream + U-Boot) |
| `boot.scr` | U-Boot boot script |
| `Image` | Linux kernel (Zynq UltraScale+) |
| `system.dtb` | Linux device tree |
| `rootfs.wic.xz` | Full SD-card disk image — this is what you flash |
| `rootfs.tar.gz` | Root filesystem tarball |

The image installs the Hailo runtime stack (HailoRT — `libhailort`, `hailortcli`, `pyhailort`;
the `hailo-pci` kernel driver; and the `libgsthailo` / `hailo-post-processes` GStreamer
integration) alongside the RPi-camera and GStreamer tooling, so the same `displaycams.sh` and
`hailodemo.sh` demos used in the PetaLinux flow work unchanged. See the
`Yocto/bsp/<board>/meta-user/recipes-core/images/edf-linux-disk-image.bbappend` `IMAGE_INSTALL`
list for the full set.

## Boot from SD card

Unlike the PetaLinux flow (which produces separate boot files for a hand-partitioned card), the
Yocto flow produces a **full SD-card disk image** (`rootfs.wic.xz`) that already contains all
partitions. You flash that image to the SD card's raw device, then — since these are all Zynq
UltraScale+ designs — copy `BOOT.BIN` onto the first FAT partition.

### Prepare the SD card

```{warning}
Flashing writes directly to a raw block device and cannot be undone. Be absolutely
certain you have identified the SD card's device node before running the commands below — if you
use the wrong device you risk destroying data on one of your hard drives.
```

1. Identify the SD card device. With the card **un**plugged, run:
   ```
   lsblk -o NAME,SIZE,RM,TYPE,MOUNTPOINT
   ```
   Insert the card and run the same command again. The new entry — typically `/dev/sdX`, with
   `RM=1` (removable) and a size matching your card — is your target. Replace `sdX` with that
   device, and `<target>` with your board, throughout the steps below.

2. Unmount any partitions the desktop auto-mounted:
   ```
   for p in /dev/sdX?*; do sudo umount "$p" 2>/dev/null; done
   ```

3. Flash the wic image to the raw device. With `bmaptool` (fast — only writes the blocks that are
   actually used):
   ```
   sudo bmaptool copy --bmap Yocto/<target>/images/linux/rootfs.wic.bmap \
                            Yocto/<target>/images/linux/rootfs.wic.xz \
                            /dev/sdX
   ```
   Or, as a fallback with `dd` (slower — writes every block):
   ```
   xzcat Yocto/<target>/images/linux/rootfs.wic.xz \
       | sudo dd of=/dev/sdX bs=4M status=progress conv=fsync
   ```

4. **Install `BOOT.BIN` on the `esp` partition.** The EDF wic leaves the first FAT partition
   (`esp`) empty and installs `BOOT.BIN` onto the ext4 `boot` partition, which the BootROM cannot
   read. Since the BootROM loads `BOOT.BIN` from the first FAT partition, it must be copied onto
   `esp` by hand:
   ```
   sudo partprobe /dev/sdX
   cp Yocto/<target>/images/linux/BOOT.BIN /media/<you>/esp/BOOT.BIN
   sync
   ```
   If `esp` did not auto-mount, mount the first partition manually:
   ```
   sudo mkdir -p /mnt/sd_esp
   sudo mount /dev/sdX1 /mnt/sd_esp
   sudo cp Yocto/<target>/images/linux/BOOT.BIN /mnt/sd_esp/BOOT.BIN
   sync
   sudo umount /mnt/sd_esp && sudo rmdir /mnt/sd_esp
   ```
   ```{note}
   On `uzev` the on-SOM eMMC enumerates as `mmcblk0` and the SD card as `mmcblk1`; the ZynqMP boot
   script resolves the rootfs device dynamically, so it mounts on `mmcblk1p3`. On the ZCU104,
   ZCU106 and PYNQ-ZU the rootfs is on `mmcblk0p3`.
   ```

5. Eject the card cleanly so pending writes flush:
   ```
   sudo eject /dev/sdX
   ```

### Boot

1. Plug the SD card into the target board.
2. Set the board to boot from SD card. The boot-mode DIP-switch settings are the same regardless of
   the Linux flow — see the per-board switch settings under
   [Boot from SD card](petalinux.md#boot-from-sd-card).
3. Connect the [RPi Camera FMC] and the Hailo-8 M.2 module (on the [M.2 M-key Stack FMC], or the
   [FPGA Drive FMC Gen4] for the `zcu106` design) to the target board's FMC connector(s), and
   connect one or more [Raspberry Pi camera modules](https://www.raspberrypi.com/products/camera-module-v2/)
   to the RPi Camera FMC.
4. Connect a DisplayPort monitor (or an HDMI monitor via a DP-to-HDMI adapter).
5. Connect the USB-UART to your PC and open a terminal emulator at 115200 baud (8N1).
6. Connect and power your hardware.

## Run the cameras and Hailo demo

Once Linux has booted and you have logged in at the console, running the multi-camera and Hailo-8
demos is identical to the PetaLinux flow — the Yocto image ships the same `displaycams.sh` and
`hailodemo.sh` scripts and the same HailoRT runtime. See
[Test the cameras](petalinux.md#test-the-cameras) for the `v4l2-ctl --list-devices`,
`displaycams.sh` and `hailodemo.sh` walkthrough, including the expected `/dev/hailo0` enumeration
from the `hailo-pci` driver.

## Patches and known issues

The per-board fixups applied in the Yocto flow live in `Yocto/bsp/<board>/` — chiefly the
`system-user.dtsi` device-tree overrides and the kernel `bsp.cfg` fragments. These cover quirks
such as the deterministic `ttyPS0` console mapping, the DisplayPort live-video / Video Mixer
wiring the 2025.2 `xlnx-mixer` driver requires, the DP PSGTR reference clock on the ZCU104/ZCU106,
and the SD-card / eMMC and PSGTR setup on the `zcu104` and `uzev` boards. See the BSP sources and
[advanced](advanced) for details.

[FPGA Drive FMC Gen4]: https://docs.opsero.com/op063/datasheet/overview/
[M.2 M-key Stack FMC]: https://docs.opsero.com/op073/datasheet/overview/
[RPi Camera FMC]: https://docs.opsero.com/op068/datasheet/overview/
[supported Linux distributions]: https://docs.amd.com/r/en-US/ug1144-petalinux-tools-reference-guide/Setting-Up-Your-Environment
