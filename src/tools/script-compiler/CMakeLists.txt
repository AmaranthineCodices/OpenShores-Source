au_add_executable(AuScript "${CMAKE_CURRENT_SOURCE_DIR}")
target_link_libraries(AuScript PRIVATE
    AuAtom AuData AuGlobal AuUtil AuGL AuMath AuStoryRes
)
add_custom_command(TARGET AuScript POST_BUILD
    COMMAND "${CMAKE_COMMAND}" -E copy_if_different
        "${CMAKE_CURRENT_SOURCE_DIR}/resources/AuScript.bin"
        "$<TARGET_FILE_DIR:AuScript>/AuScript.bin"
    COMMENT "Copying AuScript compiler data"
)
