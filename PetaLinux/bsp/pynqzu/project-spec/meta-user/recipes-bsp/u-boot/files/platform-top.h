#if defined(CONFIG_MICROBLAZE)
#include <configs/microblaze-generic.h>
#define CONFIG_SYS_BOOTM_LEN 0xF000000
#endif
#if defined(CONFIG_ARCH_ZYNQ)
#include <configs/zynq-common.h>
#endif
#if defined(CONFIG_ARCH_ZYNQMP)
#include <configs/xilinx_zynqmp.h>

/*
 * Opsero Inc. 2024 Jeff Johnson
 * 
 * The following adds a U-boot environment variable containing the commands that 
 * configure the Si5324 device on PYNQ-ZU board to pass the 100MHz clock from
 * the FMC (CKIN2) straight through to the CKOUT1 output, which drives the GTH
 * reference clock of the XDMA PCIe IP. The DSPLL is not used (bypass mode), so
 * no frequency plan or calibration is needed. After the device is configured,
 * the pl_resetn0 pin is toggled low to reset the XDMA IP.
 *
 * Without this, the XDMA has no reference clock and Linux stalls at the XDMA
 * PCIe probe, so this step is required for the board to boot.
 *
 * "i2c dev 1": the Si5324 (I2C address 0x68) is on the AXI IIC hdmi_axi_iic
 * (0x80030000), aliased i2c1 in the PetaLinux device tree.
 * U-Boot "i2c mw" takes the register address in HEX:
 *   reg 0x15 = 0xFE  CKSEL_PIN=0: input selected by register (CKSEL_REG), not
 *                    by the CS_CA pin; other bits at their defaults
 *   reg 0x03 = 0x45  CKSEL_REG=01: select CKIN2 (FMC 100MHz); SQ_ICAL=0, so the
 *                    outputs are not squelched waiting for a calibration
 *   reg 0x00 = 0x16  BYPASS_REG=1: pass the selected input to the outputs
 *                    without the DSPLL (written last, after the input select)
 * pl_resetn0 = EMIO GPIO 95 (bank 5 bit 31): DATA 0xFF0A0054, DIRM 0xFF0A0344,
 * OEN 0xFF0A0348; driven low for 0.2 s.
 *
 */

#define SI5324_SETTINGS \
	"fmc_gt_clk_en=" \
		"i2c dev 1;" \
		"i2c mw 0x68 0x15.1 0xfe 0x1;" \
		"i2c mw 0x68 0x03.1 0x45 0x1;" \
		"i2c mw 0x68 0x00.1 0x16 0x1;" \
		"mw 0xFF0A0054 0x80000000;" \
		"mw 0xFF0A0344 0x80000000;" \
		"mw 0xFF0A0348 0x80000000;" \
		"mw 0xFF0A0054 0x00;" \
		"sleep 0.2;" \
		"mw 0xFF0A0054 0x80000000;" \
		"sleep 0.2\0" \
	
#define CFG_EXTRA_ENV_SETTINGS \
	ENV_MEM_LAYOUT_SETTINGS \
	SI5324_SETTINGS \
	BOOTENV

#define CONFIG_BOOTCOMMAND "run fmc_gt_clk_en; run distro_bootcmd"

#endif
#if defined(CONFIG_ARCH_VERSAL)
#include <configs/xilinx_versal.h>
#endif
#if defined(CONFIG_ARCH_VERSAL_NET)
#include <configs/xilinx_versal_net.h>
#endif
