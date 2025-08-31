## Initial C++ Setup
1. **Homebrew - install or ensure it's installed**
    - In terminal application
    - `brew --version -> should say 4.6.7+`
2. **Install CMake using Homebrew (MacOS)**
    - In terminal application
    - `brew install cmake`
    - `cmake --version`
3. **OR Download & Install CMake using Windows**
    - https://cmake.org/download/?utm_source=chatgpt.com
    - Check box to add to PATH
    - `cmake --version`
4. **Installing "Qt"**
    - `brew install qt`
5. **Retrieving qt PATH for CMake**
    - In terminal application
    - `brew --prefix qt@6`
    - Should output something like /opt/homebrew/opt/qt
6. **Give this path to CMake when initiating the build**
    - In VSCode terminal, in project folder, i.e. module_cpp/...
    - mkdir build && cd build (Creates and moves to a folder called build)
    - Auto: `cmake .. -DCMAKE_PREFIX_PATH=$(brew --prefix qt@6)`
    - Manual: `cmake .. -DCMAKE_PREFIX_PATH=/opt/homebrew/opt/qt`
7. **Build and Run the Application**
    - Ensure you're still in module_cpp/build/...
    - `cmake --build .`
    - `./TheSquadFFB_GUI`

## Fixing VSCode Errors
1. **Open command Palette**
    - Cmd+Shift+P
    - Select C/C++: Edit Configurations (UI)
    - Scroll down to the _Include Path_ section
2. **Install pkg-config**
    - `brew install pkg-config`
    - Used to find the Qt include library
2. **Add the Qt include directory**
    - `pkg-config --cflags Qt6Widgets`
    - Copy the output and remove anything other than the paths themselves
    - /opt/homebrew/lib/QtWidgets.framework/Headers
    - /opt/homebrew/lib/QtWidgets.framework
    - /opt/homebrew/lib/QtGui.framework/Headers
    - /opt/homebrew/lib/QtGui.framework
    - /opt/homebrew/lib/QtCore.framework/Headers
    - /opt/homebrew/lib/QtCore.framework
    - /opt/homebrew/share/qt/mkspecs/macx-clang
    - /opt/homebrew/include
    - Paste each one line, by line, in the section.
    - OR open the .json and do it manually

### CMakeLists.txt (What it is)
- Configuration Script
- Used by CMake
    - Cross-platform system generator

### CMakeLists.txt (What it contained and made work at the start)
cmake_minimum_required(VERSION 3.27)
project(TheSquadFFB_GUI VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Widgets)
qt_standard_project_setup()

include_directories(include)

add_executable(TheSquadFFB_GUI
    main.cpp
    src/MainWindow.cpp
    include/MainWindow.h
)
target_link_libraries(TheSquadFFB_GUI PRIVATE Qt6::Widgets)

### CMakeLists.txt (What it does)
1. **Declares what source files to compile**
    - Source files include every file necessary for the project
      to run
2. **Declares what libraries to link against (i.e. Qt5 or SQLite)**
    - Libraries are collections of pre-compiled code (funcs, classes, templates)
    - Can pre-declare data structs, algorithms, file I/O etc
    `Static Libraries` - _.lib/.a_
        - Compiled into the final binary during build time
    `Dyanamic Libraries` - _.dll/.so_
        - Loaded at runtime. Gives permission of shared use between programs
3. **Declares which C++ standard to use** 
    - Defines core language syntax/semantics
        - Will determine the overal behavior of standard library components
          such as std:vector, std::string, etc
    - Ensures portability/predictability
    - Newer standards may have different syntatic rules

4. **Declares what the output binary name should be**
    - The _output binary name_ is the name of the file created after code
      is compiled/linked. 
    - The output binary is the _executable_ a program produces
    - i.e. main.exe (Windows) or main (MacOS)
    - `Usage`
        - g++ main.cpp -o [output_name]
5. **Declares where to find header files**
    - Header files declare function sigs, class defs, constants, macros, templates
    - Do not contain function bodies
    - Enables modular code