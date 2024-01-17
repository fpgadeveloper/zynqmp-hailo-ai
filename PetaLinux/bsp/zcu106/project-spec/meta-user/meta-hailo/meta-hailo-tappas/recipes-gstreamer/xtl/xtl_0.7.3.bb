SUMMARY = "Xtl: Basic tools (containers, algorithms) used by other quantstack packages"
HOMEPAGE = "https://github.com/xtensor-stack/xtl"

SRCREV_xtl = "46f8a9390db2c52aaf41de8f93ed0dab97af012d"
SRC_URI = "git://github.com/xtensor-stack/xtl.git;name=xtl"

LICENSE = "LICENSE"
LIC_FILES_CHKSUM = "file://LICENSE;md5=c12cbcb0f50cce3b0c58db4e3db8c2da"

S = "${WORKDIR}/git"

do_install(){
    install -d ${D}${includedir}/xtl
    cp -r ${S}/include/xtl/* ${D}${includedir}/xtl
}

FILES:${PN} += "/usr/include/* /usr/include/xtl/*"