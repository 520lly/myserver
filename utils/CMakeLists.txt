include_directories(./inc)

add_library(comm_objs OBJECT    src/common.cpp)
add_library(locker_objs OBJECT    src/locker.cpp)
add_library(log_objs OBJECT    src/log.cpp)
add_library(json_objs OBJECT    src/jsoncpp.cpp)
