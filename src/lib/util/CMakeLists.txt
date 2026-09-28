au_add_static_library(AuUtil "${CMAKE_CURRENT_SOURCE_DIR}" DEFINE AUUTIL)

# Two utility protocol clients use packet enums declared by legacy server headers.
target_include_directories(AuUtil PRIVATE
    "${CMAKE_SOURCE_DIR}/src/app/servers/login"
    "${CMAKE_SOURCE_DIR}/src/app/servers/mail"
)
