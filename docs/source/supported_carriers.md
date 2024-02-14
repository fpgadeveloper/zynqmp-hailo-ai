# Supported carrier boards

## List of supported boards

| Carrier board                                              | FMC connector               |
|------------------------------------------------------------|-----------------------------|
| AMD Xilinx [ZCU104] Zynq UltraScale+ Evaluation board      | LPC                         |
| AMD Xilinx [ZCU106] Zynq UltraScale+ Evaluation board      | HPC0                        |
| TUL [PYNQ-ZU] Zynq UltraScale+ Development board           | LPC                         |
| Digilent [Genesys-ZU] Zynq UltraScale+ Development board   | LPC                         |
| Avnet [UltraZed EV Carrier Card] Zynq UltraScale+          | HPC                         |
 
## Unlisted boards

If you need more information on whether the [RPi Camera FMC] is compatible with a carrier that is not 
listed above, please first check the [compatibility list]. If the carrier is not listed there, please 
[contact Opsero], provide us with the pinout of your carrier and we'll be happy to check compatibility 
and generate a Vivado constraints file for you.

## Board specific notes

### PYNQ-ZU and UltraZed EV carrier

Note that the PYNQ-ZU and UltraZed EV carrier boards have a fixed VADJ voltage that is set to 1.8VDC. The 
[AMD Xilinx MIPI CSI Controller Subsystem IP] documentation recommends an I/O voltage of 1.2VDC, and the 
Vivado tools prevent using the IP with IO standards that are not compatible with 1.2VDC. For this reason,
all of the designs in this repository use 1.2VDC compatible IO standards, even though the I/O banks on the 
PYNQ-ZU and UltraZed EV carrier boards are powered at 1.8VDC. At the moment this is the only practical and
functional workaround that we have found for these two target boards.



[contact Opsero]: https://opsero.com/contact-us
[UltraZed EV Carrier Card]: https://www.xilinx.com/products/boards-and-kits/1-y3n9v1.html
[ZCU104]: https://www.xilinx.com/zcu104
[ZCU106]: https://www.xilinx.com/zcu106
[Genesys-ZU]: https://digilent.com/shop/genesys-zu-zynq-ultrascale-mpsoc-development-board/
[PYNQ-ZU]: https://www.tulembedded.com/FPGA/ProductsPYNQ-ZU.html
[RPi Camera FMC]: https://camerafmc.com/docs/rpi-camera-fmc/overview/
[compatibility list]: https://camerafmc.com/docs/rpi-camera-fmc/compatibility/
[AMD Xilinx MIPI CSI Controller Subsystem IP]: https://docs.xilinx.com/r/en-US/pg202-mipi-dphy

