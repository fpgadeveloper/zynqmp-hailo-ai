# Copyright (C) 2025-2026, Opsero Electronic Design Inc.  All rights reserved.
#
# SPDX-License-Identifier: MIT
#
# Add the PL AXI IIC driver to the EDF u-boot so that the boot script can
# program the PYNQ-ZU Si5324 (PCIe reference clock). See the kconfig fragment
# in files/ for the rationale.
#
# := captures the bbappend dir at parse time (${THISDIR} is unreliable at task
# time inside a bbappend).
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " file://pynqzu-axi-iic.cfg"
