au_add_shared_library(AuModelRes "${CMAKE_CURRENT_SOURCE_DIR}" DEFINE AUMODELRES)
target_link_libraries(AuModelRes PRIVATE
    AuModel1 AuModel2 AuModel3 AuModel4 AuModel5
    AuModel6 AuModel7 AuModel8 AuModel9 AuModel10
)
