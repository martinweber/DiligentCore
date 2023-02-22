
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
        Diligent-Archiver-static
        Diligent-ArchiverInterface
        Diligent-BuildSettings 
        Diligent-PublicBuildSettings 
        Diligent-Primitives
        Diligent-Common
        Diligent-BasicPlatform
        Diligent-Win32Platform
        Diligent-PlatformInterface
        Diligent-ShaderTools
        Diligent-HLSL2GLSLConverterLib
        xxhash
        Vulkan-Headers
        volk_headers
        glslang
        glew-static
        spirv-cross-core
        SPIRV-Tools-opt
        SPIRV-Tools-static
        SPIRV
        OGLCompiler
        OSDependent
        MachineIndependent
        GenericCodeGen
        Diligent-GraphicsTools
        Diligent-GraphicsAccessories
        Diligent-GraphicsEngine
        Diligent-GraphicsEngineInterface
        Diligent-GraphicsEngineD3DBase
        Diligent-GraphicsEngineD3DBaseInterface
        Diligent-GraphicsEngineD3D11-static
        Diligent-GraphicsEngineD3D12-static
        Diligent-GraphicsEngineVk-static
        Diligent-GraphicsEngineOpenGL-static
        Diligent-GraphicsEngineNextGenBase
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