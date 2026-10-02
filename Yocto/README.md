# Yocto / EDF builds

This folder builds Linux images for the ZynqMP Hailo AI reference designs
using the AMD Yocto / Embedded Development Framework (EDF) flow — the
announced successor to PetaLinux Tools.

The design pairs the Zynq UltraScale+ PS+PL with a Hailo-8 AI accelerator
(an M.2 module reached over PCIe via the FPGA Drive FMC Gen4 or the M.2 M-key
Stack FMC) and up to four Raspberry Pi cameras on the RPi Camera FMC. The
Yocto image therefore layers the Hailo runtime stack and the camera/GStreamer
tooling onto the AMD EDF base (see "Image contents" below).

## How it works: the parse-sdt flow

The build generates a **custom Yocto MACHINE directly from the Vivado XSA** —
there is no dependency on an AMD-provided machine config. This is what lets
the design serve any board (including third-party boards with no AMD machine,
like the Avnet UltraZed-EV) and lets a customer change the PS or the PL in
Vivado and have it flow through automatically:

```
XSA  --sdtgen-->  System Device Tree  --gen-machineconf parse-sdt-->  MACHINE + DTS
```

`scripts/configure-build.sh` runs `xsct`/`sdtgen` on the XSA to produce a
System Device Tree (which includes `pl.dtsi`, the PL hardware extracted from
the design), then runs `gen-machineconf parse-sdt` to emit
`conf/machine/rpi-<target>.conf` plus the lopper-pruned per-domain device
trees (`cortexa53-linux.dts` for the ZynqMP Linux domain). The PL — the
MIPI capture pipelines and Video Processing Subsystems for the RPi cameras,
the Video Mixer, the DisplayPort live-video path, and the PCIe Root Port
(`xilinx_pcie_dma`, XDMA) that the Hailo-8 M.2 module attaches to — therefore
comes from the design's own SDT, with no hand-curated device tree. Because no
PL overlay is requested, the Vivado boot artifact (the `.bit`) is embedded into
`BOOT.BIN` (the FSBL programs the PL at boot, before Linux comes up).

The only per-board hand-written file is `system-user.dtsi`, which carries
SoC-side and PL-glue board quirks the XSA doesn't encode (see "Per-board
fixups" below).

## Image contents

`bsp/<board>/meta-user/recipes-core/images/edf-linux-disk-image.bbappend`
layers the design's userspace onto the AMD EDF base image via
`IMAGE_INSTALL:append`. The Hailo runtime and camera/GStreamer stack are:

* **HailoRT userspace** — `libhailort`, `hailortcli`, `pyhailort`,
  `hailo-firmware`
* **Hailo PCIe driver** — `hailo-pci` (the `hailo` kernel module that
  enumerates the M.2 accelerator as `/dev/hailo0`)
* **GStreamer integration** — `libgsthailo`, `libgsthailotools`,
  `hailo-post-processes` (the TAPPAS post-processing elements), plus
  `gstreamer-vcu-examples`
* **Camera + utility tooling** — `initcams`, `v4l-utils`, and the
  storage/flash/network helpers (`nvme-cli`, `pciutils`, `mtd-utils`,
  `nfs-utils`, `can-utils`)

## Prerequisites

Host packages on Ubuntu 22.04 / 24.04:

```
sudo apt-get install repo gawk wget git diffstat unzip texinfo gcc \
    build-essential chrpath socat cpio python3 python3-pip python3-pexpect \
    xz-utils debianutils iputils-ping python3-git python3-jinja2 \
    python3-subunit zstd liblz4-tool file locales libacl1 bmap-tools
```

Plus Vivado 2025.2 (used to produce the XSA this flow consumes) and Vitis
2025.2 — `sdtgen`/`xsct` (used to turn the XSA into a System Device Tree)
ship with Vitis, not Vivado, in 2025.2. The build runner locates and sources
the Vitis environment itself; sourcing it manually is only needed when
running the `scripts/` engine by hand:

```
source <xilinx-install>/2025.2/Vitis/settings64.sh
```

## Build

Yocto images are built with the cross-platform build runner at the repo root
(this stage requires a native Linux machine; on Windows the runner refuses
it up front and prints the hand-off command):

