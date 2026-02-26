cmake_minimum_required(VERSION 3.23 FATAL_ERROR)

cmake_policy(SET CMP0144 NEW)

set_property(GLOBAL PROPERTY USE_FOLDERS ON)
list(INSERT CMAKE_MODULE_PATH 0 ${CMAKE_CURRENT_SOURCE_DIR}/CMake)

option(HUNTER_ENABLED "Enable Hunter package manager support." ON)

if(HUNTER_ENABLED)
	include(Hunter/HunterInit)
endif()

project(open-vcdiff VERSION 0.8.4 LANGUAGES CXX C)

if(HUNTER_ENABLED)
	include(ThirdPartyLibraries)
endif()

# For config.h.in to avoid generic define
set(OPEN_VCDIFF_VERSION ${PROJECT_VERSION})
set(PROJECT_SOVERSION 0)

# Configuration options
option(vcdiff_build_exec "Build vcdiff executable" OFF)
option(BUILD_TESTING "Enable build of the unit tests and their execution using CTest." OFF)

# Copy value. We'll override BUILD_TESTING for subprojects
set(vcdiff_build_tests ${BUILD_TESTING})

if(vcdiff_build_exec)
	set(BUILD_TESTING OFF)
endif()

include(CheckIncludeFiles)
check_include_files(ext/rope HAVE_EXT_ROPE)
check_include_files(getopt.h HAVE_GETOPT_H)
check_include_files(malloc.h HAVE_MALLOC_H)
check_include_files(sys/mman.h HAVE_SYS_MMAN_H)
check_include_files(sys/time.h HAVE_SYS_TIME_H)
check_include_files(unistd.h HAVE_UNISTD_H)
check_include_files(windows.h HAVE_WINDOWS_H)

include(CheckFunctionExists)
check_function_exists(gettimeofday HAVE_GETTIMEOFDAY)
check_function_exists(memalign HAVE_MEMALIGN)
check_function_exists(posix_memalign HAVE_POSIX_MEMALIGN)
check_function_exists(mprotect HAVE_MPROTECT)

configure_file(${PROJECT_SOURCE_DIR}/src/config.h.in ${PROJECT_SOURCE_DIR}/src/config.h)

set(VCDCOM_HDR
	"src/google/codetablewriter_interface.h"
	"src/google/encodetable.h"
	"src/google/encodetable.h"
	"src/google/format_extension_flags.h"
	"src/google/jsonwriter.h"
	"src/google/output_string.h"
)

set(VCDCOM_SRC
	"src/google/format_extension_flags.h"
	"src/google/output_string.h"
	"src/addrcache.h"
	"src/checksum.h"
	"src/codetable.h"
	"src/logging.h"
	"src/unique_ptr.h"
	"src/varint_bigendian.h"
	"src/vcdiff_defs.h"
	"src/zlib/zlib.h"
	"src/zlib/zconf.h"
	"src/zlib/adler32.c"
	"src/addrcache.cc"
	"src/codetable.cc"
	"src/logging.cc"
	"src/varint_bigendian.cc"
)

set(VCDDEC_HDR
	"src/google/vcdecoder.h"
)

set(VCDDEC_SRC
	"src/decodetable.cc"
	"src/headerparser.cc"
	"src/vcdecoder.cc"
)

set(VCDENC_HDR
	"src/google/vcencoder.h"
)

set(VCDENC_SRC
	"src/blockhash.cc"
	"src/encodetable.cc"
	"src/instruction_map.cc"
	"src/jsonwriter.cc"
	"src/vcdiffengine.cc"
	"src/vcencoder.cc"
)

# Common Library
add_library(vcdcom ${VCDCOM_SRC})

target_sources(vcdcom
	PUBLIC
		FILE_SET HEADERS
		TYPE HEADERS
		BASE_DIRS
			${CMAKE_CURRENT_SOURCE_DIR}/src
		FILES
			${VCDCOM_HDR}
)

target_include_directories(vcdcom
	PUBLIC
		$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src>
		$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src/zlib>
		$<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
)

set_target_properties(vcdcom PROPERTIES
	OUTPUT_NAME vcdcom
	VERSION ${OPEN_VCDIFF_VERSION}
	SOVERSION ${PROJECT_SOVERSION}
)

