cmake_minimum_required(VERSION 3.12)
project(app LANGUAGES C CXX)

##########################################################################
# g++ -std=c++17
##########################################################################
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)
set(CMAKE_AUTOMOC ON)

##########################################################################
# Dependencies
##########################################################################
find_package(Qt5 REQUIRED COMPONENTS Core Gui Widgets)
find_package(Threads REQUIRED)

##########################################################################
# g++ -fPIC -c libcyusb.cpp
# g++ -shared ...
##########################################################################
set(CYUSB_SOURCES
    lib/libcyusb.cpp
)

add_library(cyusb SHARED
    ${CYUSB_SOURCES}
)

##########################################################################
# -fPIC
# -shared
# -Wl,-soname,libcyusb.so
##########################################################################
set_target_properties(cyusb PROPERTIES
    OUTPUT_NAME cyusb
    VERSION 1.0
    SOVERSION 1
)

target_include_directories(cyusb PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/lib
)

##########################################################################
# -l usb-1.0 -l rt
##########################################################################
target_link_libraries(cyusb PUBLIC
    usb-1.0
    rt
)

##########################################################################
# Application
##########################################################################
set(APP_SOURCES
    main.cpp
    src/console.cpp
    src/device.cpp
    src/gui.cpp
)

set(APP_HEADERS
    inc/gui.h        # needed for Qt AUTOMOC (Q_OBJECT)
    inc/console.h
    inc/device.h
)

add_executable(app
    ${APP_SOURCES}
    ${APP_HEADERS}
)

target_include_directories(app PRIVATE
    inc
    lib
)

target_link_libraries(app PRIVATE
    Qt5::Core
    Qt5::Gui
    Qt5::Widgets
    Threads::Threads
    cyusb
)
