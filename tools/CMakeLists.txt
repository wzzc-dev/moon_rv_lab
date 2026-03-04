cmake_minimum_required(VERSION 3.14)
project(rvrunner)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_BUILD_TYPE Release)

# libriscv paths
set(LIBRISCV_DIR /tmp/libriscv)
set(LIBRISCV_BUILD ${LIBRISCV_DIR}/emulator/.build)

add_executable(rvrunner rvrunner.cpp)

# Include both source and build directories
target_include_directories(rvrunner PRIVATE 
    ${LIBRISCV_DIR}/lib
    ${LIBRISCV_BUILD}/lib
)
target_link_libraries(rvrunner PRIVATE 
    ${LIBRISCV_BUILD}/lib/libriscv.a
)
# macOS specific frameworks
if(APPLE)
    find_library(SECURITY_FRAMEWORK Security REQUIRED)
    target_link_libraries(rvrunner PRIVATE ${SECURITY_FRAMEWORK})
endif()
target_link_options(rvrunner PRIVATE -pthread)
