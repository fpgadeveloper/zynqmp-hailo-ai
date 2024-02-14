# Updating the projects

This section contains instructions for updating the reference designs. It is intended as a guide
for anyone wanting to attempt updating the designs for a tools release that we do not yet support.
Note that the update process is not always straight-forward and sometimes requires dealing with
new issues or significant changes to the functionality of the tools and/or specific IP. Unfortunately, 
we cannot always provide support if you have trouble updating the designs.

## Vivado projects

1. Download and install the Vivado release that you intend to use.
2. In a text editor, open the `Vivado/scripts/build.tcl` file and perform the following changes:
   * Update the `version_required` variable value to the tools version number 
     that you are using.
   * Update the year in all references to `Vivado Synthesis <year>` to the 
     tools version number that you are using. For example, if you are using tools
     version 2022.1, then the `<year>` should be 2022.
   * Update the year in all references to `Vivado Implementation <year>` to the 
     tools version number that you are using. For example, if you are using tools
     version 2022.1, then the `<year>` should be 2022.
3. In a text editor, open the `Vivado/scripts/xsa.tcl` file and perform the following changes:
   * Update the `version_required` variable value to the tools version number 
     that you are using.
4. **Windows users only:** In a text editor, open the `Vivado/build-vivado.bat` file and update 
   the tools version number to the one you are using (eg. 2022.1).

After completing the above, you should now be able to use the [build instructions](build_instructions) to
build the Vivado project. If there were no significant changes to the tools and/or IP, the build script 
should succeed and you will be able to open and generate a bitstream.

## PetaLinux

The main procedure for updating the PetaLinux project is to update the BSP for the target platform.
The BSP files for each supported target platform are contained in the `PetaLinux/bsp` directory.

