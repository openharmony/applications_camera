# the minimum version of CMake.
cmake_minimum_required(VERSION 3.5.0)
project(Camera)

set(NATIVERENDER_ROOT_PATH ${CMAKE_CURRENT_SOURCE_DIR})
set(CMAKE_SKIP_RPATH TRUE)

add_compile_options(-fstack-protector-strong -D_FORTIFY_SOURCE=2 -O2 -fPIC)
add_link_options(-Wl,-z,relro,-z,now,-z,noexecstack -s)

if(DEFINED PACKAGE_FIND_FILE)
    include(${PACKAGE_FIND_FILE})
endif()

include_directories(
    ${NATIVERENDER_ROOT_PATH}
    ${NATIVERENDER_ROOT_PATH}/include
    ${NATIVERENDER_ROOT_PATH}/rouletteZoom
)


# UI主线程-NativeFunction-libappnative.so
add_library(appnative SHARED
    napi_init.cpp
    rouletteZoom/native_bridge.cpp
    rouletteZoom/native_node.cpp
    rouletteZoom/zoom_struct.cpp
    rouletteZoom/zoom_calculate.cpp
)

target_link_libraries(appnative PUBLIC
    libace_napi.z.so
    libace_ndk.z.so
    libhilog_ndk.z.so
    libhitrace_ndk.z.so
    libnative_window.so
    native_window.so
    libnative_drawing.so
    libpixelmap_ndk.z.so

    libimage_source_ndk.z.so
    libnative_buffer.so
    libohimage.so
    libimage_effect.so
    libimage_receiver.so
    libnative_image.so
    libpixelmap.so
)


target_link_options(appnative PRIVATE -s)




