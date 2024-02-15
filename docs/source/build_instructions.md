# Build instructions

## Source code

The source code for the reference designs is managed on this Github repository:

* [https://github.com/fpgadeveloper/zynqmp-hailo-ai](https://github.com/fpgadeveloper/zynqmp-hailo-ai)

Note that the repository contains submodules, so it is essential to use the `--recursive` option when cloning:
```
git clone --recursive https://github.com/fpgadeveloper/zynqmp-hailo-ai.git
```

## License requirements

The designs for all of the [target boards](supported_carriers) can be built with the Vivado ML Standard 
Edition **without a license**.

(target-designs)=
## Target designs

This repo contains several designs that target the various supported development boards and their
FMC connectors. The table below lists the target design name, the camera ports supported by the design and 
the FMC connector on which to connect the RPi Camera FMC.

Note that there are two target designs for the [ZCU106][5] board: `zcu106` and `zcu106_hpc0`, and the
differences are explained in the table below.
All target designs except `zcu106` require the [M.2 M-key Stack FMC][2] as the M.2 adapter for the Hailo-8, with the
[RPi Camera FMC][3] stacked on top of it.

| Target board             | Target design | FMC slots used | Cameras | M.2 adapter for Hailo | M.2 active slots |
|--------------------------|---------------|----------|---------|-------------|------------------|
| [ZCU104][4]              | `zcu104`      | LPC       | 4 | [M.2 M-key Stack FMC][2] | 1 |
| [ZCU106][5]              | `zcu106`      | HPC0+HPC1 (note 1) | 4 | [FPGA Drive FMC Gen4][1] | 1 |
| [ZCU106][5]              | `zcu106_hpc0` | HPC0      | 4 | [M.2 M-key Stack FMC][2] | 2 (note 3) |
| [PYNQ-ZU][6]             | `pynqzu`      | LPC       | 2 (note 2) | [M.2 M-key Stack FMC][2] | 1 |
| [Genesys-ZU][7]          | `genesyszu`   | LPC       | 2 (note 2) | [M.2 M-key Stack FMC][2] | 1 |
| [UltraZed EV carrier][8] | `uzev`        | HPC       | 4 | [M.2 M-key Stack FMC][2] | 2 (note 3) |

#### Notes:
1. The `zcu106` target design uses the [FPGA Drive FMC Gen4][1] as the M.2 adapter for the Hailo-8.
   In that design, the [FPGA Drive FMC Gen4][1] connects to HPC1 while the [RPi Camera FMC][3] connects
   to the HPC0 connector.
2. The `pynqzu` and `genesyszu` target designs have video pipelines for only 2 cameras (CAM1 and CAM2 as
   labelled on the RPi Camera FMC). This is due to the resource limitations of the devices on these boards.
3. The `zcu106_hpc0` and `uzev` target designs have support for 2x M.2 modules. To use the Hailo demo scripts,
   at least one of these modules must be the [Hailo-8 M.2 AI Acceleration Module]. The second slot can be used
   for a second Hailo module, or an NVMe SSD for storage.

## Linux only

These projects can be built using a machine (either physical or virtual) with one of the 
[supported Linux distributions].

```{tip} The build steps can be completed in the order shown below, or
you can go directly to the [build PetaLinux](#build-petalinux-project) instructions below
to build the Vivado and PetaLinux projects with a single command.
```

### Build Vivado project

1. Open a command terminal and launch the setup script for Vivado:
   ```
   source <path-to-vivado-install>/2022.1/settings64.sh
   ```
2. Clone the Git repository and `cd` into the `Vivado` folder of the repo:
   ```
   git clone --recursive https://github.com/fpgadeveloper/zynqmp-hailo-ai.git
   cd zynqmp-hailo-ai/Vivado
   ```
3. Run make to create the Vivado project for the target board. You must replace `<target>` with a valid
   target (alternatively, skip to step 5):
   ```
   make project TARGET=<target>
   ```
   Valid targets are: `zcu104`, `zcu106`, `zcu106_hpc0`, `pynqzu`, `genesyszu` and `uzev`.
   That will create the Vivado project and block design without generating a bitstream or exporting to XSA.
4. Open the generated project in the Vivado GUI and click **Generate Bitstream**. Once the build is
   complete, select **File->Export->Export Hardware** and be sure to tick **Include bitstream** and use
   the default name and location for the XSA file.
5. Alternatively, you can create the Vivado project, generate the bitstream and export to XSA (steps 3 and 4),
   all from a single command:
   ```
   make xsa TARGET=<target>
   ```
   
(build-petalinux-project)=
### Build PetaLinux project

These steps will build the PetaLinux project for the target design. You are not required to have built the
Vivado design before following these steps, as the Makefile triggers the Vivado build for the corresponding
design if it has not already been done.

1. Launch the setup script for Vivado (only if you skipped the Vivado build steps above):
   ```
   source <path-to-vivado-install>/2022.1/settings64.sh
   ```
2. Launch PetaLinux by sourcing the `settings.sh` bash script, eg:
   ```
   source <path-to-petalinux-install>/2022.1/settings.sh
   ```
3. Build the PetaLinux project for your specific target platform by running the following
   command, replacing `<target>` with a valid value from below:
   ```
   cd PetaLinux
   make petalinux TARGET=<target>
   ```
   Valid targets are: 
   `zcu104`, 
   `zcu106`, 
   `zcu106_hpc0`, 
   `pynqzu`, 
   `uzev`.
   Note that if you skipped the Vivado build steps above, the Makefile will first generate and
   build the Vivado project, and then build the PetaLinux project.

### PetaLinux offline build

If you need to build the PetaLinux projects offline (without an internet connection), you can
follow these instructions.

1. Download the sstate-cache artefacts from the Xilinx downloads site (the same page where you downloaded
   PetaLinux tools). There are four of them:
   * aarch64 sstate-cache (for ZynqMP designs)
   * arm sstate-cache (for Zynq designs)
   * microblaze sstate-cache (for Microblaze designs)
   * Downloads (for all designs)
2. Extract the contents of those files to a single location on your hard drive, for this example
   we'll say `/home/user/petalinux-sstate`. That should leave you with the following directory 
   structure:
   ```
   /home/user/petalinux-sstate
                             +---  aarch64
                             +---  arm
                             +---  downloads
                             +---  microblaze
   ```
3. Create a text file called `offline.txt` that contains a single line of text. The single line of text
   should be the path where you extracted the sstate-cache files. In this example, the contents of 
   the file would be:
   ```
   /home/user/petalinux-sstate
   ```
   It is important that the file contain only one line and that the path is written with NO TRAILING 
   FORWARD SLASH.

Now when you use `make` to build the PetaLinux projects, they will be configured for offline build.

[supported Linux distributions]: https://docs.xilinx.com/r/2022.1-English/ug1144-petalinux-tools-reference-guide/Setting-Up-Your-Environment
[FPGA Drive FMC Gen4]: https://fpgadrive.com
[1]: https://www.fpgadrive.com/docs/fpga-drive-fmc-gen4/overview/
[2]: https://www.fpgadrive.com/docs/m2-mkey-stack-fmc/overview/
[3]: https://camerafmc.com/docs/rpi-camera-fmc/overview/
[4]: https://www.xilinx.com/zcu104
[5]: https://www.xilinx.com/zcu106
[6]: https://www.tulembedded.com/FPGA/ProductsPYNQ-ZU.html
[7]: https://digilent.com/shop/genesys-zu-zynq-ultrascale-mpsoc-development-board/
[8]: https://www.xilinx.com/products/boards-and-kits/1-y3n9v1.html


