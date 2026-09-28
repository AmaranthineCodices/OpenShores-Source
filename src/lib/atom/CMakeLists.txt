au_add_static_library(AuAtom "${CMAKE_CURRENT_SOURCE_DIR}" DEFINE AUATOM)
target_link_libraries(AuAtom PUBLIC
    AuGlobal AuData AuUtil AuMath AuGL AuStoryRes SDL2::SDL2
)
