cmake_minimum_required(VERSION 3.21)

project(ShoresOfHazeron VERSION 7.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_INCLUDE_CURRENT_DIR ON)

set(AU_OUTPUT_ROOT "${CMAKE_BINARY_DIR}" CACHE PATH
    "Directory that receives the bin and lib build artifacts"
)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${AU_OUTPUT_ROOT}/bin")
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${AU_OUTPUT_ROOT}/lib")
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${AU_OUTPUT_ROOT}/lib")
foreach(configuration Debug Release RelWithDebInfo MinSizeRel)
    string(TOUPPER "${configuration}" configuration_upper)
    set(CMAKE_RUNTIME_OUTPUT_DIRECTORY_${configuration_upper} "${AU_OUTPUT_ROOT}/bin")
    set(CMAKE_LIBRARY_OUTPUT_DIRECTORY_${configuration_upper} "${AU_OUTPUT_ROOT}/lib")
    set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY_${configuration_upper} "${AU_OUTPUT_ROOT}/lib")
endforeach()

if(UNIX AND NOT APPLE)
    set(CMAKE_BUILD_RPATH_USE_ORIGIN ON)
    set(CMAKE_BUILD_RPATH "$ORIGIN/../lib")
endif()

if(WIN32)
    enable_language(RC)
endif()

set(AU_OPENGL_VERSION "32" CACHE STRING "OpenGL shader version: 32, 33, or 41")
set_property(CACHE AU_OPENGL_VERSION PROPERTY STRINGS 32 33 41)
if(NOT AU_OPENGL_VERSION MATCHES "^(32|33|41)$")
    message(FATAL_ERROR "AU_OPENGL_VERSION must be 32, 33, or 41")
endif()

file(MAKE_DIRECTORY "${CMAKE_BINARY_DIR}/generated")
configure_file(
    "${CMAKE_SOURCE_DIR}/cmake/AuGLVer.h.in"
    "${CMAKE_BINARY_DIR}/generated/AuGLVer.h"
    @ONLY
)

include(cmake/Dependencies.cmake)
include(cmake/AuTargets.cmake)

file(GLOB au_module_candidates LIST_DIRECTORIES true "${CMAKE_SOURCE_DIR}/au*")
set(au_module_directories)
foreach(candidate IN LISTS au_module_candidates)
    if(IS_DIRECTORY "${candidate}")
        list(APPEND au_module_directories "${candidate}")
    endif()
endforeach()

add_library(AuBuildSettings INTERFACE)
target_compile_features(AuBuildSettings INTERFACE cxx_std_11)
target_include_directories(AuBuildSettings INTERFACE
    "${CMAKE_SOURCE_DIR}"
    "${CMAKE_BINARY_DIR}/generated"
    ${au_module_directories}
)

if(MINGW)
    # Large generated Qt resource objects can exceed MinGW's default section limit.
    target_compile_options(AuBuildSettings INTERFACE -Wa,-mbig-obj)
endif()

add_library(AuQt INTERFACE)
target_link_libraries(AuQt INTERFACE
    Qt5::Core
    Qt5::Gui
    Qt5::Network
    Qt5::OpenGL
    Qt5::Sql
    Qt5::Widgets
)

add_library(AuPlatform INTERFACE)
target_link_libraries(AuPlatform INTERFACE
    SDL2::SDL2
    OpenAL::OpenAL
    OpenGL::GL
    OpenGL::GLU
)

# Foundation libraries.
au_add_static_library(AuUtil auutil DEFINE AUUTIL)
au_add_static_library(AuMath aumath DEFINE AUMATH)
au_add_static_library(AuGL augl DEFINE AUGL)
target_link_libraries(AuGL PUBLIC AuUtil AuMath)

au_add_static_library(AuGlobal auglobal DEFINE AUGLOBAL)
target_link_libraries(AuGlobal PUBLIC AuUtil AuMath AuGL OpenAL::OpenAL)

au_add_static_library(AuData audata DEFINE AUDATA)
target_link_libraries(AuData PUBLIC AuGlobal AuUtil AuMath AuGL)

