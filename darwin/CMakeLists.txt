cmake_minimum_required(VERSION 3.16)
project(ProcLaunchHook)

# get the millennium version from version file
file(STRINGS "${CMAKE_SOURCE_DIR}/version" VERSION_LINES LIMIT_COUNT 2)
list(GET VERSION_LINES 1 MILLENNIUM_VERSION)
set(MILLENNIUM_VERSION "${MILLENNIUM_VERSION}")

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_OBJCXX_FLAGS "${CMAKE_OBJCXX_FLAGS} -fobjc-arc")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-deprecated-declarations")

# Add include directory
include_directories(include)

# Add sources
set(SOURCES
    src/main.mm
    src/watchdog.mm
    src/exec.mm
)

set_source_files_properties(
    src/watchdog.mm
    PROPERTIES
    COMPILE_FLAGS "-fobjc-arc"
)

# Set up the app icon first
set(APP_ICON_PATH "${CMAKE_SOURCE_DIR}/darwin/AppIcon.icns")
if(EXISTS ${APP_ICON_PATH})
    # Add icon to sources
    list(APPEND SOURCES ${APP_ICON_PATH})
    message(STATUS "Found AppIcon.icns at ${APP_ICON_PATH}")
else()
    message(WARNING "AppIcon.icns not found at ${APP_ICON_PATH}. Bundle will be created without an icon.")
endif()

# Add the executable as a macOS bundle
add_executable(${PROJECT_NAME} MACOSX_BUNDLE ${SOURCES})

target_link_libraries(${PROJECT_NAME} 
    "-framework Foundation"
    "-framework AppKit"
    "-framework UserNotifications"
)

# Configure the app icon in the bundle
if(EXISTS ${APP_ICON_PATH})
    set_source_files_properties(${APP_ICON_PATH} PROPERTIES
        MACOSX_PACKAGE_LOCATION "Resources"
    )
endif()

# Set bundle properties on the target
set_target_properties(${PROJECT_NAME} PROPERTIES
    MACOSX_BUNDLE TRUE
    MACOSX_BUNDLE_BUNDLE_NAME "Millennium"
    MACOSX_BUNDLE_BUNDLE_VERSION "${MILLENNIUM_VERSION}"
    MACOSX_BUNDLE_SHORT_VERSION_STRING "${MILLENNIUM_VERSION}"
    MACOSX_BUNDLE_LONG_VERSION_STRING "${MILLENNIUM_VERSION}"
    MACOSX_BUNDLE_IDENTIFIER "com.steamhomebrew.millennium"
    MACOSX_BUNDLE_GUI_IDENTIFIER "com.steamhomebrew.millennium"
    MACOSX_BUNDLE_ICON_FILE "AppIcon"
    MACOSX_BUNDLE_INFO_STRING "Millennium ${MILLENNIUM_VERSION}"
    MACOSX_BUNDLE_COPYRIGHT "Copyright © 2025 Steam Client Homebrew"
    MACOSX_BUNDLE_EXECUTABLE_NAME "Millennium"
    MACOSX_BUNDLE_INFO_PLIST "${CMAKE_SOURCE_DIR}/darwin/Info.plist.in"
    OUTPUT_NAME "Millennium"
)

# Force Info.plist generation if template doesn't exist
if(NOT EXISTS "${CMAKE_SOURCE_DIR}/darwin/Info.plist.in")
    message(STATUS "Creating Info.plist.in template")
    configure_file(
        "${CMAKE_ROOT}/Modules/MacOSXBundleInfo.plist.in"
        "${CMAKE_BINARY_DIR}/Info.plist.in"
        @ONLY
    )
    set_target_properties(${PROJECT_NAME} PROPERTIES
        MACOSX_BUNDLE_INFO_PLIST "${CMAKE_BINARY_DIR}/Info.plist.in"
    )
endif()

# Manual icon copy to ensure it's in the bundle
if(EXISTS ${APP_ICON_PATH})
    add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E make_directory
        "$<TARGET_BUNDLE_DIR:${PROJECT_NAME}>/Contents/Resources"
        COMMAND ${CMAKE_COMMAND} -E copy
        ${APP_ICON_PATH}
        "$<TARGET_BUNDLE_DIR:${PROJECT_NAME}>/Contents/Resources/AppIcon.icns"
        COMMENT "Copying AppIcon.icns to bundle"
    )
endif()