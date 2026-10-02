# Copyright (C) 2025-2026, Opsero Electronic Design Inc.  All rights reserved.
#
# SPDX-License-Identifier: MIT

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " file://bsp.cfg"
KERNEL_FEATURES:append = " bsp.cfg"

# 2025.2 v_mix -> dpsub DRM-bridge pipeline (xlnx_mixer.connect_drm_bridge=1)
# fixes. Same patches as the PetaLinux BSP. Without them:
#  0001: NULL deref (kernel oops) in xlnx_mix_connector_init at probe, since
#        dpsub no longer registers as an xlnx_bridge -> no display pipeline.
#  0002: manual drm_mode_config_cleanup() in xlnx_unbind clashes with the
#        drm_managed init helpers -> ida_free / NULL deref on poweroff/reboot.
#  0003: drm_vblank_init_release WARN_ON on shutdown; outputs are now powered
#        down via drm_atomic_helper_shutdown() before drm_dev_unregister().
SRC_URI:append = " file://0001-drm-xlnx-mixer-fix-NULL-deref-in-connector_init.patch"
SRC_URI:append = " file://0002-drm-xlnx-drv-drop-mode_config_cleanup-on-unbind.patch"
SRC_URI:append = " file://0003-drm-xlnx-drv-disable-vblank-before-cleanup-on-shutdown.patch"

# ISP pipeline (xilinx-isppipeline) fixes:
#  0004: the gamma LUTs were written to the wrong colour planes (red_gamma
#        acted on blue, green_gamma on red, blue_gamma on green) and the
#        default green curve differed from red/blue -> magenta cast on every
#        camera picture. Now R/G/B tables land on R/G/B, all defaults 2.0.
#  0005: the xlnx,rgain / xlnx,bgain / xlnx,pawb DT values were overwritten
#        by fixed control defaults at probe and never reached the core.
SRC_URI:append = " file://0004-media-xilinx-isppipeline-fix-gamma-LUT-plane-order.patch"
SRC_URI:append = " file://0005-media-xilinx-isppipeline-use-the-DT-gain-and-threshold.patch"

# PYNQ-ZU on-board Wi-Fi (Microchip WILC3000 on PS SD1). linux-xlnx 6.12 has
# the in-tree wilc1000 driver but it only recognises the WILC1000 chip ID;
# this backports mainline WILC3000 support (v6.13..v6.18, adapted to the 6.12
# cfg80211 API). Enabled by CONFIG_WILC1000_SDIO=m in bsp.cfg; firmware comes
# from the wilc3000-firmware recipe.
SRC_URI:append = " file://0010-wifi-wilc1000-backport-WILC3000-support.patch"
# A station dump on wlan0 before its first open (no firmware running yet)
# left a config query queued that broke the next firmware start.
SRC_URI:append = " file://0011-wifi-wilc1000-refuse-config-requests-before-the-first-open.patch"
