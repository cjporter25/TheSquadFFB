### CMakeLists.txt (What it is)
- Configuration Script
- Used by CMake
    - Cross-platform system generator

### CMakeLists.txt (What it does)
1. **Declares what source files to compile**
    - Source files include every file necessary for the project
      to run
2. **Declares what libraries to link against (Qt5 or SQLite)**
3. **Declares which C++ standard to use** 
    - Defines core language syntax/semantics
        - Will determine the overal behavior of standard library components
          such as std:vector, std::string, etc.
    - Ensures portability/predictability.
    - Newer standards may have different syntatic rules
- What the output binary name should be
- Where to find header files