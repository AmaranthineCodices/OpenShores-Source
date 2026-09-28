au_add_executable(AuServerStatus "${CMAKE_CURRENT_SOURCE_DIR}")
target_link_libraries(AuServerStatus PRIVATE AuUtil)
target_include_directories(AuServerStatus PRIVATE
    "${CMAKE_SOURCE_DIR}/src/app/servers/login"
    "${CMAKE_SOURCE_DIR}/src/app/servers/mail"
    "${CMAKE_SOURCE_DIR}/src/app/servers/scene"
)
