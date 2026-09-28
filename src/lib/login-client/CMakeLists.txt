au_add_static_library(AuLoginClient "${CMAKE_CURRENT_SOURCE_DIR}" DEFINE AULOGINCLIENT)
target_link_libraries(AuLoginClient PUBLIC AuData AuGlobal AuUtil AuMath AuGL)
target_include_directories(AuLoginClient PRIVATE
    "${CMAKE_SOURCE_DIR}/src/app/servers/login"
)
