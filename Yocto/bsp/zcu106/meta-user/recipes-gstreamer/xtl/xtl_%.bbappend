# Copyright (C) 2025-2026, Opsero Electronic Design Inc.  All rights reserved.
# SPDX-License-Identifier: MIT
#
# meta-hailo-tappas' xtl_0.7.3.bb fetches over git:// which github no longer
# supports (and sets no branch), so do_fetch fails. Override SRC_URI to use the
# https transport with the recipe's pinned SRCREV (nobranch since the rev is a
# bare commit, not a branch tip). xtl is a header-only dep of the Hailo TAPPAS
# post-processing libs (libgsthailotools / hailo-post-processes).
SRC_URI = "git://github.com/xtensor-stack/xtl.git;name=xtl;protocol=https;nobranch=1"