target_compile_features(vcdcom
	PUBLIC
		c_std_99
		cxx_std_11
)

# Decoder Library
add_library(vcddec ${VCDDEC_SRC})

target_sources(vcddec
	PUBLIC
		FILE_SET HEADERS
		TYPE HEADERS
		BASE_DIRS
			${CMAKE_CURRENT_SOURCE_DIR}/src
		FILES
			${VCDDEC_HDR}
)

target_include_directories(vcddec
	PUBLIC
		$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src>
		$<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
)

set_target_properties(vcddec PROPERTIES
	OUTPUT_NAME vcddec
	VERSION ${OPEN_VCDIFF_VERSION}
	SOVERSION ${PROJECT_SOVERSION}
)

target_compile_features(vcddec
	PUBLIC
		c_std_99
		cxx_std_11
)

target_link_libraries(vcddec PUBLIC vcdcom)

# Encoder Library
add_library(vcdenc ${VCDENC_SRC})

target_sources(vcdenc
	PUBLIC
		FILE_SET HEADERS
		TYPE HEADERS
		BASE_DIRS
			${CMAKE_CURRENT_SOURCE_DIR}/src
		FILES
			${VCDENC_HDR}
)

target_include_directories(vcdenc
	PUBLIC
		$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src>
		$<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
)

set_target_properties(vcdenc PROPERTIES
	OUTPUT_NAME vcdenc
	VERSION ${OPEN_VCDIFF_VERSION}
	SOVERSION ${PROJECT_SOVERSION}
)

target_compile_features(vcdenc
	PUBLIC
		c_std_99
		cxx_std_11
)

target_link_libraries(vcdenc PUBLIC vcdcom)

if(vcdiff_build_exec)
	add_executable(vcdiff "src/vcdiff_main.cc")
	target_link_libraries(vcdiff vcddec vcdenc gflags)
	install(TARGETS vcdiff DESTINATION bin)
	install(FILES man/vcdiff.1 DESTINATION ${CMAKE_INSTALL_PREFIX}/share/man/man1)
endif()

