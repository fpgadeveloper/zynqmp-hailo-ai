# Copyright (C) 2025-2026, Opsero Electronic Design Inc.  All rights reserved.
#
# SPDX-License-Identifier: MIT

# hailo-pci comes from the meta-hailo submodule (bblayers-extra.txt);
# same bbappend as the PetaLinux BSP.
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += "file://0001-vdma-take-mmap_read_lock-around-find_vma.patch;apply=no"

# Patch target lives at linux/vdma/memory.c, but the upstream recipe sets
# S = ${WORKDIR}/git/linux/pcie — so the file is OUTSIDE of S and do_patch
# won't see it. Apply manually at do_compile time, idempotently.
# Fixes WARN_ON at /include/linux/rwsem.h:80 in find_vma() on kernel >= 6.5
# (PetaLinux 2025.2 ships 6.12). Backport of the v5.3-hotfix-kernel-above-6-15
# fix from upstream hailort-drivers, for our HailoRT 4.23 driver.
#
# Idempotency check uses count: pristine upstream memory.c already has ONE
# mmap_read_lock (in prepare_sg_table); our patch adds a SECOND one around
# the find_vma call. So `grep -c` must be < 2 to know the patch isn't yet
# applied — a plain `grep -q` would always match the pre-existing call and
# silently skip our patch.
do_compile:prepend() {
    if [ "$(grep -c 'mmap_read_lock(current->mm);' ${WORKDIR}/git/linux/vdma/memory.c)" -lt 2 ]; then
        bbnote "Applying hailo-pci mmap_lock patch for kernel >= 6.5"
        patch -p1 -d ${WORKDIR}/git < ${WORKDIR}/0001-vdma-take-mmap_read_lock-around-find_vma.patch
    fi
}
