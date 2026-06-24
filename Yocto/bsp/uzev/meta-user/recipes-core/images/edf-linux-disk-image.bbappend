# Copyright (C) 2025-2026, Opsero Electronic Design Inc.  All rights reserved.
#
# SPDX-License-Identifier: MIT

# ZynqMP Hailo AI reference-design rootfs packages (ported from the PetaLinux
# bsp rootfs_config: design test/utility tools layered on the amd-edf base).
IMAGE_INSTALL:append = " \
    hailo-firmware \
    hailo-pci \
    hailortcli \
    libhailort \
    pyhailort \
    libgsthailo \
    libgsthailotools \
    hailo-post-processes \
    initcams \
    v4l-utils \
    nvme-cli \
    pciutils \
    mtd-utils \
    nfs-utils \
    can-utils \
"

# gstreamer-vcu-examples has REQUIRED_MACHINE_FEATURES = "vcu" (hardened Video
# Codec Unit). gen-machineconf only sets the vcu MACHINE_FEATURE when the design's
# XSA exposes a VCU; requesting the package unconditionally fails the build with
# "Nothing RPROVIDES gstreamer-vcu-examples" on non-VCU targets. Pull it in only
# when the generated machine actually has the feature.
IMAGE_INSTALL:append = " ${@bb.utils.contains('MACHINE_FEATURES', 'vcu', 'gstreamer-vcu-examples', '', d)}"
