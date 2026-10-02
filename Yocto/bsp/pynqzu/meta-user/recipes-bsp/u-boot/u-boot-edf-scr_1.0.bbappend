# Copyright (C) 2025-2026, Opsero Electronic Design Inc.  All rights reserved.
#
# SPDX-License-Identifier: MIT

# PYNQ-ZU only: program the Si5324 that supplies the PCIe reference clock, from
# the EDF U-Boot script, before the kernel is loaded. The PetaLinux BSP does the
# same from its U-Boot bootcmd (platform-top.h "fmc_gt_clk_en"); in the EDF flow
# every SD boot runs boot.scr (meta-amd-edf u-boot-edf-scr), so the commands in
# files/pynqzu-si5324-pcie-refclk.cmd are prepended to the script right after
# unpack. Kept apart from u-boot-edf-scr_%.bbappend (BSP_EXTRA_BOOTARGS), which
# is the same file in every BSP.
#
# := captures the bbappend dir at parse time (${THISDIR} is unreliable at task
# time inside a bbappend).
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " file://pynqzu-si5324-pcie-refclk.cmd"

do_unpack[postfuncs] += "bsp_add_si5324_refclk"
bsp_add_si5324_refclk[dirs] = "${WORKDIR}"
bsp_add_si5324_refclk() {
    f=${WORKDIR}/edf-linux-mmc-boot.cmd
    [ -f "$f" ] || bbfatal "Si5324: $f not found"
    cat ${WORKDIR}/pynqzu-si5324-pcie-refclk.cmd "$f" > "$f.si5324"
    mv "$f.si5324" "$f"
    grep -q '^i2c mw 0x68 0x00.1 0x16 0x1$' "$f" || \
        bbfatal "Si5324: programming sequence not added to $f"
}
