# Recipe created by recipetool
# This is the basis of a recipe and may need further editing in order to be fully functional.
# (Feel free to remove these comments when editing.)

SUMMARY = "Distribution utilities"
HOMEPAGE = "https://bitbucket.org/pypa/distlib"
# WARNING: the following LICENSE and LIC_FILES_CHKSUM values are best guesses - it is
# your responsibility to verify that the values are complete and correct.
#
# The following license files were not able to be identified and are
# represented as "Unknown" below, you will need to check them yourself:
#   LICENSE.txt
#   tests/testdist-0.1/LICENSE
#   tests/test_testdist-0.1/LICENSE
#   tests/testsrc/LICENSE
LICENSE = "PSF"
LIC_FILES_CHKSUM = "file://LICENSE.txt;md5=f6a11430d5cd6e2cd3832ee94f22ddfc \
                    file://tests/testdist-0.1/LICENSE;md5=ec4886c1e9e3d1b699af172fb703677b \
                    file://tests/test_testdist-0.1/LICENSE;md5=ec4886c1e9e3d1b699af172fb703677b \
                    file://tests/testsrc/LICENSE;md5=9029fc6cf0fbe3c5a0df05762a2be5cc"

SRC_URI = "https://files.pythonhosted.org/packages/2f/83/1eba07997b8ba58d92b3e51445d5bf36f9fba9cb8166bcae99b9c3464841/distlib-${PV}.zip"
SRC_URI[md5sum] = "4baf787d8aceb260d6f77cb31bf27cf6"
SRC_URI[sha256sum] = "edf6116872c863e1aa9d5bb7cb5e05a022c519a4594dc703843343a9ddd9bff1"

S = "${WORKDIR}/distlib-${PV}"

inherit distutils3

# WARNING: the following rdepends are determined through basic analysis of the
# python sources, and might not be 100% accurate.
RDEPENDS:${PN} += "python3-compile python3-compression python3-contextlib2 python3-core python3-crypt python3-datetime python3-distutils python3-email python3-html python3-io python3-lang python3-netclient python3-netserver python3-pkgutil python3-shell python3-textutils python3-unixadmin python3-xmlrpc"

# WARNING: We were unable to map the following python3 package/module
# dependencies to the bitbake packages which include them:
#    __builtin__
#    _frozen_importlib
#    _frozen_importlib_external
#    collections.abc
#    configparser
#    html
#    html.entities
#    html.parser
#    http.client
#    imp
#    importlib.util
#    java
#    queue
#    reprlib
#    thread
#    urllib.error
#    urllib.parse
#    urllib.request
#    xmlrpc.client


