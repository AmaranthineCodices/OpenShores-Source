au_add_static_library(AuMail "${CMAKE_CURRENT_SOURCE_DIR}" DEFINE AUMAIL)
target_link_libraries(AuMail PUBLIC
    AuGlobal AuUtil AuMath AuGL AuLoginClient
)
target_include_directories(AuMail PRIVATE
    "${CMAKE_SOURCE_DIR}/src/app/servers/mail"
)
