# Supported carrier boards

## List of supported boards

{% set unique_boards = {} %}
{% for design in data.designs %}
    {% if design.publish %}
        {% if design.board not in unique_boards %}
            {% set _ = unique_boards.update({design.board: {"group": design.group, "link": design.link, "connectors": []}}) %}
        {% endif %}
        {% set _ = unique_boards[design.board]["connectors"].append(design.connector) %}
    {% endif %}
{% endfor %}

{% for group in data.groups %}
    {% set designs_in_group = [] %}
    {% for design in data.designs %}
        {% if design.group == group.label and design.publish %}
            {% set _ = designs_in_group.append(design.label) %}
        {% endif %}
    {% endfor %}
    {% if designs_in_group | length > 0 %}
### {{ group.name }} boards

| Carrier board       | Supported FMC connector(s)    |
|---------------------|--------------|
{% for name,board in unique_boards.items() %}{% if board.group == group.label %}| [{{ name }}]({{ board.link }}) | {% for connector in board.connectors %}{{ connector }} {% endfor %} |
{% endif %}{% endfor %}
{% endif %}
{% endfor %}

For list of the target designs showing the number of cameras supported, refer to the build instructions.

## Unlisted boards

If you need more information on whether the [RPi Camera FMC] is compatible with a carrier that is not 
listed above, please first check the [compatibility list]. If the carrier is not listed there, please 
[contact Opsero], provide us with the pinout of your carrier and we'll be happy to check compatibility 
and generate a Vivado constraints file for you.

## Board specific notes

### UltraZed EV carrier DisplayPort limitation

The UltraZed EV carrier has a DisplayPort connector with only a single lane connected. Not all
DisplayPort monitors can operate at resolutions above 1080p on a single lane; the 1920x1080 at
60 Hz mode that this design outputs is within that limit.

### ZCU106 HPC1

The HPC1 connector of the ZCU106 carries a single GT lane. In the `zcu106` target design the
[FPGA Drive FMC Gen4] on HPC1 therefore has a Gen3 x1 link to its M.2 slot 1 (the Hailo-8),
and its M.2 slot 2 is not connected. For two M.2 slots with four lanes each, use the
`zcu106_hpc0` target design (M.2 M-key Stack FMC with the RPi Camera FMC on HPC0).

### PYNQ-ZU and UltraZed EV carrier

Note that the PYNQ-ZU and UltraZed EV carrier boards have a fixed VADJ voltage that is set to 1.8VDC. The 
[AMD Xilinx MIPI CSI Controller Subsystem IP] documentation recommends an I/O voltage of 1.2VDC, and the 
Vivado tools prevent using the IP with IO standards that are not compatible with 1.2VDC. For this reason,
all of the designs in this repository use 1.2VDC compatible IO standards, even though the I/O banks on the 
PYNQ-ZU and UltraZed EV carrier boards are powered at 1.8VDC. At the moment this is the only practical and
functional workaround that we have found for these two target boards.

(pynqzu-notes)=
### PYNQ-ZU

The FMC GT reference clock connects to the GTH bank 224 MGTREFCLK0P/N via a jitter attenuator device [Si5324] 
on the PYNQ-ZU board. For correct operation of this reference design, the [Si5324] must be configured to route 
the 100MHz FMC GT reference clock through to the GT.

To configure the [Si5324] device via I2C bus, the Vivado design contains an AXI IIC IP (hdmi_axi_iic).
At every boot, U-Boot configures the [Si5324] and then resets the XDMA IP by toggling the pl_resetn0 pin
(Bank 5, bit 31, EMIO 95). The [Si5324] is put in bypass mode: the 100MHz clock from the FMC (CKIN2) is
passed straight through to the output that feeds the GT (CKOUT1), without using its PLL. Three register
writes do this: register 0x15 = 0xFE (input selected by register rather than by pin), register 0x03 = 0x45
(select CKIN2) and, last, register 0x00 = 0x16 (enable bypass). Both Linux flows carry these commands:

* PetaLinux: the U-Boot environment variable `fmc_gt_clk_en`, run by the boot command, in
  `PetaLinux/bsp/pynqzu/project-spec/meta-user/recipes-bsp/u-boot/files/platform-top.h`.
* Yocto: the start of the U-Boot boot script (`boot.scr`), from
  `Yocto/bsp/pynqzu/meta-user/recipes-bsp/u-boot/files/pynqzu-si5324-pcie-refclk.cmd`.

If the [Si5324] is not configured, the PCIe block has no reference clock and Linux stops responding
while it probes the XDMA PCIe host.

The PYNQ-ZU has no Ethernet port. The Yocto image supports its on-board WILC3000 Wi-Fi
module as a Wi-Fi station (see [PYNQ-ZU Wi-Fi](pynq-zu-wi-fi)).

[contact Opsero]: https://opsero.com/contact-us
[RPi Camera FMC]: https://docs.opsero.com/op068/datasheet/overview/
[compatibility list]: https://camerafmc.com/docs/rpi-camera-fmc/compatibility/
[AMD Xilinx MIPI CSI Controller Subsystem IP]: https://docs.xilinx.com/r/en-US/pg202-mipi-dphy
[Si5324]: https://www.skyworksinc.com/-/media/Skyworks/SL/documents/public/data-sheets/Si5324.pdf
[FPGA Drive FMC Gen4]: https://docs.opsero.com/op063/datasheet/overview/
