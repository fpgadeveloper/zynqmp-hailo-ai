SUMMARY = "cxxopts : A lightweight C++ option parser library"

LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://LICENSE;md5=8de00431559a76a1b43f6fd44f8f6689"

SRC_URI = "git://github.com/jarro2783/cxxopts.git;protocol=https"

PV = "1.0+git${SRCPV}"
SRCREV = "c74846a891b3cc3bfa992d588b1295f528d43039"

S = "${WORKDIR}/git"

do_install(){
    install -d ${D}${includedir}/cxxopts
    cp -r ${S}/include/* ${D}${includedir}/cxxopts
}

FILES:${PN} += "/usr/include/* /usr/include/cxxopts/*"