if(vcdiff_build_tests)
	enable_testing()

	add_executable(addrcache_test src/addrcache_test.cc)
	target_link_libraries(addrcache_test vcdcom GTest::gtest GTest::gtest_main)
	add_test(addrcache_test addrcache_test)

	add_executable(blockhash_test src/blockhash_test.cc)
	target_link_libraries(blockhash_test vcdenc GTest::gtest GTest::gtest_main)
	add_test(blockhash_test blockhash_test)

	add_executable(codetable_test src/codetable_test.cc)
	target_link_libraries(codetable_test vcdcom GTest::gtest GTest::gtest_main)
	add_test(codetable_test codetable_test)

	add_executable(decodetable_test src/decodetable_test.cc)
	target_link_libraries(decodetable_test vcddec vcdcom GTest::gtest GTest::gtest_main)
	add_test(decodetable_test decodetable_test)

	add_executable(encodetable_test src/encodetable_test.cc)
	target_link_libraries(encodetable_test vcdenc vcdcom GTest::gtest GTest::gtest_main)
	add_test(encodetable_test encodetable_test)

	add_executable(headerparser_test src/headerparser_test.cc)
	target_link_libraries(headerparser_test vcddec vcdcom GTest::gtest GTest::gtest_main)
	add_test(headerparser_test headerparser_test)

	add_executable(instruction_map_test src/instruction_map_test.cc)
	target_link_libraries(instruction_map_test vcdenc vcdcom GTest::gtest GTest::gtest_main)
	add_test(instruction_map_test instruction_map_test)

	add_executable(output_string_test src/output_string_test.cc)
	target_include_directories(output_string_test PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/src)
	target_link_libraries(output_string_test GTest::gtest GTest::gtest_main)
	add_test(output_string_test output_string_test)

	add_executable(rolling_hash_test src/rolling_hash_test.cc)
	target_link_libraries(rolling_hash_test vcdcom GTest::gtest GTest::gtest_main)
	add_test(rolling_hash_test rolling_hash_test)

	add_executable(varint_bigendian_test src/varint_bigendian_test.cc)
	target_link_libraries(varint_bigendian_test vcdcom GTest::gtest GTest::gtest_main)
	add_test(varint_bigendian_test varint_bigendian_test)

	add_executable(vcdecoder1_test src/vcdecoder1_test.cc src/vcdecoder_test.cc)
	target_link_libraries(vcdecoder1_test vcddec GTest::gtest GTest::gtest_main)
	add_test(vcdecoder1_test vcdecoder1_test)

	add_executable(vcdecoder2_test src/vcdecoder2_test.cc src/vcdecoder_test.cc)
	target_link_libraries(vcdecoder2_test vcddec GTest::gtest GTest::gtest_main)
	add_test(vcdecoder2_test vcdecoder2_test)

	add_executable(vcdecoder3_test src/vcdecoder3_test.cc src/vcdecoder_test.cc)
	target_link_libraries(vcdecoder3_test vcddec GTest::gtest GTest::gtest_main)
	add_test(vcdecoder3_test vcdecoder3_test)

	add_executable(vcdecoder4_test src/vcdecoder4_test.cc src/vcdecoder_test.cc)
	target_link_libraries(vcdecoder4_test vcddec GTest::gtest GTest::gtest_main)
	add_test(vcdecoder4_test vcdecoder4_test)

	add_executable(vcdecoder5_test src/vcdecoder5_test.cc src/vcdecoder_test.cc)
	target_link_libraries(vcdecoder5_test vcddec GTest::gtest GTest::gtest_main)
	add_test(vcdecoder5_test vcdecoder5_test)

	add_executable(vcdiffengine_test src/vcdiffengine_test.cc)
	target_link_libraries(vcdiffengine_test vcdenc vcdcom GTest::gtest GTest::gtest_main)
	add_test(vcdiffengine_test vcdiffengine_test)

	add_executable(vcencoder_test src/vcencoder_test.cc)
	target_link_libraries(vcencoder_test vcddec vcdenc vcdcom GTest::gtest GTest::gtest_main)
	add_test(vcencoder_test vcencoder_test)

	add_executable(jsonwriter_test src/jsonwriter_test.cc)
	target_link_libraries(jsonwriter_test vcdenc vcdcom GTest::gtest GTest::gtest_main)
	add_test(jsonwriter_test jsonwriter_test)

	if(${UNIX})
		add_test(
			NAME vcdiff_test
			COMMAND ${PROJECT_SOURCE_DIR}/src/vcdiff_test.sh ${PROJECT_SOURCE_DIR})
	elseif(${WINDOWS})
		add_test(
			NAME vcdiff_test
			COMMAND ${PROJECT_SOURCE_DIR}/src/vcdiff_test.bat vcdiff)
	endif()
endif()

include(GNUInstallDirs)

set(CONFIG_INSTALL_DIR "${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME}")
set(GENERATED_DIR "${CMAKE_CURRENT_BINARY_DIR}/generated")
set(VERSION_CONFIG "${GENERATED_DIR}/${PROJECT_NAME}ConfigVersion.cmake")
set(PROJECT_CONFIG "${GENERATED_DIR}/${PROJECT_NAME}Config.cmake")
set(TARGETS_EXPORT_NAME "${PROJECT_NAME}Targets")
set(NAMESPACE "${PROJECT_NAME}::")

include(CMakePackageConfigHelpers)

write_basic_package_version_file(
	"${VERSION_CONFIG}" COMPATIBILITY SameMajorVersion
)

configure_package_config_file(
	"CMake/Config.cmake.in"
	"${PROJECT_CONFIG}"
	INSTALL_DESTINATION "${CONFIG_INSTALL_DIR}"
)

set(INSTALL_TARGETS
	vcdcom
	vcdenc
	vcddec
)

install(
	TARGETS ${INSTALL_TARGETS}
	EXPORT "${TARGETS_EXPORT_NAME}"
	LIBRARY DESTINATION "${CMAKE_INSTALL_LIBDIR}"
	ARCHIVE DESTINATION "${CMAKE_INSTALL_LIBDIR}"
	RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}"
	FILE_SET HEADERS
		DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}"
)

install(
	FILES "${PROJECT_CONFIG}" "${VERSION_CONFIG}"
	DESTINATION "${CONFIG_INSTALL_DIR}"
)

install(
	EXPORT "${TARGETS_EXPORT_NAME}"
	NAMESPACE "${NAMESPACE}"
	DESTINATION "${CONFIG_INSTALL_DIR}"
)
