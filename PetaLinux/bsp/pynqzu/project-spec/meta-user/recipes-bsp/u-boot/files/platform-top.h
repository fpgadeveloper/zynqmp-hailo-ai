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
 * configure the Si5324 device on PYNQ-ZU board to output the 100MHz clock from
 * the FMC into the Clk2 input and out of the Clk1 output. After the device is
 * configured, the pl_resetn0 pin is toggled low to reset the XDMA IP.
 *
 */

#define SI5324_SETTINGS \
	"fmc_gt_clk_en=" \
		"i2c dev 1;" \
		"i2c mw 0x68 000.1 0x16 0x1;" \
		"i2c mw 0x68 001.1 0xE4 0x1;" \
		"i2c mw 0x68 002.1 0xA2 0x1;" \
		"i2c mw 0x68 003.1 0x55 0x1;" \
		"i2c mw 0x68 004.1 0x92 0x1;" \
		"i2c mw 0x68 005.1 0xED 0x1;" \
		"i2c mw 0x68 006.1 0x3F 0x1;" \
		"i2c mw 0x68 007.1 0x2A 0x1;" \
		"i2c mw 0x68 008.1 0x00 0x1;" \
		"i2c mw 0x68 009.1 0xC0 0x1;" \
		"i2c mw 0x68 010.1 0x00 0x1;" \
		"i2c mw 0x68 011.1 0x40 0x1;" \
		"i2c mw 0x68 019.1 0x29 0x1;" \
		"i2c mw 0x68 020.1 0x3E 0x1;" \
		"i2c mw 0x68 021.1 0xFE 0x1;" \
		"i2c mw 0x68 022.1 0xDF 0x1;" \
		"i2c mw 0x68 023.1 0x1F 0x1;" \
		"i2c mw 0x68 024.1 0x3F 0x1;" \
		"i2c mw 0x68 025.1 0x60 0x1;" \
		"i2c mw 0x68 031.1 0x00 0x1;" \
		"i2c mw 0x68 032.1 0x00 0x1;" \
		"i2c mw 0x68 033.1 0x07 0x1;" \
		"i2c mw 0x68 034.1 0x00 0x1;" \
		"i2c mw 0x68 035.1 0x00 0x1;" \
		"i2c mw 0x68 036.1 0x07 0x1;" \
		"i2c mw 0x68 040.1 0x00 0x1;" \
		"i2c mw 0x68 041.1 0x02 0x1;" \
		"i2c mw 0x68 042.1 0xBB 0x1;" \
		"i2c mw 0x68 043.1 0x00 0x1;" \
		"i2c mw 0x68 044.1 0x00 0x1;" \
		"i2c mw 0x68 045.1 0x31 0x1;" \
		"i2c mw 0x68 046.1 0x00 0x1;" \
		"i2c mw 0x68 047.1 0x00 0x1;" \
		"i2c mw 0x68 048.1 0x31 0x1;" \
		"i2c mw 0x68 055.1 0x00 0x1;" \
		"i2c mw 0x68 131.1 0x1F 0x1;" \
		"i2c mw 0x68 132.1 0x02 0x1;" \
		"i2c mw 0x68 137.1 0x01 0x1;" \
		"i2c mw 0x68 138.1 0x0F 0x1;" \
		"i2c mw 0x68 139.1 0xFF 0x1;" \
		"i2c mw 0x68 142.1 0x00 0x1;" \
		"i2c mw 0x68 143.1 0x00 0x1;" \
		"i2c mw 0x68 136.1 0x40 0x1;" \
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
