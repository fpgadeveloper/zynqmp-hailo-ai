# PetaLinux

PetaLinux can be built for these reference designs with the cross-platform `build.py`
runner at the root of the repository.

## Requirements

To build the PetaLinux projects, you will need a physical or virtual machine running one of the 
[supported Linux distributions] with PetaLinux Tools 2025.2 and the Vitis Core Development
Kit installed. Plan for roughly 40 to 50 GB of free disk space per target.

```{attention}
You cannot build the PetaLinux projects in the Windows operating system. Windows
users are advised to use a Linux virtual machine to build the PetaLinux projects.
```

```{important}
Before the first PetaLinux build on a machine, apply the one-time CA-certificate
workaround described in [Build issue and workaround](build-issue-and-workaround),
otherwise the Hailo recipes fail to configure.
```

To run the design you also need the hardware listed in [requirements](requirements).

## How to build

The build runner locates and sources the PetaLinux and Vivado settings itself, so there
is no need to source them by hand. See the [build instructions](build_instructions) for
the full description of the runner.

1. From a command terminal, clone the Git repository (with its submodules) and `cd` into it:
   ```
   git clone --recurse-submodules https://github.com/fpgadeveloper/zynqmp-hailo-ai.git
   cd zynqmp-hailo-ai
   ```
2. Build the PetaLinux image for your target by running the following command and replacing
   `<target>` with one of the target design labels found in the build instructions:
   ```
   ./build.sh petalinux --target <target>
   ```

This will also launch the build process for the corresponding Vivado project if that project
has not already been built and its hardware exported.

The output products are written to `PetaLinux/<target>/images/linux/`: `BOOT.BIN`,
`boot.scr`, `image.ub` (kernel, device tree and initial RAM disk) and `rootfs.tar.gz`
(root filesystem), among others. `./build.sh package --target <target>` (or `all`) also
collects them into `bootimages/zynqmp-hailo-ai_<target>_petalinux-2025-2.zip`.

## Prepare the SD card

Once the build process is complete, you must prepare the SD card for booting PetaLinux.

1. The SD card must first be prepared with two partitions: one for the boot files and another 
   for the root file system.

   * Plug the SD card into your computer and find it's device name using the `dmesg` command.
     The SD card should be found at the end of the log, and it's device name should be something
     like `/dev/sdX`, where `X` is a letter such as a,b,c,d, etc. Note that you should replace
     the `X` in the following instructions.
     
```{warning}
Do not continue these steps until you are certain that you have found the correct
device name for the SD card. If you use the wrong device name in the following steps, you risk
losing data on one of your hard drives.
```
   * Run `fdisk` by typing the command `sudo fdisk /dev/sdX`
   * Make the `boot` partition: typing `n` to create a new partition, then type `p` to make 
     it primary, then use the default partition number and first sector. For the last sector, type 
     `+1G` to allocate 1GB to this partition.
   * Make the `boot` partition bootable by typing `a`
   * Make the `root` partition: typing `n` to create a new partition, then type `p` to make 
     it primary, then use the default partition number, first sector and last sector.
   * Save the partition table by typing `w`
   * Format the `boot` partition (FAT32) by typing `sudo mkfs.vfat -F 32 -n boot /dev/sdX1`
   * Format the `root` partition (ext4) by typing `sudo mkfs.ext4 -L root /dev/sdX2`

2. Copy the following files to the `boot` partition of the SD card:
   Assuming the `boot` partition was mounted to `/media/user/boot`, follow these instructions:
   ```
   $ cd /media/user/boot/
   $ sudo cp /<petalinux-project>/images/linux/BOOT.BIN .
   $ sudo cp /<petalinux-project>/images/linux/boot.scr .
   $ sudo cp /<petalinux-project>/images/linux/image.ub .
   ```

3. Create the root file system by extracting the `rootfs.tar.gz` file to the `root` partition.
   Assuming the `root` partition was mounted to `/media/user/root`, follow these instructions:
   ```
   $ cd /media/user/root/
   $ sudo cp /<petalinux-project>/images/linux/rootfs.tar.gz .
   $ sudo tar xvf rootfs.tar.gz -C .
   $ sudo rm rootfs.tar.gz
   $ sync
   ```
   
   Once the `sync` command returns, you will be able to eject the SD card from the machine.

(petalinux-boot-mode)=
## Boot from SD card

1. Plug the SD card into your target board. The UltraZed-EV carrier boots from the
   SD1 slot on the carrier (the BSP sets `CONFIG_SUBSYSTEM_PRIMARY_SD_PSU_SD_1_SELECT=y`
   and the rootfs is mounted from `/dev/mmcblk1p2`). For the ZCU104, ZCU106, and PYNQ-ZU
   the rootfs lives on `/dev/mmcblk0p2`.
