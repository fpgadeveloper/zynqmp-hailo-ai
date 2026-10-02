# Troubleshooting

## Build failures

Check the following if the project fails to build or generate a bitstream:

1. **Are you using the correct version of Vivado for this version of the repository?**
   Check the version specified in the Requirements section of the README.md file.

2. **Did you follow the** [build instructions](build_instructions) **?**
   If it still doesn't build, please let us know and provide details of your setup and the error message(s).

3. **`libhailort` / `hailortcli` fail at `do_configure` with a CA-cert path
   under `/usr/local/oe-sdk-hardcoded-buildpath/...`** (PetaLinux only). This is the
   PetaLinux 2025.2 eSDK `git-native` CA-bundle relocation issue.
   Apply the one-time sudo symlink described in
   [Build issue and workaround](build-issue-and-workaround).
   `PetaLinux/Makefile` runs a `check_ca_workaround` prerequisite that
   prints the same fix if you haven't applied it yet.

4. **`bitbake petalinux-image-minimal failed` with `_setscene Fetcher failure`
   errors.** Transient public sstate mirror 404s. Re-run the same
   `./build.sh petalinux --target <board>` command; the second attempt finds
   the packages in the local sstate cache populated by the first run.

5. **The Yocto build stops before it starts bitbake.** Check that the `repo` tool is on
   your `PATH` and that Vitis 2025.2 is installed (the flow needs `sdtgen` from Vitis).

## Hailo-8

### The Hailo-8 is not listed by `lspci`

* Check that the module is in **M.2 slot 1** and fully seated, and that the M.2 adapter
  is on the right FMC connector for your target (see the
  [target designs](target-designs) table; `zcu106` uses HPC1 for the
  [FPGA Drive FMC Gen4]).
* **VADJ**: the FMC cards need the board's VADJ supply. On the ZCU104, the FSBL sets VADJ
  from the FMC card's EEPROM; the ZCU104 BSPs carry a patched FSBL that reads the FMC
  EEPROM correctly (see [advanced](advanced)). On the PYNQ-ZU and the
  UltraZed-EV carrier, VADJ is fixed at 1.8 V.
* On PYNQ-ZU, the GT reference clock passes through the board's Si5324, which U-Boot
  configures at every boot, in both the PetaLinux and the Yocto image (see
  [board specific notes](pynqzu-notes)). The Yocto boot script prints
  `Programming Si5324 (PCIe reference clock)` on the UART. If the Si5324 is not configured,
  Linux stops responding while it probes the XDMA PCIe host.
* Check the kernel log for the PCIe host driver: `sudo dmesg | grep -i xdma` should show
  `PCIe Link is UP`.

### The link is narrower or slower than expected

The expected link is **Gen3 (8 GT/s) x1** on `zcu104`, `zcu106` and `pynqzu`, and
**Gen3 x4** on `zcu106_hpc0` and `uzev` (see
[PCIe link per target](pcie-link-per-target)). `lspci` reports the x1 link as
"Width x1 (downgraded)" because the module supports x4: that is normal. The inference rate
of the bundled network (about 150 FPS) is the same on x1 and x4. A link below 8 GT/s, or
narrower than the target's width, points at the module seating or the FMC connection.

(hailort-version-mismatch)=
### HailoRT version mismatch

The `hailo_pci` driver, the Hailo-8 firmware it loads, the HailoRT library and
`hailortcli` must all be the **same version** (4.23.0 in this release), and the HEF files
you run must be compiled with a Hailo Dataflow Compiler that is compatible with that
HailoRT version. A mismatch shows as a version error from `hailortcli` or from the
`synchailonet` GStreamer element, or as a failure to configure the network on the device.
Check the three versions:

```
sudo dmesg | grep "hailo: Init module"
cd /tmp && sudo hailortcli fw-control identify | grep "Firmware Version"
hailortcli --version
```

The images built from this repository have matching versions and a matching HEF
(`/usr/bin/resources/yolov5m_wo_spp_yuy2.hef`). If you bring your own HEF, compile it for
HailoRT 4.23.0. If you update HailoRT (the `meta-hailo` submodule), update the driver and
firmware with it, and recompile your HEFs.

### `hailo` driver WARN_ON in `find_vma()`

The HailoRT v4.23 `hailo_pci` driver calls `find_vma()` without
holding `mmap_lock`, which the 6.12 kernel of the 2025.2 tools asserts on. Both BSPs
apply a backport of the fix that Hailo shipped for newer kernels — see
`recipes-kernel/hailo-pci/` in `PetaLinux/bsp/<board>/project-spec/meta-user/` and
`Yocto/bsp/<board>/meta-user/`. If you see the WARN_ON, confirm the bbappend's
`do_compile:prepend()` hook ran (it logs
`Applying hailo-pci mmap_lock patch for kernel >= 6.5`).

## NVMe SSD in the second M.2 slot is not detected

* The second slot is only connected on `zcu106_hpc0` and `uzev`. On `zcu104`, `pynqzu` and
  `zcu106` it has no GT lanes.
