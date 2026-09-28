au_add_executable(AuMailServer "${CMAKE_CURRENT_SOURCE_DIR}")
target_link_libraries(AuMailServer PRIVATE
    AuGlobal AuUtil AuGL AuMath
)
