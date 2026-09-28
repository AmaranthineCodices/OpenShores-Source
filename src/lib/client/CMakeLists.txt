au_add_static_library(AuClient "${CMAKE_CURRENT_SOURCE_DIR}" DEFINE AUCLIENT)
target_link_libraries(AuClient PUBLIC
    AuMail AuUtil AuMath AuGlobal AuGL AuData AuAtom AuLoginClient
)

# The client decodes scene and chat packets declared by the server protocol.
target_include_directories(AuClient PRIVATE
    "${CMAKE_SOURCE_DIR}/src/app/servers/scene"
)
