SUMMARY = "Xtensor : C++ library meant for numerical analysis with multi-dimensional array expressions"
HOMEPAGE = "https://github.com/xtensor-stack/xtensor"

SRCREV_xtensor = "825c0fd8a465049c06ad89fa3911b342dbffcabf"
SRC_URI = "git://github.com/xtensor-stack/xtensor.git;name=xtensor"

LICENSE = "LICENSE"
LIC_FILES_CHKSUM = "file://LICENSE;md5=5c67ec4d3eb9c5b7eed4c37e69571b93"

S = "${WORKDIR}/git"
RDEPENDS:${PN} += "xtl"

do_install(){
    install -d ${D}${includedir}/xtensor
    cp -r ${S}/include/xtensor/* ${D}${includedir}/xtensor
}

FILES:${PN} += "/usr/include/* /usr/include/xtensor/*"