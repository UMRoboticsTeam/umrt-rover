cmake_minimum_required(VERSION 3.22.1)
project(umrt-can-definitions)

set(SYMBOL_FILE "${CMAKE_CURRENT_SOURCE_DIR}/Messages.sym" CACHE STRING "Symbol file to read for message definitions")
set(GENERATED_CODE_BASENAME "messages")
set(Python3_EXECUTABLE python3)

set(GENERATED_CODE_FOLDER ${CMAKE_CURRENT_BINARY_DIR})
set(GENERATED_HEADER ${GENERATED_CODE_FOLDER}/${GENERATED_CODE_BASENAME}.h)
set(GENERATED_SOURCE ${GENERATED_CODE_FOLDER}/${GENERATED_CODE_BASENAME}.c)
set(STRIPPED_SYMBOL_FILE_PATH ${CMAKE_CURRENT_BINARY_DIR}/Messages.stripped.sym)
set(DBC_OUTPUT_PATH ${CMAKE_CURRENT_BINARY_DIR}/Messages.dbc)

# ********** Setup CMake **********

# Default to C++17
if(NOT CMAKE_CXX_STANDARD)
    set(CMAKE_CXX_STANDARD 17)
endif()

if(CMAKE_COMPILER_IS_GNUCXX OR CMAKE_CXX_COMPILER_ID MATCHES "Clang")
    # enables building a static library but later link it into a dynamic library
    add_compile_options(-fPIC)
endif()
if(NOT WIN32)
    # About -Wno-sign-conversion: With Clang, -Wconversion implies -Wsign-conversion. There are a number of
    # implicit sign conversions in gtest.cc, see https://ci.ros2.org/job/ci_osx/9381/clang/.
    # Hence disabling -Wsign-conversion for now until all those have eventually been fixed.
    # (from https://github.com/ros2/rcutils/pull/263#issuecomment-663252537)
    add_compile_options(-Wall -Wextra -Wconversion -Wno-sign-conversion -Wpedantic)
endif()

# ********** Generate the code **********

# If symbol file is a symlink, get the absolute real path
get_filename_component(RESOLVED_SYMBOL_FILE "${SYMBOL_FILE}" REALPATH)

execute_process(
        COMMAND ./strip_sym_file.sh
        "${RESOLVED_SYMBOL_FILE}" "${STRIPPED_SYMBOL_FILE_PATH}"
)

execute_process(
        COMMAND ./generate_definitions_from_sym.sh
        "${STRIPPED_SYMBOL_FILE_PATH}" "${GENERATED_CODE_BASENAME}" "${GENERATED_CODE_FOLDER}"
        "${CMAKE_CURRENT_SOURCE_DIR}/TranslateToDbc.py" "${DBC_OUTPUT_PATH}"
)

# Tell CMake that it needs to reconfigure if the symbol file changes
# This is because the msgs list (and the rosidl target list) is generated at configure time not build time
# So if a build notices that the symbol file has changed, then that means we need new msgs, and thus we need to reconfigure
set_property(DIRECTORY APPEND PROPERTY
        CMAKE_CONFIGURE_DEPENDS "${RESOLVED_SYMBOL_FILE}"
)

install(
        FILES "${RESOLVED_SYMBOL_FILE}" "${STRIPPED_SYMBOL_FILE_PATH}" "${DBC_OUTPUT_PATH}" 
        DESTINATION share/${PROJECT_NAME}/
)

# ********** Set up umrt-can-definitions library **********

set(lib_target ${PROJECT_NAME})

add_library(${lib_target})

target_sources(${lib_target} PRIVATE # These files will only be available during building
        ${GENERATED_SOURCE}
        )

# Locate headers
# Using FILE_SET would be much cleaner, but needs CMake 3.23+ and ROS Humble ships with 3.22
set(public_headers # These files will be installed with the library
        ${GENERATED_HEADER}
        )
set_property(TARGET ${lib_target} PROPERTY PUBLIC_HEADER ${public_headers})
target_include_directories(${lib_target} PUBLIC # Everything in this folder will be available during building
        "$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include/${PROJECT_NAME}>"
        "$<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}/include/${PROJECT_NAME}>"
        "$<INSTALL_INTERFACE:include/>")

# Copy source file into package
install(FILES
        ${GENERATED_SOURCE}
        DESTINATION src/
)

# ********** Setup packaging **********

include(GNUInstallDirs)
include(CMakePackageConfigHelpers)

# Parse version number from the file
file(READ "version" version_input)
string(REGEX MATCH "([0-9]+)\.([0-9]+)\.([0-9]+)" _ ${version_input})

# Fill in cmake variables in config template
configure_file(
        ${CMAKE_CURRENT_SOURCE_DIR}/config.in.cmake
        ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Config.cmake
        @ONLY
)

write_basic_package_version_file(
        ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake
        VERSION ${version_input}
        COMPATIBILITY AnyNewerVersion
)

install(FILES
        ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake
        ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Config.cmake
        DESTINATION ${CMAKE_INSTALL_DATADIR}/${PROJECT_NAME}
)

install(
        TARGETS ${lib_target}  # These targets will be packaged
        EXPORT ${PROJECT_NAME}Targets
        PUBLIC_HEADER DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/${PROJECT_NAME}
)

install(
        EXPORT ${PROJECT_NAME}Targets
        NAMESPACE ${PROJECT_NAME}::
        DESTINATION ${CMAKE_INSTALL_DATADIR}/${PROJECT_NAME}
)

message(STATUS "Components to pack: ${CPACK_COMPONENTS_ALL}")
include(cpack.cmake)

