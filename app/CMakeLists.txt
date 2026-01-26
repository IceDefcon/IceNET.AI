cmake_minimum_required(VERSION 3.10)
project(app LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Enable Ninja-friendly flags
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

set(CMAKE_AUTOMOC ON)

# Qt Setup
find_package(Qt5 REQUIRED COMPONENTS Core Gui Widgets SerialPort)

# Source files
set(SOURCES
    main.cpp
    src/gui.cpp
)

# Header files (optional, but nice for IDEs)
set(HEADERS
    inc/gui.h
)

# Include directories
include_directories(
    inc
)

# Define the executable
add_executable(app ${SOURCES} ${HEADERS})

# Link Qt and OpenCV libraries
find_package(Threads REQUIRED)

target_link_libraries(app
    Qt5::Core
    Qt5::Gui
    Qt5::Widgets
    Qt5::SerialPort
    Threads::Threads
    ${OpenCV_LIBS}
)