2. Ensure that the target board is configured to boot from SD card (the same settings
   apply to the Yocto images):
   * **ZCU104 / ZCU106:** DIP switch SW6 must be set to 1000 (1=ON,2=OFF,3=OFF,4=OFF)
   * **PYNQ-ZU:** Switch labelled "JTAG SD" must be flipped to the right (towards "SD")
   * **UltraZed-EV:** DIP switch SW2 (on the SoM) is set to 1000 (1=ON,2=OFF,3=OFF,4=OFF)

   The boot-mode switches are described in the user guide of each board, available from
   the board's product page: [ZCU104](https://www.xilinx.com/zcu104),
   [ZCU106](https://www.xilinx.com/zcu106),
   [PYNQ-ZU](https://www.tulembedded.com/FPGA/ProductsPYNQ-ZU.html),
   [UltraZed-EV Carrier](https://www.xilinx.com/products/boards-and-kits/1-1s78dxb.html).
3. Connect the [M.2 M-key Stack FMC] (with the Hailo-8 in M.2 slot 1) and the
   [RPi Camera FMC] to the FMC connector of the target board, and connect one or more
   [Raspberry Pi camera module v2] to the [RPi Camera FMC].
   For the `zcu106` design: connect the [FPGA Drive FMC Gen4] (with the Hailo-8 in slot 1) to
   the HPC1 connector and the [RPi Camera FMC] to the HPC0 connector.
4. Connect a DisplayPort monitor that supports 1920x1080 at 60 Hz.
5. Connect the USB-UART to your PC and then open a UART terminal set to 115200 baud and the 
   comport that corresponds to your target board.
6. Connect and power your hardware.

## Log in

Log into PetaLinux using the username `petalinux`. On the first boot you will be prompted
to set the password for this user before the shell starts. On subsequent boots, use the
chosen password. The scripts and most test commands require `sudo`, which will prompt for
the same password. The hostname is `<board>-hailo-2025-2`, for example
`zcu104-hailo-2025-2`.

The kernel command line of the PetaLinux images is:

```
earlycon console=ttyPS0,115200 clk_ignore_unused root=/dev/mmcblk0p2 rw rootwait cma=1536M xlnx_mixer.connect_drm_bridge=1
```

(`root=/dev/mmcblk1p2` and `cma=1000M` on `uzev`). `cma=` reserves contiguous memory for
the video frame buffers and the Hailo DMA buffers; `xlnx_mixer.connect_drm_bridge=1`
connects the Video Mixer to the DisplayPort controller.

## Run and test

Continue with [Run and test the design](run-and-test): it checks the PCIe link and the
Hailo-8, runs inference with `hailortcli`, configures and captures from the cameras, runs a
camera through the Hailo-8 without a monitor, and starts the `hailodemo.sh` multi-camera
demo on the monitor. The commands are the same for PetaLinux and Yocto.

## Known issues and limitations

### UltraZed EV DisplayPort

The DisplayPort connector on the UltraZed EV carrier has only a single lane connected to it.
Not all monitors can run resolutions above 1080p over a single lane; the 1920x1080 at
60 Hz mode that this design outputs is within the single-lane limit.

### PYNQ-ZU limits

The ZynqMP device on the PYNQ-ZU board is a relatively small device in terms of FPGA resources.
Fitting the necessary logic to handle four video streams simultaneously can be a challenge on this board. 
For this reason, in our Vivado design for this board we have included the video pipes for only two cameras:
CAM1 and CAM2. The PYNQ-ZU has no Ethernet port; the PetaLinux image does not set up its
Wi-Fi module, so use the serial console (or the [Yocto image](yocto), which supports the
on-board Wi-Fi).

### Changes in this release that need a PetaLinux rebuild

The fixes to the ISP driver (camera colour) and to `hailodemo.sh` (display mode), and the
new PCIe address map, are in the sources of this release. If you built the PetaLinux
image from an earlier version of the repository, rebuild it (`./build.sh clean --target
<target>` then `./build.sh petalinux --target <target>`) to pick them up. See the
[revision history](revision_history).

[RPi Camera FMC]: https://docs.opsero.com/op068/datasheet/overview/
[M.2 M-key Stack FMC]: https://docs.opsero.com/op073/datasheet/overview/
[FPGA Drive FMC Gen4]: https://docs.opsero.com/op063/datasheet/overview/
[Raspberry Pi camera module v2]: https://www.raspberrypi.com/products/camera-module-v2/
[supported Linux distributions]: https://docs.amd.com/r/en-US/ug1144-petalinux-tools-reference-guide/Setting-Up-Your-Environment
