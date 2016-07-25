cmake_minimum_required(VERSION 2.8)
project(myserver)

set(SYSTEM_ROOT /.)
set(PROJECT_ROOT /home/jaycee/mycode/server/C/server/myserver)
set(CMAKE_BUILD_TYPE ${CMAKE_CXX_FLAGS_DEBUG})

#add_definitions(-DCGI_SERVER)
add_definitions(-DHTTP_SERVER)
add_definitions(-DXEA_DEBUG)

include_directories(${SYSTEM_ROOT}/usr/lib/x86_64-linux-gnu/glib-2.0/include)
include_directories(${SYSTEM_ROOT}/usr/local/include/Poco)
include_directories(${SYSTEM_ROOT}/usr/include/Poco)
include_directories(${SYSTEM_ROOT}/usr/local/include/mongo)
include_directories(${SYSTEM_ROOT}/usr/local/include)

link_directories(${SYSTEM_ROOT}/usr/local/lib)
link_directories(${SYSTEM_ROOT}/usr/include/lib)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -DNULL=0 -Wno-errors")

add_executable(myserver $<TARGET_OBJECTS:comm_objs>
                        $<TARGET_OBJECTS:cgi_objs>
                        $<TARGET_OBJECTS:locker_objs>
                        $<TARGET_OBJECTS:http_objs>
                        $<TARGET_OBJECTS:log_objs>
                        $<TARGET_OBJECTS:json_objs>
                        $<TARGET_OBJECTS:mongodb_objs>
                        $<TARGET_OBJECTS:main_objs>)

add_executable(test_client $<TARGET_OBJECTS:test_objs>)

target_link_libraries(myserver PocoFoundation z pthread mongoclient boost_thread boost_filesystem boost_system boost_regex ssl crypto)  

set(executable_output_path ${PROJECT_BINARY_DIR}/bin)
install(TARGETS myserver RUNTIME DESTINATION ${PROJECT_BINARY_DIR}/bin)
install(TARGETS test_client RUNTIME DESTINATION ${PROJECT_BINARY_DIR}/bin)
if (${CMAKE_BUILD_TYPE} STREQUAL ${CMAKE_CXX_FLAGS_DEBUG}) 
    message("-- Build type is: debug")
else()
    message("-- Build type is: release")
endif()


add_subdirectory(cgi)
add_subdirectory(http)
add_subdirectory(pool)
add_subdirectory(utils)
add_subdirectory(db)
add_subdirectory(main)
add_subdirectory(test)

