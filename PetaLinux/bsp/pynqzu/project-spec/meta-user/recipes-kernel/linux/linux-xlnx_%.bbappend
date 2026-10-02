FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " file://bsp.cfg"
KERNEL_FEATURES:append = " bsp.cfg"

# Workaround for NULL deref in xlnx_mix_connector_init when
# xlnx_mixer.connect_drm_bridge=1 is set (needed for 2025.2 v_mix->dpsub
# DRM-bridge pipeline; dpsub no longer registers as an xlnx_bridge).
SRC_URI:append = " file://0001-drm-xlnx-mixer-fix-NULL-deref-in-connector_init.patch"

# Drop manual drm_mode_config_cleanup() in xlnx_unbind; required since the
# v_mix bridge-connector path uses drm_managed-based init helpers that
# clash with the manual cleanup (double-cleanup → ida_free for unallocated
# id and NULL deref during poweroff / reboot).
SRC_URI:append = " file://0002-drm-xlnx-drv-drop-mode_config_cleanup-on-unbind.patch"

# Silence drm_vblank_init_release WARN_ON on shutdown by powering outputs
# down via drm_atomic_helper_shutdown() before drm_dev_unregister().
SRC_URI:append = " file://0003-drm-xlnx-drv-disable-vblank-before-cleanup-on-shutdown.patch"

# ISP pipeline gamma LUTs were written to the wrong colour planes
# (red_gamma acted on blue, green_gamma on red, blue_gamma on green) and the
# default green curve differed from red/blue -> magenta cast on every camera
# picture. Put the R/G/B tables on the R/G/B planes; all defaults 2.0.
SRC_URI:append = " file://0004-media-xilinx-isppipeline-fix-gamma-LUT-plane-order.patch"

# ISP pipeline: use the xlnx,rgain / xlnx,bgain / xlnx,pawb DT values as the
# control defaults (they were overwritten by fixed defaults at probe).
SRC_URI:append = " file://0005-media-xilinx-isppipeline-use-the-DT-gain-and-threshold.patch"
