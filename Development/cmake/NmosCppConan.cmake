# see https://github.com/conan-io/cmake-conan#creating-packages
if(CONAN_EXPORTED)
    include(${CMAKE_BINARY_DIR}/conanbuildinfo.cmake)
    conan_basic_setup()
    return()
endif()

if(NOT EXISTS "${CMAKE_CURRENT_BINARY_DIR}/conan.cmake")
    message(STATUS "Downloading conan.cmake from https://github.com/conan-io/cmake-conan")
    file(DOWNLOAD "https://github.com/conan-io/cmake-conan/raw/v0.16.1/conan.cmake"
                  "${CMAKE_CURRENT_BINARY_DIR}/conan.cmake")
endif()

include(${CMAKE_CURRENT_BINARY_DIR}/conan.cmake)

# checking the Conan version produces a more helpful message than the confusing errors
# that are reported when some dependency's recipe uses new features; Conan moves fast!
# it would be nice to output a message if its a more recent version than tested, like:
# "Found Conan version 99.99 that is higher than the current tested version: " ${CONAN_VERSION_CUR})
set(CONAN_VERSION_MIN "1.33.0")
set(CONAN_VERSION_CUR "1.39.0")
conan_check(VERSION ${CONAN_VERSION_MIN} REQUIRED)

set(NMOS_CPP_CONAN_BUILD_LIBS "missing" CACHE STRING "Semicolon separated list of libraries to build rather than download")
mark_as_advanced(FORCE NMOS_CPP_CONAN_BUILD_LIBS)
set(NMOS_CPP_CONAN_OPTIONS "" CACHE STRING "Semicolon separated list of Conan options")
mark_as_advanced(FORCE NMOS_CPP_CONAN_OPTIONS)

if(CMAKE_CONFIGURATION_TYPES AND NOT CMAKE_BUILD_TYPE)
    # e.g. Visual Studio
    conan_cmake_run(CONANFILE conanfile.txt
                    BASIC_SETUP
                    GENERATORS cmake_find_package_multi
                    KEEP_RPATHS
                    OPTIONS ${NMOS_CPP_CONAN_OPTIONS}
                    BUILD ${NMOS_CPP_CONAN_BUILD_LIBS})

    # tell find_package() to try "Config" mode before "Module" mode if no mode was specified
    # so a FindXXXX.cmake file in CMake's default modules directory isn't used instead of
    # the <PackageName>Config.cmake generated by Conan in the current binary directory
    # see https://docs.conan.io/en/1.39/integrations/build_system/cmake/cmake_find_package_multi_generator.html
    set(CMAKE_FIND_PACKAGE_PREFER_CONFIG TRUE)

    # ensure <PackageName>Config.cmake config files generated by Conan can be found
    list(APPEND CMAKE_PREFIX_PATH ${CMAKE_CURRENT_BINARY_DIR})
else()
    conan_cmake_run(CONANFILE conanfile.txt
                    BASIC_SETUP
                    NO_OUTPUT_DIRS
                    GENERATORS cmake_find_package
                    KEEP_RPATHS
                    OPTIONS ${NMOS_CPP_CONAN_OPTIONS}
                    BUILD ${NMOS_CPP_CONAN_BUILD_LIBS})

    # ensure Find<PackageName>.cmake module files generated by Conan can be found
    list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_BINARY_DIR})
endif()
