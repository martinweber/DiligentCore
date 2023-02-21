
include(CMakePackageConfigHelpers)

set(DILIGENT_CORE_VERSION "2.5.3")
set(diligent_core_install_path_ "${CMAKE_INSTALL_LIBDIR}/cmake/DiligentCore")

configure_package_config_file(DiligentCoreConfig.cmake.in
    DiligentCoreConfig.cmake
    INSTALL_DESTINATION "${diligent_core_install_path_}"
    NO_CHECK_REQUIRED_COMPONENTS_MACRO
)

write_basic_package_version_file(DiligentCoreConfigVersion.cmake
    VERSION ${DILIGENT_CORE_VERSION}
    COMPATIBILITY SameMajorVersion
)

configure_file(DiligentCore.pc.in DiligentCore.pc @ONLY)

install(
    FILES 
        "${CMAKE_BINARY_DIR}/DiligentCoreConfig.cmake"
        "${CMAKE_BINARY_DIR}/DiligentCoreConfigVersion.cmake"
    DESTINATION
        "${diligent_core_install_path_}"
)

get_supported_backends(diligent_core_backends_)
message(DEBUG "Backends: ${diligent_core_backends_}")

set(diligent_core_backend_interfaces_ ${diligent_core_backends_})
list(TRANSFORM diligent_core_backend_interfaces_ REPLACE "-shared" "Interface")
message(DEBUG "Backend Interfaces: ${diligent_core_backend_interfaces_}")

install(
    TARGETS 
        Diligent-BuildSettings 
        Diligent-PublicBuildSettings 
        Diligent-Primitives
        Diligent-GraphicsEngineInterface
        Diligent-GraphicsEngineD3DBaseInterface
        ${diligent_core_backends_}
        ${diligent_core_backend_interfaces_}
    EXPORT DiligentCoreTargets
)

install(
    EXPORT DiligentCoreTargets
    FILE DiligentCoreTargets.cmake
    EXPORT_LINK_INTERFACE_LIBRARIES
    DESTINATION "${diligent_core_install_path_}"
)

install(
    FILES
        "${CMAKE_BINARY_DIR}/DiligentCore.pc"
    DESTINATION
        "${CMAKE_INSTALL_LIBDIR}/pkgconfig"
)