1. Download and install the PetaLinux release that you intend to use.
2. Download and install the BSP for the target platform for the release that you intend to use.
   * For ZCU104 and ZCU106 download the BSP from the 
     [Xilinx downloads] page
   * For UltraZed-EV download the BSP from the [Avnet downloads] page
   * For PYNQ-ZU, there is a PetaLinux BSP maintainted in the [PYNQ-ZU Git repo](https://github.com/Xilinx/PYNQ-ZU)
3. Update the BSP files for the target platform in the `PetaLinux/bsp/<platform>` directory. 
   These are the specific directories to update:
   * `<platform>/project-spec/configs/*`
   * `<platform>/project-spec/meta-user/*`   
   The simple way to update the files is to delete the `configs` and `meta-user` folders from the repository
   and copy in those folders from the more recent BSP.
4. Apply the required modifications to the updated BSP files. The modifications are described for each
   target platform in the following sections.

### Add configs

This BSP modification applies to all target platforms.

1. Append the following lines to `project-spec/configs/config`:

```
# RPi Camera FMC customizations

CONFIG_SUBSYSTEM_BOOTARGS_AUTO=n
CONFIG_SUBSYSTEM_USER_CMDLINE="earlycon console=ttyPS0,115200 clk_ignore_unused root=/dev/mmcblk0p2 rw rootwait cma=1536M"

CONFIG_SUBSYSTEM_ROOTFS_INITRD=n
CONFIG_SUBSYSTEM_ROOTFS_EXT4=y
CONFIG_SUBSYSTEM_SDROOT_DEV="/dev/mmcblk0p2"
CONFIG_SUBSYSTEM_RFS_FORMATS="tar.gz ext4 ext4.gz "

CONFIG_SUBSYSTEM_HOSTNAME="zynqmp-hailo-ai"
CONFIG_SUBSYSTEM_PRODUCT="zynqmp-hailo-ai"
```

2. Replace the last line in `project-spec/meta-user/conf/petalinuxbsp.conf` with this one:

```
IMAGE_BOOT_FILES:zynqmp = "BOOT.BIN boot.scr Image system.dtb"
```

The purpose of these configurations is to specify that the root filesystem should be on the SD
card, and to set the project name. Note that this will set the project name to "zynqmp-hailo-ai" but you can 
use a more descriptive name, for example one that includes the target platform name and the tools version.

### Add tools to root filesystem

This BSP modification applies to all target platforms.

1. Append the following lines to `project-spec/configs/rootfs_config`:

```
# RPi Camera FMC customizations

CONFIG_dnf=y
CONFIG_e2fsprogs-resize2fs=y
CONFIG_openssh-sftp-server=y
CONFIG_wget=y
CONFIG_parted=y
CONFIG_gawk=y
CONFIG_git=y
CONFIG_unzip=y
CONFIG_vim=y
CONFIG_zip=y
CONFIG_tcl=y
CONFIG_libmali-xlnx=y
CONFIG_mali-backend-x11=y
CONFIG_xrt-dev=y
CONFIG_zocl=y
CONFIG_opencl-clhpp-dev=y
CONFIG_opencl-headers=y
CONFIG_protobuf=y
CONFIG_libstdcPLUSPLUS=y
CONFIG_gdb=y
CONFIG_gstreamer1.0-plugins-bad=y
CONFIG_gstreamer1.0-plugins-base=y
CONFIG_gstreamer1.0-plugins-base-apps=y
CONFIG_gstreamer1.0-plugins-good=y
CONFIG_net-tools=y
CONFIG_packagegroup-core-buildessential=y
CONFIG_python3=y
CONFIG_v4l-utils=y
CONFIG_libv4l=y
CONFIG_media-ctl=y
CONFIG_valgrind=y
CONFIG_gstreamer1.0=y
CONFIG_gstreamer1.0-omx=y
CONFIG_resize-part=y
CONFIG_packagegroup-petalinux-multimedia=y
CONFIG_packagegroup-petalinux-opencv=y
CONFIG_packagegroup-petalinux-opencv-dev=y
CONFIG_packagegroup-petalinux-self-hosted=y
CONFIG_packagegroup-petalinux-v4lutils=y
CONFIG_cmake=y
CONFIG_opencv-staticdev=y
CONFIG_initcams=y

CONFIG_ADD_USERS_TO_GROUPS="petalinux:audio,video,disk,kmem;"
```

2. Append the following lines to `project-spec/meta-user/conf/user-rootfsconfig`:

```
# RPi Camera FMC additions

CONFIG_packagegroup-petalinux-gstreamer
CONFIG_packagegroup-petalinux-multimedia
CONFIG_packagegroup-petalinux-opencv
CONFIG_packagegroup-petalinux-x11
CONFIG_packagegroup-petalinux-v4lutils
CONFIG_cmake
CONFIG_opencv-staticdev
CONFIG_initcams
```

```{note}
Note that for the PYNQ-ZU BSP, you may have to create this file.
```

### Add support for the cameras and NFS

This BSP modification applies to all target platforms.

1. Append the following lines to file `project-spec/meta-user/recipes-kernel/linux/linux-xlnx/bsp.cfg`:

```
CONFIG_VIDEO_IMX219=y
CONFIG_VIDEO_OV5640=y
CONFIG_NFSD=y
```

2. Append the following lines to device tree file
   `project-spec/meta-user/recipes-bsp/device-tree/files/system-user.dtsi`:

```
&amba_pl {
	imx219_clk: imx219_clk {
		#clock-cells = <0x0>;
		clock-frequency = <24000000>;
		compatible = "fixed-clock";
	};


	imx219_vana: fixedregulator@3 {
		compatible = "regulator-fixed";
		regulator-name = "imx219_vana";
		regulator-min-microvolt = <2800000>;
		regulator-max-microvolt = <2800000>;
		enable-active-high;
	};

	imx219_vdig: fixedregulator@4 {
		compatible = "regulator-fixed";
		regulator-name = "imx219_vdig";
		regulator-min-microvolt = <1800000>;
		regulator-max-microvolt = <1800000>;
	};

	imx219_vddl: fixedregulator@5 {
		compatible = "regulator-fixed";
		regulator-name = "imx219_vddl";
		regulator-min-microvolt = <1200000>;
		regulator-max-microvolt = <1200000>;
	};
	
};

&mipi_0_axi_iic_0 {
	imx219_cam0: sensor@10 {
		compatible = "sony,imx219";
		reg = <0x10>;
		clocks = <&imx219_clk>;
		VANA-supply = <&imx219_vana>;   /* 2.8v */
		VDIG-supply = <&imx219_vdig>;   /* 1.8v */
		VDDL-supply = <&imx219_vddl>;   /* 1.2v */

		port {
		     imx219_cam0_0: endpoint {
			remote-endpoint = <&mipi_csi_inmipi_0_mipi_csi2_rx_subsyst_0>;
			data-lanes = <1 2>;
			link-frequencies = /bits/ 64 <456000000>;
			};
		};
	};
};

&mipi_1_axi_iic_0 {
	imx219_cam1: sensor@10 {
		compatible = "sony,imx219";
		reg = <0x10>;
		clocks = <&imx219_clk>;
		VANA-supply = <&imx219_vana>;   /* 2.8v */
		VDIG-supply = <&imx219_vdig>;   /* 1.8v */
		VDDL-supply = <&imx219_vddl>;   /* 1.2v */

		port {
		     imx219_cam1_0: endpoint {
			remote-endpoint = <&mipi_csi_inmipi_1_mipi_csi2_rx_subsyst_0>;
			data-lanes = <1 2>;
			link-frequencies = /bits/ 64 <456000000>;
			};
		};
	};
};

&mipi_2_axi_iic_0 {
	imx219_cam2: sensor@10 {
		compatible = "sony,imx219";
		reg = <0x10>;
		clocks = <&imx219_clk>;
		VANA-supply = <&imx219_vana>;   /* 2.8v */
		VDIG-supply = <&imx219_vdig>;   /* 1.8v */
		VDDL-supply = <&imx219_vddl>;   /* 1.2v */

		port {
		     imx219_cam2_0: endpoint {
			remote-endpoint = <&mipi_csi_inmipi_2_mipi_csi2_rx_subsyst_0>;
			data-lanes = <1 2>;
			link-frequencies = /bits/ 64 <456000000>;
			};
		};
	};
};

&mipi_3_axi_iic_0 {
	imx219_cam3: sensor@10 {
		compatible = "sony,imx219";
		reg = <0x10>;
		clocks = <&imx219_clk>;
		VANA-supply = <&imx219_vana>;   /* 2.8v */
		VDIG-supply = <&imx219_vdig>;   /* 1.8v */
		VDDL-supply = <&imx219_vddl>;   /* 1.2v */

		port {
		     imx219_cam3_0: endpoint {
			remote-endpoint = <&mipi_csi_inmipi_3_mipi_csi2_rx_subsyst_0>;
			data-lanes = <1 2>;
			link-frequencies = /bits/ 64 <456000000>;
			};
		};
	};
};

&mipi_0_mipi_csi2_rx_subsyst_0 {
	xlnx,en-active-lanes;
};

&mipi_1_mipi_csi2_rx_subsyst_0 {
	xlnx,en-active-lanes;
};

&mipi_2_mipi_csi2_rx_subsyst_0 {
	xlnx,en-active-lanes;
};

&mipi_3_mipi_csi2_rx_subsyst_0 {
	xlnx,en-active-lanes;
};

&mipi_csi_inmipi_0_mipi_csi2_rx_subsyst_0 {
	remote-endpoint = <&imx219_cam0_0>;
};

&mipi_csi_inmipi_1_mipi_csi2_rx_subsyst_0 {
	remote-endpoint = <&imx219_cam1_0>;
};

&mipi_csi_inmipi_2_mipi_csi2_rx_subsyst_0 {
	remote-endpoint = <&imx219_cam2_0>;
};

&mipi_csi_inmipi_3_mipi_csi2_rx_subsyst_0 {
	remote-endpoint = <&imx219_cam3_0>;
};

&xx_mix_masterv_mix {
	v_mixv_tpg: endpoint {
		remote-endpoint = <&tpg_outv_tpg>;
	};
};

&v_axi4s_remap {
	remap_ports: ports {
		#address-cells = <1>;
		#size-cells = <0>;
		remap_port0: port@0 {
			reg = <0>;
			v_axi4s_remapv_mix: endpoint {
				remote-endpoint = <&mixer_crtcv_mix>;
			};
		};
	};
};

&mipi_0_v_proc {
	compatible = "xlnx,v-vpss-scaler-2.2";
};

&mipi_1_v_proc {
	compatible = "xlnx,v-vpss-scaler-2.2";
};

&mipi_2_v_proc {
	compatible = "xlnx,v-vpss-scaler-2.2";
};

&mipi_3_v_proc {
	compatible = "xlnx,v-vpss-scaler-2.2";
};
```

### Add the initcams script

The initcams script must be added to the BSPs for all targets. This can be done by copying the following files
into the BSP:

```
project-spec
           +--- meta-user
                        +--- recipes-apps
                                        +--- initcams
                                                    +--- files
                                                    |        +--- init_cams
                                                    +--- .gbdinit
                                                    +--- initcams.bb
```

```{note}
These files can be copied over from one of the BSPs in the repository, but the directory structure and/or the
`initcams.bb` file may need updating to work with newer versions of PetaLinux.
```

### Mods for ZCU104

These modifications are specific to the ZCU104 BSP.

1. Add patch for FSBL to `project-spec/meta-user/recipes-bsp/embeddedsw/`. You will have to update this
   patch for the version of PetaLinux that you are using. Refer to the existing patch files in that
   location for guidance.
   
```
project-spec
           +--- meta-user
                        +--- recipes-bsp
                                       +--- embeddedsw
                                                     +--- files
                                                     |        +--- zcu104_vadj_fsbl.patch
                                                     +--- fsbl-firmware_%.bbappend
```

### Mods for ZCU106

These modifications are specific to the ZCU106 BSP.

1. Append the following lines to `project-spec/configs/config`. The first option prevents the removal of
   the PL DTB nodes that we need in this design. The second option disables the FPGA manager.

```
# ZCU106 configs

CONFIG_SUBSYSTEM_REMOVE_PL_DTB=n
CONFIG_SUBSYSTEM_FPGA_MANAGER=n
```

### Mods for UltraZed EV

These modifications are specific to the UltraZed-EV BSP.

```{note}
When copying the UltraZed-EV BSP, you can ignore the `meta-avnet` folder because we do not use it in this
design.
```

1. Append the following lines to `project-spec/configs/config`:

```
# UltraZed-EV configs

CONFIG_YOCTO_MACHINE_NAME="zynqmp-generic"
CONFIG_USER_LAYER_0=""
CONFIG_SUBSYSTEM_SDROOT_DEV="/dev/mmcblk1p2"
CONFIG_SUBSYSTEM_USER_CMDLINE=" earlycon console=ttyPS0,115200 clk_ignore_unused root=/dev/mmcblk1p2 rw rootwait cma=1000M"
CONFIG_SUBSYSTEM_PRIMARY_SD_PSU_SD_0_SELECT=n
CONFIG_SUBSYSTEM_PRIMARY_SD_PSU_SD_1_SELECT=y
CONFIG_SUBSYSTEM_SD_PSU_SD_0_SELECT=n
```

2. Overwrite the device tree file 
   `project-spec/meta-user/recipes-bsp/device-tree/files/system-user.dtsi` with the one that is in the
   repository.

### Mods for the M.2 adapter support

These modifications are required to add support for PCIe and the M.2 adapter.

1. Append the following lines to `project-spec/configs/rootfs_config`:

```
# Tools for PCIe and NVMe

CONFIG_e2fsprogs=y
CONFIG_e2fsprogs-mke2fs=y
CONFIG_e2fsprogs-badblocks=y
CONFIG_mtd-utils=y
CONFIG_util-linux=y
CONFIG_util-linux-mount=y
CONFIG_util-linux-mkfs=y
CONFIG_util-linux-blkid=y
CONFIG_util-linux-fdisk=y
CONFIG_pciutils=y
CONFIG_bridge-utils=y

# Add coreutils for full version of dd, and nvme-cli for NVMe tools

CONFIG_coreutils=y
CONFIG_nvme-cli=y
```

2. Append the following lines to `project-spec/meta-user/conf/user-rootfsconfig`:

```
# PCIe and NVMe additions

CONFIG_e2fsprogs
CONFIG_e2fsprogs-mke2fs
CONFIG_e2fsprogs-badblocks
CONFIG_mtd-utils
CONFIG_util-linux
CONFIG_util-linux-mount
CONFIG_util-linux-mkfs
CONFIG_util-linux-blkid
CONFIG_util-linux-fdisk
CONFIG_pciutils
CONFIG_bridge-utils
CONFIG_nvme-cli
```

3. Append the following lines to file `project-spec/meta-user/recipes-kernel/linux/linux-xlnx/bsp.cfg`:

```
# PCIe and NVMe configs

CONFIG_PCI_REALLOC_ENABLE_AUTO=y
CONFIG_PCIE_XDMA_PL=y
CONFIG_NVME_CORE=y
CONFIG_BLK_DEV_NVME=y
CONFIG_NVME_TARGET=y
```

[Xilinx downloads]: https://www.xilinx.com/support/download/index.html/content/xilinx/en/downloadNav/embedded-design-tools.html
[Avnet downloads]: https://avnet.me/zedsupport
[FPGA Drive FMC Gen4]: https://www.fpgadrive.com/docs/fpga-drive-fmc-gen4/overview/

