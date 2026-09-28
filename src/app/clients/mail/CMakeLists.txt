au_add_executable(AuMailClient "${CMAKE_CURRENT_SOURCE_DIR}")
target_link_libraries(AuMailClient PRIVATE
    AuClientMailRes AuData AuGlobal AuUtil AuGL AuMath AuLoginClient AuMail
)
