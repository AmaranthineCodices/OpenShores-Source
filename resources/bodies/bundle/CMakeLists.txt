au_add_shared_library(AuBodyPartsRes "${CMAKE_CURRENT_SOURCE_DIR}" DEFINE AUBODYPARTSRES)
target_link_libraries(AuBodyPartsRes PRIVATE
    AuBodyParts0 AuBodyParts1 AuBodyParts2 AuBodyParts3
    AuBodyParts4 AuBodyParts5 AuBodyParts6 AuBodyParts7 AuPowerArmor
)
