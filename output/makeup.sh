#!/bin/bash
# encoding: utf-8
# Name  : makeup.sh
# Descp : used for 
# Author: jaycee
# Date  : 02/07/16 09:15:25
VER=0.1

function usage()
{
    echo "$basename [options -rm]
            -r : make and run
            -m : only make not run"
}

function clean()
{
    clear
    ctags -R ../
    echo "------------------------ delete old temporary files -------------------------"
    find ./ -type d -name "CMakeFiles" | xargs rm -rf
    find ./ -type f -name "*.cmake" | xargs rm -f
    find ./ -type f -name "Makefile" | xargs rm -f
    find ./ -type f -name "CMakeCache.txt" | xargs rm -f

    echo "------------------------ delete old executable files ------------------------"
    rm -f myserver
    rm -f test_client 
}

function makeonly()
{
    clean
    echo "------------------------ make new executable files ---------------------------"
    cmake ..
    make
}

function run()
{
    echo "--------------------------------- [ done ] -----------------------------------"
    ./myserver -f ../config.xml
}

if [ $# -eq 0 ]
then
    usage
else
    if [ $1 == "-r" ]
    then
        makeonly
        run 
    fi
    if [ $1 == "-m" ]
    then
        echo "make only"
        makeonly
    fi
fi