au_add_static_library(AuLoginClient auloginclient DEFINE AULOGINCLIENT)
target_link_libraries(AuLoginClient PUBLIC AuGlobal AuUtil AuMath AuGL)

au_add_static_library(AuMail aumail DEFINE AUMAIL)
target_link_libraries(AuMail PUBLIC
    AuGlobal AuUtil AuMath AuGL AuLoginClient
)

au_add_shared_library(AuStoryRes austoryres DEFINE AUSTORYRES)

au_add_static_library(AuAtom auatom DEFINE AUATOM)
target_link_libraries(AuAtom PUBLIC
    AuGlobal AuData AuUtil AuMath AuGL AuStoryRes SDL2::SDL2
)

au_add_static_library(AuClient auclient DEFINE AUCLIENT)
target_link_libraries(AuClient PUBLIC
    AuMail AuUtil AuMath AuGlobal AuGL AuData AuAtom AuLoginClient
)

au_add_static_library(AuDesigner audesigner DEFINE AUDESIGNER)
target_link_libraries(AuDesigner PUBLIC
    AuUtil AuMath AuGlobal AuGL AuData AuAtom AuLoginClient AuMail AuClient
    SDL2::SDL2
)

# Atom resource shards and aggregate shared library.
foreach(index RANGE 1 6)
    au_add_static_library(AuAtomR${index} auatomr${index})
endforeach()
au_add_shared_library(AuAtomRes auatomres DEFINE AUATOMRES)
target_link_libraries(AuAtomRes PRIVATE
    AuAtomR1 AuAtomR2 AuAtomR3 AuAtomR4 AuAtomR5 AuAtomR6
)

# Body resource shards and aggregate shared library.
foreach(index RANGE 0 7)
    au_add_static_library(AuBodyParts${index} aubodyparts${index})
endforeach()
au_add_static_library(AuPowerArmor aupowerarmor)
au_add_shared_library(AuBodyPartsRes aubodypartsres DEFINE AUBODYPARTSRES)
target_link_libraries(AuBodyPartsRes PRIVATE
    AuBodyParts0 AuBodyParts1 AuBodyParts2 AuBodyParts3
    AuBodyParts4 AuBodyParts5 AuBodyParts6 AuBodyParts7
    AuPowerArmor
)

# Model resource shards and aggregate shared library.
foreach(index RANGE 1 10)
    au_add_static_library(AuModel${index} aumodel${index})
endforeach()
au_add_shared_library(AuModelRes aumodelres DEFINE AUMODELRES)
target_link_libraries(AuModelRes PRIVATE
    AuModel1 AuModel2 AuModel3 AuModel4 AuModel5
    AuModel6 AuModel7 AuModel8 AuModel9 AuModel10
)

# Texture resource shards and aggregate shared library.
foreach(index RANGE 1 5)
    au_add_static_library(AuScTex${index} ausctex${index})
endforeach()
au_add_static_library(AuShipTex0 aushiptex0)
au_add_shared_library(AuTexture autexture DEFINE AUTEXTURE)
target_link_libraries(AuTexture PRIVATE
    AuScTex1 AuScTex2 AuScTex3 AuScTex4 AuScTex5 AuShipTex0
)

# Client resource libraries.
au_add_static_library(AuClientRes1 auclientres1)
au_add_shared_library(AuClientRes auclientres DEFINE AUCLIENTRES)
target_link_libraries(AuClientRes PRIVATE AuClientRes1)
au_add_shared_library(AuClientMailRes auclientmailres DEFINE AUCLIENTMAILRES)

# Primary game client.
au_add_executable(AuSceneClient ausceneclient)
target_link_libraries(AuSceneClient PRIVATE
    AuClientRes
    AuDesigner
    AuClient
    AuAtom
    AuData
    AuLoginClient
    AuMail
    AuGlobal
    AuUtil
    AuMath
    AuGL
    AuAtomRes
    AuModelRes
    AuBodyPartsRes
    AuTexture
    AuClientMailRes
    AuStoryRes
)

