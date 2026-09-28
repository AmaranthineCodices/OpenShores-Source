au_add_executable(AuViewer "${CMAKE_CURRENT_SOURCE_DIR}")
target_sources(AuViewer PRIVATE
    "${CMAKE_SOURCE_DIR}/src/lib/client/settings/audnasettings.cpp"
    "${CMAKE_SOURCE_DIR}/src/lib/client/settings/audnasettings.h"
)
target_include_directories(AuViewer PRIVATE
    "${CMAKE_SOURCE_DIR}/src/lib/client/settings"
)
target_link_libraries(AuViewer PRIVATE
    AuAtom AuData AuGlobal AuUtil AuMath AuGL AuAtomRes
    AuModelRes AuBodyPartsRes AuTexture AuClientRes AuClientMailRes AuStoryRes
)
