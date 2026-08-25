cmake_minimum_required(VERSION 3.14)
project(runner LANGUAGES CXX)

# Define the application target. To change its name, change BINARY_NAME in the
# top-level CMakeLists.txt, not the value here, or `flutter run` will no longer
# work.
#
# Any new source files that you add to the application should be added here.
add_executable(${BINARY_NAME} WIN32
  "flutter_window.cpp"
  "main.cpp"
  "utils.cpp"
  "win32_window.cpp"
  "yfsp_browser.cpp"
  "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
  "Runner.rc"
  "runner.exe.manifest"
)

# Apply the standard set of build settings. This can be removed for applications
# that need different build settings.
apply_standard_settings(${BINARY_NAME})

# Add preprocessor definitions for the build version.
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION=\"${FLUTTER_VERSION}\"")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_MAJOR=${FLUTTER_VERSION_MAJOR}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_MINOR=${FLUTTER_VERSION_MINOR}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_PATCH=${FLUTTER_VERSION_PATCH}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_BUILD=${FLUTTER_VERSION_BUILD}")

# Disable Windows macros that collide with C++ standard library functions.
target_compile_definitions(${BINARY_NAME} PRIVATE "NOMINMAX")

# Add dependency libraries and include directories. Add any application-specific
# dependencies here.
target_link_libraries(${BINARY_NAME} PRIVATE flutter flutter_wrapper_app)
target_link_libraries(${BINARY_NAME} PRIVATE "dwmapi.lib")
target_include_directories(${BINARY_NAME} PRIVATE "${CMAKE_SOURCE_DIR}")

# --- WebView2 SDK, for the yfsp browser transport (yfsp_browser.cpp) ---------
# Restored from NuGet at configure time. Needs network access on the first
# Windows build; the package then caches under the build tree.
set(WEBVIEW2_VERSION "1.0.2210.55")
find_program(NUGET_EXE NAMES nuget)
if(NOT NUGET_EXE)
  set(NUGET_EXE "${CMAKE_BINARY_DIR}/nuget.exe")
  if(NOT EXISTS "${NUGET_EXE}")
    message(STATUS "Downloading nuget.exe for the WebView2 SDK")
    file(DOWNLOAD "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe"
         "${NUGET_EXE}")
  endif()
endif()
execute_process(
  COMMAND "${NUGET_EXE}" install "Microsoft.Web.WebView2"
          -Version "${WEBVIEW2_VERSION}" -ExcludeVersion
          -OutputDirectory "${CMAKE_BINARY_DIR}/packages"
  WORKING_DIRECTORY "${CMAKE_BINARY_DIR}")
set(WEBVIEW2_DIR "${CMAKE_BINARY_DIR}/packages/Microsoft.Web.WebView2")

# Map the CMake platform onto WebView2's native lib folder.
if(CMAKE_GENERATOR_PLATFORM STREQUAL "Win32")
  set(WEBVIEW2_ARCH "x86")
elseif(CMAKE_GENERATOR_PLATFORM STREQUAL "ARM64")
  set(WEBVIEW2_ARCH "arm64")
else()
  set(WEBVIEW2_ARCH "x64")
endif()

target_include_directories(${BINARY_NAME} PRIVATE
  "${WEBVIEW2_DIR}/build/native/include")
target_link_libraries(${BINARY_NAME} PRIVATE
  "${WEBVIEW2_DIR}/build/native/${WEBVIEW2_ARCH}/WebView2LoaderStatic.lib")
# The static loader and WRL callbacks pull these in.
target_link_libraries(${BINARY_NAME} PRIVATE "version.lib" "shlwapi.lib")

# Run the Flutter tool portions of the build. This must not be removed.
add_dependencies(${BINARY_NAME} flutter_assemble)
