# CMAKE generated file: DO NOT EDIT!
# Generated by "Unix Makefiles" Generator, CMake Version 3.17

# Delete rule output on recipe failure.
.DELETE_ON_ERROR:


#=============================================================================
# Special targets provided by cmake.

# Disable implicit rules so canonical targets will work.
.SUFFIXES:


# Disable VCS-based implicit rules.
% : %,v


# Disable VCS-based implicit rules.
% : RCS/%


# Disable VCS-based implicit rules.
% : RCS/%,v


# Disable VCS-based implicit rules.
% : SCCS/s.%


# Disable VCS-based implicit rules.
% : s.%


.SUFFIXES: .hpux_make_needs_suffix_list


# Suppress display of executed commands.
$(VERBOSE).SILENT:


# A target that is always out of date.
cmake_force:

.PHONY : cmake_force

#=============================================================================
# Set environment variables for the build.

# The shell in which to execute make rules.
SHELL = /bin/sh

# The CMake executable.
CMAKE_COMMAND = /usr/bin/cmake

# The command to remove a file.
RM = /usr/bin/cmake -E rm -f

# Escaping for special characters.
EQUALS = =

# The top-level source directory on which CMake was run.
CMAKE_SOURCE_DIR = /home/alxhoff/git/GitHub/bluepill-HID/cmake

# The top-level build directory on which CMake was run.
CMAKE_BINARY_DIR = /home/alxhoff/git/GitHub/bluepill-HID/cmake/build

# Utility rule file for debug.

# Include the progress variables for this target.
include CMakeFiles/debug.dir/progress.make

CMakeFiles/debug:
	openocd -c 'source [find interface/stlink-v2.cfg]' -c 'transport select hla_swd' -c 'source [find target/stm32f1x_stlink.cfg]' -c 'reset_config srst_nogate' >/dev/null 2&1 & sleep 2
	arm-none-eabi-gdb -tui -command=/home/alxhoff/git/GitHub/bluepill-HID/cmake/GDBCommands -se /home/alxhoff/git/GitHub/bluepill-HID/cmake/build/STM32F1_bluepill.elf
	killall -15 openocd

debug: CMakeFiles/debug
debug: CMakeFiles/debug.dir/build.make

.PHONY : debug

# Rule to build all files generated by this target.
CMakeFiles/debug.dir/build: debug

.PHONY : CMakeFiles/debug.dir/build

CMakeFiles/debug.dir/clean:
	$(CMAKE_COMMAND) -P CMakeFiles/debug.dir/cmake_clean.cmake
.PHONY : CMakeFiles/debug.dir/clean

CMakeFiles/debug.dir/depend:
	cd /home/alxhoff/git/GitHub/bluepill-HID/cmake/build && $(CMAKE_COMMAND) -E cmake_depends "Unix Makefiles" /home/alxhoff/git/GitHub/bluepill-HID/cmake /home/alxhoff/git/GitHub/bluepill-HID/cmake /home/alxhoff/git/GitHub/bluepill-HID/cmake/build /home/alxhoff/git/GitHub/bluepill-HID/cmake/build /home/alxhoff/git/GitHub/bluepill-HID/cmake/build/CMakeFiles/debug.dir/DependInfo.cmake --color=$(COLOR)
.PHONY : CMakeFiles/debug.dir/depend