```
./build.sh yocto --target zcu104    # or any target from `./build.sh list`
```

The runner builds the Vivado XSA first if one isn't already present, then
sequences the four scripts in `scripts/` — the engine of the flow
(init-workspace, configure-build, build-image, package-output). The legacy
`cd Yocto && make yocto TARGET=<target>` still works on Linux (the Makefile
is now a thin wrapper around `build.sh`) but is deprecated.

The first build for a target:

1. Builds the Vivado project and exports the XSA if one isn't already
   present.
2. Initializes a manifest workspace under `Yocto/<TARGET>/` with
   `repo init -u https://github.com/Xilinx/yocto-manifests.git -b rel-v2025.2 -m default-edf.xml`
   and `repo sync` (≈5 GB of git history).
3. Sources `edf-init-build-env` to set up the bitbake environment.
4. Generates the System Device Tree from the XSA and runs
   `gen-machineconf parse-sdt` to create `MACHINE = "rpi-<target>"`
   (gen-machineconf builds its own native helpers — `kconfig-frontends-native`,
   `lopper`, etc. — via bitbake on first run).
5. Layers `bsp/<board>/conf/local.conf.append` (hostname, kernel cmdline) and
   `bsp/<board>/meta-user/` (kernel config, `system-user.dtsi` board fixups,
   the image bbappend that installs the Hailo runtime) over the EDF default
   config.
6. Runs `bitbake edf-linux-disk-image`.
7. Gathers `BOOT.BIN` (with the PL bitstream embedded), `Image`, `system.dtb`,
   `boot.scr`, `u-boot.elf`, `rootfs.tar.gz`, `rootfs.wic.xz`, and
   `rootfs.wic.bmap` into `Yocto/<TARGET>/images/linux/`.

Subsequent builds skip `repo sync`. To force a re-config (e.g. after editing
`bsp/<board>/conf/local.conf.append`), remove `Yocto/<TARGET>/configdone.txt`.

`./build.sh yocto --target all` builds every target; `./build.sh status --target all`
reports which are built.

Most of a first build is pulled from the public AMD sstate-cache mirror; only
the Hailo recipes (`libhailort`, `hailortcli`, the TAPPAS post-processes) and
the parts of the qt5/GStreamer stack that depend on them build from source.

## Per-board fixups (`system-user.dtsi`)

