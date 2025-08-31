cmake_minimum_required(VERSION 3.27)

# Declare application versions here
project(TheSquadFFB_GUI VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Find the Qt6 package
find_package(Qt6 REQUIRED COMPONENTS Widgets)
qt_standard_project_setup()


# NEED - Include dirs containg header files or whatever directories
#   containing other libraries
include_directories(include)

# Add source files, must have full list
add_executable(TheSquadFFB_GUI
    main.cpp
    src/MainWindow.cpp
    include/MainWindow.h
)

# Link Qt libraries
target_link_libraries(TheSquadFFB_GUI PRIVATE Qt6::Widgets)
