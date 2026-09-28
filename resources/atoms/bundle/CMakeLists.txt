au_add_shared_library(AuAtomRes "${CMAKE_CURRENT_SOURCE_DIR}" DEFINE AUATOMRES)
target_link_libraries(AuAtomRes PRIVATE
    AuAtomR1 AuAtomR2 AuAtomR3 AuAtomR4 AuAtomR5 AuAtomR6
)
