au_add_executable(AuLoginServer "${CMAKE_CURRENT_SOURCE_DIR}")
target_link_libraries(AuLoginServer PRIVATE
    AuData AuGlobal AuUtil AuGL AuMath
)
