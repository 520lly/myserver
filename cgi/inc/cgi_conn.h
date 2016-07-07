/*************************************************************************
	> File Name: cgi_conn.h
	> Author:wangjq 
	> Mail:WangJianQing@saicmotor.com 
	> Created Time: 2016年06月29日 星期三 16时10分03秒
 ************************************************************************/

#ifndef _CGI_CONN_H
#define _CGI_CONN_H

#include <sys/socket.h>
#include "common.h"

class CCgiConnection 
{

public:
    CCgiConnection();
    ~CCgiConnection();

    void init(int epollfd, int sockfd, const sockaddr_in &client_addr);
    void process();

private:
    int m_epollfd;
    int m_sockfd;
    sockaddr_in m_address;
    char m_buf[BUFFER_SIZE];
    int m_read_idx;
    int stop_child;

};


#endif

