set(AU_CLIENT_RUNTIME_SOURCE "${CMAKE_CURRENT_SOURCE_DIR}/client")
set(AU_CLIENT_RUNTIME_OUTPUT "${AU_OUTPUT_ROOT}/bin")
set(AU_CLIENT_BLUEPRINT_SOURCE "${AU_CLIENT_RUNTIME_SOURCE}/Blueprints")
set(AU_CLIENT_TEXTURE_SOURCE "${CMAKE_SOURCE_DIR}/resources/textures/runtime")
# Audio is generated outside resources so builds never dirty the source tree.
set(AU_CLIENT_AUDIO_SOURCE "${CMAKE_SOURCE_DIR}/build/assets/sfx.har")

file(GLOB_RECURSE AU_CLIENT_BLUEPRINT_FILES CONFIGURE_DEPENDS
    "${AU_CLIENT_BLUEPRINT_SOURCE}/*"
)
file(GLOB AU_CLIENT_TEXTURE_FILES CONFIGURE_DEPENDS
    "${AU_CLIENT_TEXTURE_SOURCE}/*.png"
)
set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS
    "${AU_CLIENT_AUDIO_SOURCE}"
)

set(runtime_commands
    COMMAND "${CMAKE_COMMAND}" -E make_directory "${AU_CLIENT_RUNTIME_OUTPUT}"
    COMMAND "${CMAKE_COMMAND}" -E copy_if_different
        "${AU_CLIENT_RUNTIME_SOURCE}/GD"
        "${AU_CLIENT_RUNTIME_OUTPUT}/GD"
    COMMAND "${CMAKE_COMMAND}" -E remove_directory
        "${AU_CLIENT_RUNTIME_OUTPUT}/Blueprints"
    COMMAND "${CMAKE_COMMAND}" -E copy_directory
        "${AU_CLIENT_BLUEPRINT_SOURCE}"
        "${AU_CLIENT_RUNTIME_OUTPUT}/Blueprints"
    COMMAND "${CMAKE_COMMAND}" -E make_directory
        "${AU_CLIENT_RUNTIME_OUTPUT}/tex"
    COMMAND "${CMAKE_COMMAND}" -E copy_if_different
        ${AU_CLIENT_TEXTURE_FILES}
        "${AU_CLIENT_RUNTIME_OUTPUT}/tex"
)

set(runtime_dependencies
    "${AU_CLIENT_RUNTIME_SOURCE}/GD"
    ${AU_CLIENT_BLUEPRINT_FILES}
    ${AU_CLIENT_TEXTURE_FILES}
)

list(APPEND runtime_commands
    COMMAND "${CMAKE_COMMAND}" -E copy_if_different
        "${AU_CLIENT_AUDIO_SOURCE}"
        "${AU_CLIENT_RUNTIME_OUTPUT}/sfx.har"
)
list(APPEND runtime_dependencies "${AU_CLIENT_AUDIO_SOURCE}")

add_custom_target(AuClientRuntimeData
    ${runtime_commands}
    DEPENDS ${runtime_dependencies}
    COMMENT "Copying client runtime data"
    VERBATIM
)
