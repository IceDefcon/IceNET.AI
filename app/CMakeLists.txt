cmake_minimum_required(VERSION 3.10)
project(app LANGUAGES C CXX)

##########################################################################
# g++ -std=c++17
##########################################################################
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
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
add_library(cyusb SHARED
    lib/libcyusb.cpp
)

##########################################################################
# -fPIC
# -shared
# -Wl,-soname,libcyusb.so
##########################################################################
set_target_properties(cyusb PROPERTIES
    OUTPUT_NAME cyusb
    POSITION_INDEPENDENT_CODE ON
    VERSION 1.0
    SOVERSION 1
)

target_include_directories(cyusb PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/lib
)

##########################################################################
# -l usb-1.0 -l rt
##########################################################################
target_link_libraries(cyusb
    usb-1.0
    rt
)

##########################################################################
# Application
##########################################################################
add_executable(app
    main.cpp
    src/gui.cpp
    inc/gui.h
)

target_include_directories(app PRIVATE
    inc
    lib
)

target_link_libraries(app
    Qt5::Core
    Qt5::Gui
    Qt5::Widgets
    Threads::Threads
    cyusb
)
