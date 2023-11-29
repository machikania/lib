cmake_minimum_required(VERSION 3.12)

# Pull in SDK (must be before project)
include(pico_sdk_import.cmake)

project(lcd-lib C CXX ASM)
set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)

set(PICO_NO_FLASH 1)
add_definitions(-O1)

# Initialize the SDK
pico_sdk_init()

set(ENV_TARGET QRCODE10)
set(ENV_LINKER_SCRIPT memmap_no_flash10.ld)
include(CMakeListsSub.txt)

if (1)
	set(ENV_TARGET QRCODE02)
	set(ENV_LINKER_SCRIPT memmap_no_flash02.ld)
	include(CMakeListsSub.txt)

	set(ENV_TARGET QRCODE04)
	set(ENV_LINKER_SCRIPT memmap_no_flash04.ld)
	include(CMakeListsSub.txt)

	set(ENV_TARGET QRCODE08)
	set(ENV_LINKER_SCRIPT memmap_no_flash08.ld)
	include(CMakeListsSub.txt)

	set(ENV_TARGET QRCODE0C)
	set(ENV_LINKER_SCRIPT memmap_no_flash0c.ld)
	include(CMakeListsSub.txt)

	set(ENV_TARGET QRCODE18)
	set(ENV_LINKER_SCRIPT memmap_no_flash18.ld)
	include(CMakeListsSub.txt)

	set(ENV_TARGET QRCODE20)
	set(ENV_LINKER_SCRIPT memmap_no_flash20.ld)
	include(CMakeListsSub.txt)

endif()
