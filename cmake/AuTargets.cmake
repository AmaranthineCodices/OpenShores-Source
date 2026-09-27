include(CMakeParseArguments)

function(au_collect_sources output directory)
    file(GLOB sources CONFIGURE_DEPENDS
        "${CMAKE_SOURCE_DIR}/${directory}/*.cpp"
        "${CMAKE_SOURCE_DIR}/${directory}/*.h"
        "${CMAKE_SOURCE_DIR}/${directory}/*.qrc"
    )

    if(WIN32)
        file(GLOB windows_resources CONFIGURE_DEPENDS
            "${CMAKE_SOURCE_DIR}/${directory}/*.rc"
        )
        list(APPEND sources ${windows_resources})
    endif()

    if(NOT sources)
        message(FATAL_ERROR "No sources found for ${directory}")
    endif()

    set(${output} ${sources} PARENT_SCOPE)
endfunction()

function(au_configure_target target directory)
    target_link_libraries(${target} PUBLIC AuBuildSettings AuQt)
    target_include_directories(${target} PUBLIC
        "${CMAKE_SOURCE_DIR}/${directory}"
    )
endfunction()

function(au_add_static_library target directory)
    set(options)
    set(one_value_args DEFINE)
    cmake_parse_arguments(ARG "${options}" "${one_value_args}" "" ${ARGN})

    au_collect_sources(sources "${directory}")
    add_library(${target} STATIC ${sources})
    au_configure_target(${target} "${directory}")

    if(ARG_DEFINE)
        target_compile_definitions(${target} PRIVATE ${ARG_DEFINE})
    endif()
endfunction()

function(au_add_shared_library target directory)
    set(options)
    set(one_value_args DEFINE)
    cmake_parse_arguments(ARG "${options}" "${one_value_args}" "" ${ARGN})

    au_collect_sources(sources "${directory}")
    add_library(${target} SHARED ${sources})
    au_configure_target(${target} "${directory}")
    set_target_properties(${target} PROPERTIES
        VERSION "${PROJECT_VERSION}"
        SOVERSION "${PROJECT_VERSION_MAJOR}"
    )

    if(ARG_DEFINE)
        target_compile_definitions(${target} PRIVATE ${ARG_DEFINE})
    endif()
endfunction()

function(au_add_executable target directory)
    au_collect_sources(sources "${directory}")
    add_executable(${target} ${sources})
    au_configure_target(${target} "${directory}")
    target_link_libraries(${target} PRIVATE AuPlatform)
endfunction()
