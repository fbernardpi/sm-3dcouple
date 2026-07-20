# Pin BDD's moving CPM dependencies.
#
# external/BDD is a submodule we can't edit, and its CMakeLists requests every
# dependency at a moving ref (#main / #master). Those refs drift and eventually
# pull in incompatible major versions (e.g. PEGTL 4.0.0 requires C++20 and
# breaks BDD's C++17 grammar code). CPM dedupes packages by NAME and the first
# add wins, so registering each dependency here — before add_subdirectory(BDD)
# — makes BDD's later moving-ref requests no-ops that reuse these pins.
#
# Bump a pin here rather than touching the submodule.

if(SMM_DEPS_PINNED)
    return()
endif()
set(SMM_DEPS_PINNED TRUE)

# Several of the pinned (older) dependencies declare cmake_minimum_required
# below 3.5, which CMake 4 refuses outright. Set the policy floor so their
# CMakeLists still configure. Must be a CACHE variable — a normal variable does
# not propagate into CPM's add_subdirectory scopes. (CMake >= 3.30.)
set(CMAKE_POLICY_VERSION_MINIMUM 3.5 CACHE STRING "Min policy version for old deps" FORCE)

# Newer clang promotes size_t->int narrowing in braced-init lists to a hard
# error (-Wc++11-narrowing-const-reference); BDD relies on the older lenient
# behavior (e.g. minimum_degree_ordering.hxx, ILP_input.cpp). Downgrade it so
# the submodule compiles. This runs before add_subdirectory(external/BDD), so
# the directory-level option propagates into BDD's targets.
include(CheckCXXCompilerFlag)
foreach(_flag c++11-narrowing-const-reference c++11-narrowing)
    check_cxx_compiler_flag("-Wno-${_flag}" _has_no_${_flag})
    if(_has_no_${_flag})
        add_compile_options("-Wno-${_flag}")
    endif()
endforeach()

# --- bootstrap CPM (same pattern BDD uses) ---
set(CPM_DOWNLOAD_VERSION 0.34.0)
if(CPM_SOURCE_CACHE)
    set(CPM_DOWNLOAD_LOCATION "${CPM_SOURCE_CACHE}/cpm/CPM_${CPM_DOWNLOAD_VERSION}.cmake")
elseif(DEFINED ENV{CPM_SOURCE_CACHE})
    set(CPM_DOWNLOAD_LOCATION "$ENV{CPM_SOURCE_CACHE}/cpm/CPM_${CPM_DOWNLOAD_VERSION}.cmake")
else()
    set(CPM_DOWNLOAD_LOCATION "${CMAKE_BINARY_DIR}/cmake/CPM_${CPM_DOWNLOAD_VERSION}.cmake")
endif()
if(NOT (EXISTS ${CPM_DOWNLOAD_LOCATION}))
    message(STATUS "Downloading CPM.cmake to ${CPM_DOWNLOAD_LOCATION}")
    file(DOWNLOAD
         https://github.com/TheLartians/CPM.cmake/releases/download/v${CPM_DOWNLOAD_VERSION}/CPM.cmake
         ${CPM_DOWNLOAD_LOCATION}
    )
endif()
include(${CPM_DOWNLOAD_LOCATION})

# --- pinned versions (names must match BDD's CPMAddPackage names) ---
CPMAddPackage("gh:taocpp/PEGTL#3.2.7")
CPMAddPackage("gh:CLIUtils/CLI11#v2.3.2")
CPMAddPackage("gl:libeigen/eigen#3.4.0")
CPMAddPackage("gh:Tessil/robin-map#v1.2.1")
CPMAddPackage("gh:NVIDIA/thrust#2.1.0")

# pybind11 and cereal are added by BDD with OPTIONS; replicate them so the
# first (pinned) add carries the same build settings.
CPMAddPackage(
    NAME pybind11
    GIT_TAG v2.11.1
    GITHUB_REPOSITORY pybind/pybind11
    OPTIONS
    "PYBIND11_CPP_STANDARD -std=c++17"
    "PYBIND11_INSTALL ON CACHE BOOL"
)

CPMAddPackage(
    NAME cereal
    GIT_TAG v1.3.2
    GITHUB_REPOSITORY USCiLab/cereal
    OPTIONS
    "BUILD_DOC OFF"
    "BUILD_SANDBOX OFF"
)
