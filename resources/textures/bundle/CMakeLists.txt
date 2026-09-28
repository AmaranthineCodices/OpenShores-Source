au_add_shared_library(AuTexture "${CMAKE_CURRENT_SOURCE_DIR}" DEFINE AUTEXTURE)
target_link_libraries(AuTexture PRIVATE
    AuScTex1 AuScTex2 AuScTex3 AuScTex4 AuScTex5 AuShipTex0
)
