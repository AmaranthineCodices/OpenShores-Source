au_add_executable(AuChatClient "${CMAKE_CURRENT_SOURCE_DIR}")
target_link_libraries(AuChatClient PRIVATE
    AuClientRes AuClient AuAtom AuData AuLoginClient AuMail AuGlobal AuUtil
    AuMath AuGL AuAtomRes AuBodyPartsRes AuModelRes AuTexture
    AuClientMailRes AuStoryRes
)
target_include_directories(AuChatClient PRIVATE
    "${CMAKE_SOURCE_DIR}/src/app/servers/scene"
)
