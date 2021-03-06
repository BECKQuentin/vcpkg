set(MSVC_USE_STATIC_CRT_VALUE OFF)
if(VCPKG_CRT_LINKAGE STREQUAL "static")
    if(VCPKG_LIBRARY_LINKAGE STREQUAL "dynamic")
        message(FATAL_ERROR "Ceres does not currently support mixing static CRT and dynamic library linkage")
    endif()
    set(MSVC_USE_STATIC_CRT_VALUE ON)
endif()

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO ceres-solver/ceres-solver
    REF 2.0.0
    SHA512 6379666ef57af4ea85026644fa21365ce18fbaa12d50bd452bcdae0743a7b013effdd42c961e90c31815991bf315bd6904553dcc1a382ff5ed8c7abe9edf9a6c
    HEAD_REF master
    PATCHES
        0001_cmakelists_fixes.patch
        0002_use_glog_target.patch
        0003_fix_exported_ceres_config.patch
)

file(REMOVE ${SOURCE_PATH}/cmake/FindCXSparse.cmake)
file(REMOVE ${SOURCE_PATH}/cmake/FindGflags.cmake)
file(REMOVE ${SOURCE_PATH}/cmake/FindGlog.cmake)
file(REMOVE ${SOURCE_PATH}/cmake/FindEigen.cmake)
file(REMOVE ${SOURCE_PATH}/cmake/FindSuiteSparse.cmake)

vcpkg_check_features(OUT_FEATURE_OPTIONS FEATURE_OPTIONS
    "suitesparse"       SUITESPARSE
    "cxsparse"          CXSPARSE
    "lapack"            LAPACK
    "eigensparse"       EIGENSPARSE
    "tools"             GFLAGS
)

vcpkg_configure_cmake(
    SOURCE_PATH ${SOURCE_PATH}
    PREFER_NINJA
    OPTIONS
        ${FEATURE_OPTIONS}
        -DEXPORT_BUILD_DIR=ON
        -DBUILD_EXAMPLES=OFF
        -DBUILD_TESTING=OFF
        -DMSVC_USE_STATIC_CRT=${MSVC_USE_STATIC_CRT_VALUE}
        -DLIB_SUFFIX=${LIB_SUFFIX}
)

vcpkg_install_cmake()

if(VCPKG_TARGET_IS_WINDOWS)
  vcpkg_fixup_cmake_targets(CONFIG_PATH CMake)
else()
  vcpkg_fixup_cmake_targets(CONFIG_PATH lib${LIB_SUFFIX}/cmake/Ceres)
endif()

vcpkg_copy_pdbs()

# Changes target search path
if(VCPKG_TARGET_IS_WINDOWS)
  file(READ ${CURRENT_PACKAGES_DIR}/share/ceres/CeresConfig.cmake CERES_TARGETS)
  string(REPLACE "get_filename_component(CURRENT_ROOT_INSTALL_DIR\n    \${CERES_CURRENT_CONFIG_DIR}/../"
                 "get_filename_component(CURRENT_ROOT_INSTALL_DIR\n    \${CERES_CURRENT_CONFIG_DIR}/../../" CERES_TARGETS "${CERES_TARGETS}")
  file(WRITE ${CURRENT_PACKAGES_DIR}/share/ceres/CeresConfig.cmake "${CERES_TARGETS}")
else()
  file(READ ${CURRENT_PACKAGES_DIR}/share/ceres/CeresConfig.cmake CERES_TARGETS)
  string(REPLACE "get_filename_component(CURRENT_ROOT_INSTALL_DIR\n    \${CERES_CURRENT_CONFIG_DIR}/../../../"
                 "get_filename_component(CURRENT_ROOT_INSTALL_DIR\n    \${CERES_CURRENT_CONFIG_DIR}/../../" CERES_TARGETS "${CERES_TARGETS}")
  file(WRITE ${CURRENT_PACKAGES_DIR}/share/ceres/CeresConfig.cmake "${CERES_TARGETS}")
endif()

# Clean
file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/include)
file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/share)

file(INSTALL ${SOURCE_PATH}/LICENSE DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT} RENAME copyright)
