cmake_minimum_required(VERSION 3.12)

# Pull in SDK (must be before project)
include(pico_sdk_import.cmake)

project(lcd-lib C CXX ASM)
set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)
set(PICO_NO_FLASH 1)
set(ENABLE_USB_UART 0)
add_definitions(-O0)

# Initialize the SDK
pico_sdk_init()

set(ENV_TARGET regexp02)
set(ENV_LINKER_SCRIPT memmap_no_flash_02.ld)
include(CMakeListsSub.txt)

if (1)
	set(ENV_TARGET regexp04)
	set(ENV_LINKER_SCRIPT memmap_no_flash_04.ld)
	include(CMakeListsSub.txt)
	
	set(ENV_TARGET regexp08)
	set(ENV_LINKER_SCRIPT memmap_no_flash_08.ld)
	include(CMakeListsSub.txt)

	set(ENV_TARGET regexp0c)
	set(ENV_LINKER_SCRIPT memmap_no_flash_0c.ld)
	include(CMakeListsSub.txt)

	set(ENV_TARGET regexp10)
	set(ENV_LINKER_SCRIPT memmap_no_flash_10.ld)
	include(CMakeListsSub.txt)
	
	set(ENV_TARGET regexp18)
	set(ENV_LINKER_SCRIPT memmap_no_flash_18.ld)
	include(CMakeListsSub.txt)

	set(ENV_TARGET regexp20)
	set(ENV_LINKER_SCRIPT memmap_no_flash_20.ld)
	include(CMakeListsSub.txt)
endif()
