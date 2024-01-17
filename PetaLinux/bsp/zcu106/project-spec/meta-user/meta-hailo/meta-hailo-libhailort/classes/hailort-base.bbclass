DESCRIPTION = "Base class to compile libhailort component"

inherit cmake

LIB_SRC_DIR = "${WORKDIR}/lib/"
BIN_SRC_DIR = "${WORKDIR}/bin/"

OECMAKE_GENERATOR = "Unix Makefiles"
HAILORT_BUILD_TYPE = "Release"
EXTRA_OECMAKE =  "-DCMAKE_LIBRARY_OUTPUT_DIRECTORY=${LIB_SRC_DIR} \
                  -DCMAKE_RUNTIME_OUTPUT_DIRECTORY=${BIN_SRC_DIR} \
                  -DCMAKE_BUILD_TYPE=${HAILORT_BUILD_TYPE}        \
                  -DCMAKE_SKIP_RPATH=ON"

# Skip cmake do_install process - overrides cmake bbclass
cmake_do_install() {
    :
}

# Note: This file must be placed at ${DL_DIR} so that we can build offline (i.e. without network connection)
TAR_FILE_PATH = "${DL_DIR}/hailort-${P}.tar.gz"

# Prepares hailort's external dependencies, so that the unpack stage (and onwards) can run offline
# If HAILORT_OFFLINE_BUILD_ENABLE is set we'll package hailort's sources and dependencies into ${TAR_FILE_PATH}
# If HAILORT_OFFLINE_BUILD_USE_EXISTING_TAR is set, we'll skip this task and try to unpack existing sources from ${TAR_FILE_PATH}
python do_prepare_hailort_external_dependencies() {
    if (d.getVar('HAILORT_OFFLINE_BUILD_ENABLE') is None) or (d.getVar('HAILORT_OFFLINE_BUILD_ENABLE') == "0"):
        bb.note('Skipping do_prepare_hailort_external_dependencies (HAILORT_OFFLINE_BUILD_ENABLE is not set or is set to "0")')
        return
    if (d.getVar('HAILORT_OFFLINE_BUILD_USE_EXISTING_TAR') is not None) and (d.getVar('HAILORT_OFFLINE_BUILD_USE_EXISTING_TAR') != "0"):
        bb.note('Skipping do_prepare_hailort_external_dependencies (HAILORT_OFFLINE_BUILD_USE_EXISTING_TAR is set)')
        return
    temp_directory = d.getVar('WORKDIR') + '/temp_prepare_externals'
    # Unpack the sources into a temp dir
    try:
        fetcher = bb.fetch2.Fetch([d.getVar('SRC_URI')], d)
        fetcher.unpack(temp_directory)
    except bb.fetch2.BBFetchException as e:
        bb.fatal("Bitbake Fetcher Error: " + repr(e))
    # Download dependecies in the unpacked repo
    git_temp_directory = temp_directory + '/git'
    bb.process.run('cmake -P hailort/prepare_externals.cmake', cwd=git_temp_directory)
    # Remove CMakeCache.txt files created from building that occurs in prepare_externals.cmake (needed so that the repo can be move to another dir)
    bb.process.run('rm -f hailort/pre_build/build/CMakeCache.txt hailort/pre_build/external/build/CMakeCache.txt', cwd=git_temp_directory)
    # Pack to tar
    bb.process.run('tar -czvf {} .'.format(d.getVar('TAR_FILE_PATH')), cwd=git_temp_directory)
}

# Note:
# * The task needs to run after fetching so we can access the repos.
# * The task needs cmake, which is provided by the do_prepare_recipe_sysroot task.
addtask do_prepare_hailort_external_dependencies before do_unpack after do_fetch do_prepare_recipe_sysroot

# If HAILORT_OFFLINE_BUILD_ENABLE is set we'll unpack hailort's sources and dependencies from ${TAR_FILE_PATH} (overwriting the default unpack flow)
do_unpack_from_tar_if_exists() {
    if [ -z "${HAILORT_OFFLINE_BUILD_ENABLE}" ] || [ "${HAILORT_OFFLINE_BUILD_ENABLE}" = "0" ]; then
        bbnote "Skipping unpack from tar (\$HAILORT_OFFLINE_BUILD_ENABLE is not set or is set to \"0\")"
    else
        bbnote "Unpacking from tar ${TAR_FILE_PATH}"
        tar -xvf ${TAR_FILE_PATH} -C ${S}
    fi
}
do_unpack[postfuncs] += "do_unpack_from_tar_if_exists"
