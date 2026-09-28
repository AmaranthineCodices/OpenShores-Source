au_add_static_library(AuGL "${CMAKE_CURRENT_SOURCE_DIR}" DEFINE AUGL)
target_link_libraries(AuGL PUBLIC AuUtil AuMath)
