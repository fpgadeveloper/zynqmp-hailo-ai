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
are advised to use a Linux virtual machine to build the Yocto projects. The Vivado
project (XSA) can still be built on Windows and copied to the Linux machine.
```

Plan for roughly **40 to 60 GB of free disk space per target**: each target gets its own
Yocto workspace under `Yocto/<target>/` (sources, the bitbake `tmp` directory and the
shared state cache).

To run the design you also need the hardware listed in [requirements](requirements): a
Hailo-8 M.2 module, the [RPi Camera FMC] with one or more Raspberry Pi Camera Module 2,
the [M.2 M-key Stack FMC] (or the [FPGA Drive FMC Gen4] for `zcu106`), a monitor that
supports 1920x1080 at 60 Hz, a microSD card (8 GB or more) and a card reader for your
PC.

## How to build

The build runner locates and sources the Vivado and Vitis settings itself, so there is no
need to source them by hand.

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
   Valid targets for Yocto are:
   {% for design in data.designs if design.yocto and design.publish %} `{{ design.label }}`{{ ", " if not loop.last else "." }} {% endfor %}

This command launches the corresponding Vivado build if that project has not already been
built and its hardware exported. The first build of a target downloads several GB of sources
(`repo sync`) and runs bitbake; most recipes are pulled from the public AMD sstate-cache
mirror, but the Hailo runtime recipes (`libhailort`, `hailortcli`, the TAPPAS post-processes)
and the parts of the GStreamer stack that depend on them build from source. Subsequent
builds are incremental.

To build everything for a target (XSA, PetaLinux and Yocto images) and collect the boot
files into `bootimages/`, run `./build.sh all --target <target>` instead. To build only the
Yocto image and collect it, run `./build.sh yocto --target <target>` followed by
`./build.sh package --target <target>`.

### Output products

The output products are gathered into `Yocto/<target>/images/linux/`:

| File | Description |
| --- | --- |
| `BOOT.BIN` | Boot image (PMU firmware, FSBL, bitstream, TF-A, U-Boot) |
| `boot.scr` | U-Boot boot script (sets the kernel command line) |
| `Image` | Linux kernel |
| `system.dtb` | Linux device tree |
| `rootfs.wic.xz` | Full SD-card disk image — this is what you flash |
| `rootfs.wic.bmap` | Block map for flashing with `bmaptool` |
| `rootfs.tar.gz` | Root filesystem tarball |

`./build.sh package` (or `all`) writes `bootimages/zynqmp-hailo-ai_<target>_yocto-2025-2.zip`
with `rootfs.wic.xz`, `rootfs.wic.bmap`, `BOOT.BIN` and a `readme.txt` with the flashing
steps below.

### What the image contains

* The Hailo runtime stack, all from HailoRT **4.23.0**: `libhailort`, `hailortcli`,
  `pyhailort`, the `hailo-pci` kernel driver and the Hailo-8 firmware, plus the
  GStreamer integration (`libgsthailo`, `libgsthailotools`, `hailo-post-processes`).
* The camera and demo scripts in `/usr/bin`: `init_cams.sh`, `displaycams.sh` and
  `hailodemo.sh`, with the YOLOv5m network `/usr/bin/resources/yolov5m_wo_spp_yuy2.hef`
  and its post-processing configuration `/usr/bin/resources/configs/yolov5.json`.
* GStreamer with the `v4l2src`, `kmssink`, `compositor`, `videoconvertscale` and
  `videotestsrc` elements, `modetest` (libdrm tests) and `v4l-utils`.
* `pciutils`, `nvme-cli`, `mtd-utils`, `nfs-utils`, `can-utils`; on the VCU targets also the
  VCU GStreamer examples.
* An SSH server and a DHCP client on the board's Ethernet port; on PYNQ-ZU the Wi-Fi
  station tools (see [PYNQ-ZU Wi-Fi](#pynq-zu-wi-fi)).

See `Yocto/bsp/<board>/meta-user/recipes-core/images/edf-linux-disk-image.bbappend` for the
full list.

(yocto-prepare-sd)=
## Prepare the SD card

The Yocto flow produces a **full SD-card disk image** (`rootfs.wic.xz`) that already contains
all partitions. You write that image to the SD card's raw device, then copy `BOOT.BIN` onto
the first FAT partition: the image does not place `BOOT.BIN` where the BootROM of the Zynq
UltraScale+ looks for it.

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
   device, and `<target>` with your target design, throughout the steps below.

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

4. **Install `BOOT.BIN` on the first partition.** The first partition of the card (`esp`,
   FAT) is where the BootROM looks for `BOOT.BIN`:
   ```
   sudo partprobe /dev/sdX
   sudo mkdir -p /mnt/sd_esp
   sudo mount /dev/sdX1 /mnt/sd_esp
   sudo cp Yocto/<target>/images/linux/BOOT.BIN /mnt/sd_esp/BOOT.BIN
   sync
   sudo umount /mnt/sd_esp && sudo rmdir /mnt/sd_esp
   ```
   If your desktop auto-mounted the partition (for example at `/media/<you>/esp`), you can
   copy `BOOT.BIN` there instead.

5. Eject the card cleanly so pending writes flush:
   ```
   sudo eject /dev/sdX
   ```

On the card, `p1` is the FAT `esp` partition (with `BOOT.BIN`), `p2` the boot partition
(kernel and `boot.scr`, mounted at `/boot`) and `p3` the ext4 root filesystem. The root filesystem is mounted from `/dev/mmcblk0p3`; on `uzev` the on-SOM
eMMC enumerates as `mmcblk0` and the SD card as `mmcblk1`, and the boot script picks
`/dev/mmcblk1p3` automatically.

## Boot

1. Plug the SD card into the target board (on the UltraZed-EV, the SD card slot of the
   carrier card).
2. Set the board to boot from SD card. The boot-mode switch settings are the same as for
   PetaLinux — see [boot mode settings](petalinux-boot-mode).
3. Connect the FMC cards, cameras, monitor and USB-UART as described in
   [hardware setup](run-and-test).
4. Open a terminal emulator at 115200 baud (8N1) on the board's USB-UART and power up the
   board.

U-Boot runs the boot script from the SD card and starts the kernel through its EFI
loader. The kernel command line combines the defaults from the device tree with the
root device and this design's arguments: `cma=1536M` (`cma=1000M` on `uzev`) reserves
contiguous memory for the frame buffers and the Hailo DMA buffers, and
`xlnx_mixer.connect_drm_bridge=1` connects the Video Mixer to the DisplayPort controller.
An excerpt of the boot log on the ZCU104:

```
U-Boot 2025.01 ...
Model: Xilinx ZynqMP
DRAM:  2 GiB
...
Found U-Boot script /boot.scr
...
EFI stub: Booting Linux Kernel...
[    0.000000] Linux version 6.12.40-xilinx ...
[    0.000000] Kernel command line: earlycon console=ttyPS0,115200 clk_ignore_unused init_fatal_sh=1 root=/dev/mmcblk0p3 ro rootwait uio_pdrv_genirq.of_id=generic-uio cma=1536M xlnx_mixer.connect_drm_bridge=1
...
[    2.373605] xilinx-xdma-pcie 500000000.axi-pcie: PCIe Link is UP
...
Welcome to AMD Embedded Development Framework Linux distribution 25.11.1 (scarthgap)!
...
[   10.962908] hailo: Init module. driver version 4.23.0
...
[   11.535951] hailo 0000:01:00.0: Probing: Added board 1e60-2864, /dev/hailo0
...
zcu104-hailo-2025-2 login:
```

The root filesystem is mounted read-only first and remounted read-write by systemd during
boot.

## Log in

Log in on the console as **`amd-edf`**. On the first login you are asked to set a new
password. The hostname is `<board>-hailo-2025-2`, for example `zcu104-hailo-2025-2`. Use
`sudo` (with the same password) for the hardware commands.

If the board is connected to your network, it gets an IP address by DHCP and you can log
in over SSH as well:

```
ip -br addr
ssh amd-edf@<board-ip-address>
```

On the ZCU104 and ZCU106, the device tree of the Yocto image gives the Ethernet port a
fixed MAC address (in `Yocto/bsp/<board>/meta-user/recipes-bsp/device-tree/files/system-user.dtsi`,
`local-mac-address` of `&gem3`). If you run more than one of these boards on the same
network, give each one its own address there.

## Run and test

Running the multi-camera and Hailo-8 demos is the same for both Linux flows: see
[Run and test the design](run-and-test) for the step-by-step checks (PCIe link,
`/dev/hailo0`, `hailortcli`, cameras, a headless camera-to-Hailo pipeline, `hailodemo.sh` on
the monitor, and an NVMe SSD in the second M.2 slot).

(pynq-zu-wi-fi)=
## PYNQ-ZU Wi-Fi

The PYNQ-ZU has no Ethernet port. Its only network interface is the on-board Microchip
WILC3000 Wi-Fi module, which the Yocto image supports as a Wi-Fi station (`wlan0`): the
kernel driver with WILC3000 support, the WILC3000 firmware, `wpa_supplicant`, `iw` and a
DHCP client. The image ships **no Wi-Fi credentials**, so the radio stays off until you set
them up on the board.

From the serial console, run `wifi-sta-setup` with the network name (SSID) and, optionally,
your two-letter country code (default `US`). It reads the passphrase from standard input,
so it does not appear on the command line:

```
sudo wifi-sta-setup "<SSID>" CA
<type the passphrase and press Enter>
```

The script stores the network (with the passphrase as a hash) in
`/etc/wpa_supplicant/wpa_supplicant-wlan0.conf`, starts `wpa_supplicant@wlan0` and waits up
to 60 seconds for an address:

```
wlan0 up: <IP address>/<prefix>
```

The configuration is kept on the SD card, so the board joins the network at every boot.
For an open network use `sudo wifi-sta-setup --open "<SSID>"`. To configure the network by
hand instead, start from the template `/etc/wpa_supplicant/wpa_supplicant-wlan0.conf.example`.
Useful checks: `iw dev wlan0 link`, `sudo wpa_cli -i wlan0 status`, `ip -br addr show wlan0`
and `sudo dmesg | grep -i wilc`. Power saving is turned off on `wlan0` for a stable link.

## Patches and known issues

The per-board fixups applied in the Yocto flow live in `Yocto/bsp/<board>/` — chiefly the
`system-user.dtsi` device-tree overrides, the kernel patches and `bsp.cfg` fragments under
`recipes-kernel/`, and `conf/local.conf.append`. The changes that matter when you use the
design are listed in the [revision history](revision_history) and described in
[advanced](advanced) and [troubleshooting](troubleshooting).

### PYNQ-ZU PCIe reference clock

On the PYNQ-ZU, the FMC GT reference clock reaches the GT through the board's Si5324 jitter
attenuator, which must be configured to pass the 100 MHz clock through (see
[board specific notes](pynqzu-notes)). The Yocto image does this at the start of the U-Boot
boot script (`boot.scr`), with the same commands as the PetaLinux BSP's U-Boot environment.

[FPGA Drive FMC Gen4]: https://docs.opsero.com/op063/datasheet/overview/
[M.2 M-key Stack FMC]: https://docs.opsero.com/op073/datasheet/overview/
[RPi Camera FMC]: https://docs.opsero.com/op068/datasheet/overview/
[supported Linux distributions]: https://docs.amd.com/r/en-US/ug1144-petalinux-tools-reference-guide/Setting-Up-Your-Environment