Each board's `bsp/<board>/meta-user/recipes-bsp/device-tree/files/system-user.dtsi`
is layered onto the generated Linux device tree (via `EXTRA_DT_INCLUDE_FILES`,
guarded so it only applies to the Linux domain DT — the FSBL/PMU domain DTs
don't define the SoC peripheral labels). It carries SoC-side board quirks plus
the small amount of PL-glue the 2025.2 driver stack needs, not the PL hardware
itself:

* **UART** (all boards): the 2025.2 flow emits `port-number = <0>` on both
  `uart0` and `uart1`, leaving the `ttyPS0`/`ttyPS1` mapping to probe order.
  Each board pins `ttyPS0` back to `uart0` (the console these boards are cabled
  to) and fixes the serial aliases so the console is deterministic.
* **DisplayPort live-video** (all boards): wires the `dpsub` live-video input
  (`port@0`) to the Video Mixer CRTC and the DP output (`port@5`) to the
  `dp-connector`, and adds the `xlnx,bridge` (VTC timing bridge) and
  `xlnx,video-format` properties the 2025.2 `xlnx-mixer` driver now requires on
  the `v_mix` node. Without this the DRM/KMS pipeline the camera demos draw to
  does not come up.
* **DP PSGTR reference clock** (`zcu104`, `zcu106`): the auto-generated
  `pcw.dtsi` references PSGTR refclk 3 for DP but declares no clock on the
  `psgtr` node, so DP probe fails with `-EINVAL`. These boards declare a 27 MHz
  fixed-clock (the DP refclk rate the FSBL programs). `pynqzu` and `uzev`
  already declare their PSGTR refclks, so they don't need this.
* **SD card** (`zcu104`): the design exports a minimal `sdhci1` node, so the
  override adds the properties Linux needs to bring up the slot and caps the
  SDR50/HS capability bits — without it the card init times out with
  `error -110`.
* **`uzev` only**: the Avnet UltraZed-EV is a third-party SOM+carrier, so its
  `system-user.dtsi` is the largest — eMMC (`SD0`, 8-bit) and the level-shifted
  `SD1` (capped out of HS), the `&psgtr` mapping for the PS-GTR-routed
  PCIe/SATA/USB3/DP, the Ethernet PHY + MAC-ID EEPROM, and the VersaClock I2C
  clock tree. It is ported from the proven PetaLinux `uzev` BSP.

## Flashing to SD card

The build produces a full wic disk image (`rootfs.wic.xz`). Flash it to the SD
card's raw device; per-partition file copies do **not** work because the boot
script boots from the device it finds itself on.

These designs are all Zynq UltraScale+, which uses the EDF 4-partition layout —
`esp` (vfat), `boot` (ext4), `root` (ext4), `storage` (vfat). The EDF wks
leaves the `esp` partition empty and installs `BOOT.BIN` onto the ext4 `boot`
partition (which the BootROM cannot read). The BootROM reads `BOOT.BIN` from the
first FAT partition (`esp`), so after flashing you must drop `BOOT.BIN` onto
`esp` by hand (step 4 below).

> On `uzev` the on-SOM eMMC enumerates as `mmcblk0` and the SD card as
> `mmcblk1`; the dynamic `root=/dev/mmcblk${devnum}p3` in the ZynqMP boot
> script handles this automatically (rootfs mounts on `mmcblk1p3`). On the
> ZCU104, ZCU106 and PYNQ-ZU the rootfs is on `mmcblk0p3`.

### 1. Identify the SD card device — carefully

This is the step that will eat one of your hard drives if you get it wrong.
`dd`-style writes to a block device cannot be undone.

With the SD card **un**plugged, list the block devices and note what's there:

```
lsblk -o NAME,SIZE,RM,TYPE,MOUNTPOINT
```

Now insert the SD card and re-run the same command. The new entry (typically
`/dev/sdX`, with `RM=1` for removable, and a size that matches your card) is
your target. Confirm with:

```
udevadm info --query=property --name=/dev/sdX | grep -E "ID_BUS|ID_MODEL"
```

`ID_BUS=usb` and a model like `SDXC/MMC` or your card-reader's name is what you
want to see. **Do not proceed until you are certain `/dev/sdX` is your SD card
and not an internal disk.** Throughout the rest of this section, replace `sdX`
with the actual device letter, and `<TARGET>` with your board.

### 2. Unmount any auto-mounted partitions

```
for p in /dev/sdX?*; do sudo umount "$p" 2>/dev/null; done
```

### 3. Flash the wic image to the raw device

Preferred: `bmaptool` only writes the blocks that are actually used, so it
finishes in a minute or two on a fast card:

```
sudo bmaptool copy \
    --bmap Yocto/<TARGET>/images/linux/rootfs.wic.bmap \
          Yocto/<TARGET>/images/linux/rootfs.wic.xz \
          /dev/sdX
```

Fallback (slower, writes every block):

```
xzcat Yocto/<TARGET>/images/linux/rootfs.wic.xz \
    | sudo dd of=/dev/sdX bs=4M status=progress conv=fsync
```

### 4. Install BOOT.BIN on the esp partition

```
sudo partprobe /dev/sdX
```

Most desktops will now expose `/media/<you>/esp` (and `boot`, `root`,
`storage`). Copy `BOOT.BIN` onto `esp`:

```
cp Yocto/<TARGET>/images/linux/BOOT.BIN /media/<you>/esp/BOOT.BIN
sync
```

If your desktop didn't auto-mount, mount `esp` (the first partition) manually:

```
sudo mkdir -p /mnt/sd_esp
sudo mount /dev/sdX1 /mnt/sd_esp
sudo cp Yocto/<TARGET>/images/linux/BOOT.BIN /mnt/sd_esp/BOOT.BIN
sync
sudo umount /mnt/sd_esp && sudo rmdir /mnt/sd_esp
```

### 5. Eject and boot

Eject the card cleanly (`sudo eject /dev/sdX`) so pending writes flush. Insert
it into the board, set the boot mode switches to SD (the switch settings are the
same regardless of the Linux flow — see the per-board settings under
[Boot from SD card](../docs/source/petalinux.md#boot-from-sd-card)), connect the
RPi Camera FMC + the Hailo-8 M.2 module (on the M.2 M-key Stack FMC, or the FPGA
Drive FMC Gen4 on `zcu106`), connect a DisplayPort monitor, power-cycle, and
attach a UART terminal at 115200 8N1. Then run the camera and Hailo demo scripts
as described in [Test the cameras](../docs/source/petalinux.md#test-the-cameras).

## Offline / faster builds

Place the absolute path to a directory containing an extracted AMD sstate-cache
mirror in `Yocto/offline.txt` — `configure-build.sh` auto-detects which
architecture subdirs exist under it and wires one `SSTATE_MIRRORS` entry per
arch (plus `SOURCE_MIRROR_URL` if a `downloads/` dir is present).

Expected layout under that path:

```
<sstate root>/
  aarch64/           (ZynqMP Linux)
  microblaze/        (the PMU firmware multiconfig)
  downloads/         (optional — the source-mirror tarballs)
```

Both `aarch64` and `microblaze` are needed: the generated MACHINE builds the
PMU firmware as a MicroBlaze multiconfig. The sstate-cache and downloads
archives are available behind login at the AMD Embedded Design Tools download
page under "sstate-cache & Downloads - 2025.2".

A warm sstate-cache typically gives a high hit rate; because each target uses a
distinct generated MACHINE name, the machine-specific recipes still rebuild
(architecture-level recipes hit the cache), so a first build is moderate rather
than from-scratch.

## Layout

```
Yocto/
  Makefile                  deprecated thin wrapper around ../build.sh
  README.md                 this file
  .gitignore                excludes per-target workspaces + local state
  offline.txt               (optional, gitignored) path to an extracted sstate mirror
  scripts/
    init-workspace.sh       repo init + sync
    configure-build.sh      sdtgen + gen-machineconf parse-sdt + apply BSP + sstate
    build-image.sh          bitbake the image recipe
    package-output.sh       gather deploy artifacts into images/linux/
  bsp/
    <board>/                one per board (zcu106 is shared by zcu106 + zcu106_hpc0)
      conf/
        local.conf.append   board overrides (hostname, kernel cmdline)
      meta-user/            Yocto layer: kernel cfg, system-user.dtsi, image
                            bbappend (installs the Hailo runtime + camera stack)
  <TARGET>/                 (gitignored) per-target workspace built by the runner
  tools/                    (gitignored) helper checkouts
  logs/                     (gitignored) build logs
```

## Architectural notes

* **The MACHINE is generated from the XSA** by `gen-machineconf parse-sdt`
  (the flow AMD recommends; `parse-xsa` is deprecated). This is the only
  build flow — there is no pinned AMD-validated MACHINE and no per-target
  flow selection. The custom machine is named `rpi-<target>` (the `rpi`
  prefix is the design's `bd_name` from `config/data.json`).

* **The bitstream lives in BOOT.BIN**, not loaded at runtime via FPGA manager.
  Because no PL overlay is requested, `fpga-overlay` is left out of
  `MACHINE_FEATURES`, so `xilinx-bootbin`'s `BIF_BITSTREAM_ATTR` defaults to
  `bitstream` and the bitstream `sdtgen` extracted from the XSA is embedded
  automatically. FSBL programs the PL during boot so the camera pipelines and
  the PCIe link to the Hailo-8 are live before Linux starts.

* **`system-user.dtsi` is scoped to the Linux device tree** (via a guard on
  `CONFIG_DTFILE`). The FSBL and PMU domain device-trees don't define the SoC
  peripheral labels (`uart0`/`uart1`, `sdhci1`, `psgtr`, …) the overrides
  reference, so including it there makes `dtc` fail with "Label or path … not
  found".

* **Adding a target**: set `"yocto": true` for the design in
  `config/data.json` and run `config/update.py` (regenerates the README table),
  then create `bsp/<board>/` following an existing board (start from `zcu106`
  for a stock AMD board; `uzev` shows the pattern for a board needing a rich
  `system-user.dtsi`).
