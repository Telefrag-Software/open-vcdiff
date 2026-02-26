include_guard()

hunter_config(gflags
	URL "https://codeload.github.com/gflags/gflags/zip/tags/v2.3.0"
	VERSION "2.3.0"
	SHA1 "a907bf7925e6ced28ee36a315f9bb3b2eb61e962"
	CMAKE_ARGS
		GFLAGS_IS_A_DLL=OFF
		GFLAGS_NAMESPACE=google
		GFLAGS_BUILD_SHARED_LIBS=OFF
		GFLAGS_BUILD_STATIC_LIBS=ON
		GFLAGS_BUILD_gflags_LIB=OFF
		GFLAGS_BUILD_gflags_nothreads_LIB=ON
		GFLAGS_BUILD_TESTING=OFF
		GFLAGS_BUILD_PACKAGING=ON
		GFLAGS_INSTALL_HEADERS=ON
		GFLAGS_INSTALL_SHARED_LIBS=OFF
		GFLAGS_INSTALL_STATIC_LIBS=ON
		GFLAGS_EXPORT_NAMESPACE_SET=ON
)

hunter_config(GTest
	URL "https://codeload.github.com/google/googletest/zip/tags/v1.17.0"
	VERSION "1.17.0.0"
	SHA1 "c9cd451f89c5d5869ba7fa88efa3c9d91db628ad"
)
