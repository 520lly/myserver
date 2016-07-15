cmake_minimum_required(VERSION 2.8)
project(myserver)

set(SYSTEM_ROOT /.)
set(PROJECT_ROOT ~/mycode/server/C/server/myserver)

#add_definitions(-DCGI_SERVER)
add_definitions(-DHTTP_SERVER)
add_definitions(-DXEA_DEBUG)

include_directories(${SYSTEM_ROOT}/usr/lib/x86_64-linux-gnu/glib-2.0/include)
include_directories(${SYSTEM_ROOT}/usr/local/include/Poco)
include_directories(${SYSTEM_ROOT}/usr/include/Poco)

link_directories(${SYSTEM_ROOT}/usr/lib)
link_directories(${SYSTEM_ROOT}/usr/local/lib)
link_directories(${SYSTEM_ROOT}/usr/include/lib)
message("${SYSTEM_ROOT}/usr/local/lib")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11 -DNULL=0 -Wno-errors")

add_executable(myserver $<TARGET_OBJECTS:comm_objs>
                        $<TARGET_OBJECTS:cgi_objs>
                        $<TARGET_OBJECTS:locker_objs>
                        $<TARGET_OBJECTS:http_objs>
                        $<TARGET_OBJECTS:log_objs>
                        $<TARGET_OBJECTS:json_objs>
                        $<TARGET_OBJECTS:main_objs>)

add_executable(test_client $<TARGET_OBJECTS:test_objs>)

target_link_libraries(myserver pthread)  

set(executable_output_path ${PROJECT_BINARY_DIR}/bin)
install(TARGETS myserver RUNTIME DESTINATION ${PROJECT_BINARY_DIR}/bin)
install(TARGETS test_client RUNTIME DESTINATION ${PROJECT_BINARY_DIR}/bin)


add_subdirectory(cgi)
add_subdirectory(http)
add_subdirectory(pool)
add_subdirectory(utils)
add_subdirectory(main)
add_subdirectory(test)