* If `lspci` lists the SSD but `sudo nvme list` shows nothing, look for
  `can't assign` / `failed to assign` lines in `sudo dmesg`. They mean that the SSD's
  non-prefetchable BAR could not be placed: the image was built from an earlier version of
  the design whose PCIe windows were above 4 GB. Rebuild the XSA and the Linux image from
  this release (see [PCIe address map](pcie-address-map)).

## Display

### Black screen on DisplayPort

* The display pipeline outputs **1920x1080 at 60 Hz** only. Use a monitor that accepts this
  mode, and with an HDMI monitor an active DP-to-HDMI adapter.
* The 2025.2 Video Mixer → DisplayPort pipeline requires
  `xlnx_mixer.connect_drm_bridge=1` on the kernel command line. All
  BSPs in this repo set it (PetaLinux: `CONFIG_SUBSYSTEM_USER_CMDLINE`; Yocto:
  `BSP_EXTRA_BOOTARGS` in `conf/local.conf.append`). If you
  override the command line in a fork, keep that argument or the mixer will not connect
  to the DisplayPort controller. Check with `cat /proc/cmdline`.
* Nothing is shown until a program sets a display mode: run `sudo displaycams.sh` or
  `sudo hailodemo.sh`.

### `hailodemo.sh` picks the wrong resolution

`hailodemo.sh` sets 1920x1080 at 60 Hz, whatever the monitor's preferred mode is. An image
built from an earlier version of the script used the monitor's first listed mode (for
example 2560x1440), which this pipeline cannot drive. Check the script on your image:

```
grep DISP_RES= /usr/bin/hailodemo.sh
```

It must print `DISP_RES=1920x1080`; otherwise rebuild the image from this release.

### Kernel crash or hang at the first display mode set (Yocto)

The display Clocking Wizard computes its settings from the rate of its input clock, which
the device tree describes. If that rate is wrong, the wizard does not lock at the first
mode set and the kernel stops with an SError from the Video Timing Controller. Before
running the demo you can check the clock on a running board:

```
sudo grep -E "misc_clk_0|clk_wiz" /sys/kernel/debug/clk/clk_summary
```

At boot, before any mode set, the wizard's input (`misc_clk_0`, consumer `clk_in1`) must
read 250 MHz (249997500) and its output `<address>.clk_wiz_out0` about 262.7 MHz. After a
successful 1920x1080 at 60 Hz mode set, `clk_wiz_out0` reads 148.5 MHz:

```
 misc_clk_0         ...   249997500  ...  80010000.clk_wiz      clk_in1
    80010000.clk_wiz_out0  ...  148500278  ...  fd4a0000.display   dp_live_video_in_clk
```

An input of 100 MHz (and an output of about 105 MHz at boot) means the Yocto image was
built from an earlier version of the BSP device tree, which had the two fixed-clock
overrides `misc_clk_0` / `misc_clk_1` swapped. Rebuild it from this release. The PetaLinux
images are not affected (the PetaLinux device-tree generator numbers these clocks the
other way round, and its BSP matches). If the kernel has stopped, power-cycle the board.

(magenta-tint-on-the-camera-pictures)=
### Magenta tint on the camera pictures

If white and grey objects look pink or magenta on every camera, the image was built
without the ISP driver fix of this release: the driver wrote each per-channel gamma table
to the wrong colour plane, and its default green curve differed from red and blue, which
lifted the red mid-tones. Rebuild the image from this release. On an existing image you
can remove the tint at runtime by setting the three gamma controls equal on every ISP:

```
for s in /dev/v4l-subdev*; do
  case "$(cat /sys/class/video4linux/$(basename $s)/name)" in
    *ISPPipeline*) sudo v4l2-ctl -d $s --set-ctrl=red_gamma=20,green_gamma=20,blue_gamma=20;;
  esac
done
```

A warm tint that follows the scene (for example under a warm lamp) is the grey-world
auto white balance at work, not a fault; see
[Fine-tune the camera picture](isp-controls).

## Boot-time issues

### SD init fails with `-110` on ZCU104

The Vivado design for this repo (and other Opsero ZynqMP designs)
exports a minimal `sdhci1` node into the XSA. The 2025.2 PetaLinux
device-tree generator does not fill in the bus-width / clock-frequency /
voltage properties this controller needs, and Linux times out with
-110 during SD card init. The ZCU104 BSP adds an explicit `sdhci1`
override block in `system-user.dtsi` that restores the properties the
stock AMD ZCU104 BSP carries. If you forked the BSP, copy that block
over.

### Yocto: the board does not boot from a freshly written SD card

The BootROM loads `BOOT.BIN` from the first FAT partition of the card, and the Yocto disk
image does not put it there. Copy `BOOT.BIN` onto partition 1 after writing the image
(see [Prepare the SD card](yocto-prepare-sd)).

### Yocto: Ethernet link is up but no traffic (ZCU104 / ZCU106)

The device tree generated in the Yocto flow does not describe the TI DP83867 Ethernet PHY
of these boards, so Linux falls back to a generic PHY driver that does not program the
RGMII clock delays: the link comes up at 1 Gb/s but passes no packets. The Yocto BSPs of
this release add the PHY node (with the delays of the official board device tree) to
`system-user.dtsi`. Rebuild an image built from an earlier version.
