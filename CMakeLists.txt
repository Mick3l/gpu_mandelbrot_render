cmake_minimum_required(VERSION 3.15)
project(GPU CUDA)

set(CMAKE_CUDA_STANDARD 17)
set(CMAKE_CXX_STANDARD 17)

add_executable(cuda WIN32 main.cu)

add_subdirectory(lib)

target_link_libraries(cuda PRIVATE direct2d -ld2d1 -lOpenGL32 -lfreeGLUT)

set_target_properties(cuda PROPERTIES
        CUDA_SEPARABLE_COMPILATION ON)
