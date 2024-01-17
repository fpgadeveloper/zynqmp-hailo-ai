DESCRIPTION = "gsthailo gstreamer plugin \
               compiles the hailo gstreamer plugin including hailonet \
               the output of the compilation (libgsthailo.so) is copied to the target's rootfs under usr/lib/gstreamer-1.0 (gstreamer's plugins directory)"

LICENSE = "LGPLv2.1"
LIC_FILES_CHKSUM = "file://hailort/LICENSE;md5=48b1c947c88868c23e4fb874890be6fc \
                    file://hailort/LICENSE-3RD-PARTY.md;md5=6bb4065ba26c9cc3e0761bfefbd6fa27 \
                    file://hailort/libhailort/bindings/gstreamer/LICENSE;md5=4b54a1fd55a448865a0b32d41598759d"

SRC_URI = "git://git@github.com/hailo-ai/hailort.git;protocol=https;branch=master"
SRCREV = "9bce73eb42bad4da7876f6bafa2521f3c411937e"

S = "${WORKDIR}/git"

inherit hailort-base
# recipe is dependent on libhailort shared object file
DEPENDS = "glib-2.0 gstreamer1.0 gstreamer1.0-plugins-base glib-2.0-native"
RDEPENDS:${PN} += "libhailort"

EXTRA_OECMAKE:append = "-DHAILO_BUILD_GSTREAMER=1"
OECMAKE_TARGET_COMPILE = "gsthailo"

GST_HAILO_SOURCES_DIR = "${S}/hailort/libhailort/bindings/gstreamer/gst-hailo"
GST_HAILO_INCLUDE_STAGING_DIR = "${D}${includedir}/gst-hailo"

do_install() {
    # copy libgsthailo shared object to usr/lib/gstreamer-1.0 in the rootfs - so gstreamer could load it
    install -d ${D}${libdir}/gstreamer-1.0
    install -m 0755 ${LIB_SRC_DIR}libgsthailo.so  ${D}${libdir}/gstreamer-1.0

    install -d ${GST_HAILO_INCLUDE_STAGING_DIR}
    cd ${GST_HAILO_SOURCES_DIR}
    find . -type f -name \*.hpp -exec install -D {} ${GST_HAILO_INCLUDE_STAGING_DIR}/{} \;
}

FILES:${PN} += "${libdir}/gstreamer-1.0/libgsthailo.so"
FILES:${PN}-dev += "${includedir}/gst-hailo ${includedir}/gst-hailo/*"
