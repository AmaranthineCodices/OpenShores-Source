au_add_executable(AuServerMon "${CMAKE_CURRENT_SOURCE_DIR}")
target_link_libraries(AuServerMon PRIVATE
    AuAtom AuData AuGlobal AuUtil AuGL AuMath AuClientMailRes AuStoryRes
)
target_include_directories(AuServerMon PRIVATE
    "${CMAKE_SOURCE_DIR}/src/app/servers/login"
    "${CMAKE_SOURCE_DIR}/src/app/servers/scene"
)
