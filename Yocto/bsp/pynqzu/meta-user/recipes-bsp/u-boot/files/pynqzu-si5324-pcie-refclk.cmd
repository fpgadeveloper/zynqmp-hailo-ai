# PCIe reference clock (same Si5324 set-up as the PetaLinux BSP's
# platform-top.h "fmc_gt_clk_en").
#
# On PYNQ-ZU the FMC GBTCLK0 (100MHz from the M.2 M-key Stack FMC) does not go
# straight to the GTH: it routes through the Si5324 clock multiplier (CKIN2 in,
# CKOUT1 out to MGT bank 224 CLK0), which comes up with no input selected.
# Without these writes the XDMA has no reference clock and Linux stalls at the
# XDMA PCIe probe, so this step is required for the board to boot.
#
# The Si5324 is set to pass the FMC clock straight through (bypass mode): the
# DSPLL is not used, so no frequency plan or calibration is needed.
# U-Boot "i2c mw" takes the register address in HEX:
#   reg 0x15 = 0xFE  CKSEL_PIN=0: input selected by register (CKSEL_REG), not
#                    by the CS_CA pin; other bits at their defaults
#   reg 0x03 = 0x45  CKSEL_REG=01: select CKIN2 (FMC 100MHz); SQ_ICAL=0, so the
#                    outputs are not squelched waiting for a calibration
#   reg 0x00 = 0x16  BYPASS_REG=1: pass the selected input to the outputs
#                    without the DSPLL (written last, after the input select)
#
# "i2c dev 0": the EDF u-boot numbers I2C buses by the SDT /aliases, and the
# SDT aliases the Si5324's bus, hdmi_axi_iic (80030000), as i2c0 (PetaLinux
# numbers it 1). Re-check the aliases if the design's I2C controllers change.
# The AXI IIC needs the u-boot XIIC driver (u-boot-xlnx bbappend in this layer).
#
# After the Si5324 is configured, pl_resetn0 (EMIO GPIO 95, bank 5 bit 31) is
# driven low for 0.2 s to reset the XDMA IP: DIRM 0xFF0A0344, OEN 0xFF0A0348,
# DATA 0xFF0A0054.
echo "Programming Si5324 (PCIe reference clock)"
i2c dev 0
i2c mw 0x68 0x15.1 0xfe 0x1
i2c mw 0x68 0x03.1 0x45 0x1
i2c mw 0x68 0x00.1 0x16 0x1
mw 0xFF0A0054 0x80000000
mw 0xFF0A0344 0x80000000
mw 0xFF0A0348 0x80000000
mw 0xFF0A0054 0x00
sleep 0.2
mw 0xFF0A0054 0x80000000
sleep 0.2

