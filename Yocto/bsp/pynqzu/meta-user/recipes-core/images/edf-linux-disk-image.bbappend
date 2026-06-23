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
    gstreamer-vcu-examples \
    initcams \
    v4l-utils \
    nvme-cli \
    pciutils \
    mtd-utils \
    nfs-utils \
    can-utils \
"
