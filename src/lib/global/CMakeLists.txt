au_add_static_library(AuGlobal "${CMAKE_CURRENT_SOURCE_DIR}" DEFINE AUGLOBAL)
target_link_libraries(AuGlobal PUBLIC AuUtil AuMath AuGL OpenAL::OpenAL)

# AuGlobal reads packet enums shared with the legacy login and mail servers.
target_include_directories(AuGlobal PRIVATE
    "${CMAKE_SOURCE_DIR}/src/app/servers/login"
    "${CMAKE_SOURCE_DIR}/src/app/servers/mail"
)
