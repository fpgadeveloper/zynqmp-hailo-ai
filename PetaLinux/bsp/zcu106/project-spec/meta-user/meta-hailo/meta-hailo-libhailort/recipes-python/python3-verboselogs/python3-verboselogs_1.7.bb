# Recipe created by recipetool
# This is the basis of a recipe and may need further editing in order to be fully functional.
# (Feel free to remove these comments when editing.)

SUMMARY = "Verbose logging level for Python's logging module"
HOMEPAGE = "https://verboselogs.readthedocs.io"
# WARNING: the following LICENSE and LIC_FILES_CHKSUM values are best guesses - it is
# your responsibility to verify that the values are complete and correct.
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://LICENSE.txt;md5=d4b9bfd363e871d2be165d0372c0169f"

SRC_URI = "https://files.pythonhosted.org/packages/29/15/90ffe9bdfdd1e102bc6c21b1eea755d34e69772074b6e706cab741b9b698/verboselogs-${PV}.tar.gz"
SRC_URI[md5sum] = "7c33bd58875e0d316a4f8d7505e946ff"
SRC_URI[sha256sum] = "e33ddedcdfdafcb3a174701150430b11b46ceb64c2a9a26198c76a156568e427"

S = "${WORKDIR}/verboselogs-${PV}"

inherit setuptools3

# WARNING: the following rdepends are determined through basic analysis of the
# python sources, and might not be 100% accurate.
RDEPENDS:${PN} += "${PYTHON_PN}-core ${PYTHON_PN}-logging ${PYTHON_PN}-math ${PYTHON_PN}-unittest"

# WARNING: We were unable to map the following python package/module
# dependencies to the bitbake packages which include them:
#    astroid
#    mock


