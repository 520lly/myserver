/*************************************************************************
	> File Name: common.h
	> Author: jaycee
	> Mail: jaycee_wjq@163.com
	> Created Time: 2016年07月01日 星期五 09时28分42秒
 ************************************************************************/

#ifndef _COMMON_H
#define _COMMON_H

#include <sys/socket.h>
#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <signal.h>
#include <string>

#include "log.h"

#define BUFFER_SIZE 1024

using std::string;

struct process_in_pool
{
    pid_t pid;
    int pipefd[2];
};

struct client_data
{
    sockaddr_in address;
    char buf[ BUFFER_SIZE ];
    int read_idx;
};

class host
{
public:
    char m_hostname[1024];
    int m_port;
    int m_conncnt;
};


class CCommon
{

public:
    static CCommon *getInstance();
    CCommon();
    ~CCommon();

    int setnonblocking( int fd );
    void addfd( int epollfd, int fd );
    void removefd( int epollfd, int fd );
    void sig_handler( int sig );
    void addsig( int sig, void(*handler)(int), bool restart = true );
    void del_resource();
    void show_error( int connfd, const char* info );
    void addfd( int epollfd, int fd, bool one_shot = false );
    void modfd( int epollfd, int fd, int ev );

    string url_encode(const string &url);
    string url_decode(const string &url);

private:
    char dechex2char(short int n);
    short int decchar2hex(char ch);



private:
    static CCommon *m_comm;
    char* ip_address;
    int port;
    int Connections;
    
};


#endif
