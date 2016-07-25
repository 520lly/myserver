include_directories(./inc)
include_directories(../utils/inc)
include_directories(../db/inc)

add_library(http_objs OBJECT    src/http_conn.cpp)
