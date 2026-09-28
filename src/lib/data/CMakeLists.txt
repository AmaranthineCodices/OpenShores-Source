au_add_static_library(AuData "${CMAKE_CURRENT_SOURCE_DIR}" DEFINE AUDATA)
target_link_libraries(AuData PUBLIC AuGlobal AuUtil AuMath AuGL)
