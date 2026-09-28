au_add_shared_library(AuClientRes "${CMAKE_CURRENT_SOURCE_DIR}" DEFINE AUCLIENTRES)
target_link_libraries(AuClientRes PRIVATE AuClientRes1)
