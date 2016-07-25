#!/bin/bash
# encoding: utf-8
# Name  : makeup.sh
# Descp : used for make myserver and run myserver 
# Author: jaycee
# Date  : 02/07/16 09:15:25
VER=0.1
################################################################

function usage()
{
    echo "usage: `basename $0 .sh` [options -rma] 
            -h : help 
            -r : only run program 
            -m : only make not run 
            -c : clean old temporary files 
            -a : make and run"
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
    echo "--------------------------------- [ done ] -----------------------------------"
}

function run()
{
    ./myserver -f ../config.xml
}

if [ $# -eq 0 ]
then
    usage
fi

while getopts :hracm OPT; 
do
    case "$OPT" in
        h)
            usage
            ;;
        m)
            makeonly
            ;;
        r)
            run
            ;;
        a)
            makeonly
            run
            ;;
        c)
            clean
            ;;
        \?)
            usage
            ;;
    esac
done