# Multiplayer servers.
au_add_executable(AuLoginServer auloginserver)
target_link_libraries(AuLoginServer PRIVATE
    AuData AuGlobal AuUtil AuGL AuMath
)

au_add_executable(AuMailServer aumailserver)
target_link_libraries(AuMailServer PRIVATE
    AuGlobal AuUtil AuGL AuMath
)

au_add_executable(AuSceneServer ausceneserver)
target_link_libraries(AuSceneServer PRIVATE
    AuAtom
    AuData
    AuGlobal
    AuUtil
    AuGL
    AuMath
    AuLoginClient
    AuMail
    AuAtomRes
    AuModelRes
    AuBodyPartsRes
    AuStoryRes
)

# Additional clients.
au_add_executable(AuMailClient aumailclient)
target_link_libraries(AuMailClient PRIVATE
    AuClientMailRes AuData AuGlobal AuUtil AuGL AuMath AuLoginClient AuMail
)

au_add_executable(AuChatClient auchatclient)
target_link_libraries(AuChatClient PRIVATE
    AuClientRes AuClient AuAtom AuData AuLoginClient AuMail AuGlobal AuUtil
    AuMath AuGL AuAtomRes AuBodyPartsRes AuModelRes AuTexture
    AuClientMailRes AuStoryRes
)

au_add_executable(AuLauncher aulauncher)
target_link_libraries(AuLauncher PRIVATE AuUtil)

# Account and status CGI/command-line programs.
foreach(account_target IN ITEMS
    AuAcctEmail
    AuAcctExpire
    AuAcctNew
    AuAcctPassword
    AuAcctSendPassword
)
    string(TOLOWER "${account_target}" account_directory)
    au_add_executable(${account_target} ${account_directory})
    target_link_libraries(${account_target} PRIVATE AuUtil)
endforeach()

au_add_executable(AuServerStatus auserverstatus)
target_link_libraries(AuServerStatus PRIVATE AuUtil)

# Administrative and content tools.
au_add_executable(AuEmpireReport auempirereport)
target_link_libraries(AuEmpireReport PRIVATE
    AuAtom AuData AuGlobal AuUtil AuGL AuMath AuLoginClient AuMail
    AuBodyPartsRes AuAtomRes AuStoryRes
)

au_add_executable(AuScript auscript)
target_link_libraries(AuScript PRIVATE
    AuAtom AuData AuGlobal AuUtil AuGL AuMath AuStoryRes
)

au_add_executable(AuServerMon auservermon)
target_link_libraries(AuServerMon PRIVATE
    AuAtom AuData AuGlobal AuUtil AuGL AuMath AuClientMailRes AuStoryRes
)

au_add_executable(AuViewer auviewer)
target_sources(AuViewer PRIVATE
    "${CMAKE_SOURCE_DIR}/auclient/audnasettings.cpp"
    "${CMAKE_SOURCE_DIR}/auclient/audnasettings.h"
)
target_link_libraries(AuViewer PRIVATE
    AuAtom AuData AuGlobal AuUtil AuMath AuGL AuAtomRes
    AuModelRes AuBodyPartsRes AuTexture AuClientRes AuClientMailRes AuStoryRes
)

au_collect_sources(hashpack_sources hashpack)
add_executable(hashpack ${hashpack_sources})
target_link_libraries(hashpack PRIVATE AuBuildSettings Qt5::Core Qt5::Gui)

add_custom_target(client DEPENDS AuSceneClient)
add_custom_target(clients DEPENDS
    AuSceneClient AuMailClient AuChatClient AuLauncher
)
add_custom_target(servers DEPENDS AuLoginServer AuMailServer AuSceneServer)
add_custom_target(cgi DEPENDS
    AuAcctEmail AuAcctExpire AuAcctNew AuAcctPassword
    AuAcctSendPassword AuServerStatus
)
add_custom_target(tools DEPENDS
    AuEmpireReport AuScript AuServerMon AuViewer hashpack
)
add_custom_target(programs DEPENDS clients servers cgi tools)
