au_add_executable(AuEmpireReport "${CMAKE_CURRENT_SOURCE_DIR}")
target_link_libraries(AuEmpireReport PRIVATE
    AuAtom AuData AuGlobal AuUtil AuGL AuMath AuLoginClient AuMail
    AuBodyPartsRes AuAtomRes AuStoryRes
)
target_include_directories(AuEmpireReport PRIVATE
    "${CMAKE_SOURCE_DIR}/src/app/servers/scene"
)
