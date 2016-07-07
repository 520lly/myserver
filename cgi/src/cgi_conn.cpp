#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <assert.h>
#include <stdio.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <fcntl.h>
#include <stdlib.h>
#include <sys/epoll.h>
#include <signal.h>
#include <sys/wait.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <fcntl.h>

#include "cgi_conn.h"

CCgiConnection::~CCgiConnection()
{

}

CCgiConnection::CCgiConnection() 
    : stop_child(false)
{

}

void CCgiConnection::init(int epollfd, int sockfd, const sockaddr_in &client_addr)
{
    m_epollfd = epollfd;
    m_sockfd = sockfd;
    m_address = client_addr;
    memset( m_buf, '\0', BUFFER_SIZE );
    m_read_idx = 0;
}

void CCgiConnection::process()
{
    int idx = 0;
    int ret = -1;

    while(!stop_child)
    {
        idx = m_read_idx;
        ret = recv(m_sockfd, m_buf + idx, BUFFER_SIZE - 1 - idx, 0);
        //if opreation error ,then close server connecion ,if nothing to read currently ,then quit loop
        if(ret < 0)
        {
            if(errno != EAGAIN)
            {
                CCommon::getInstance()->removefd(m_epollfd, m_sockfd);
            }
            break;
        }
        //if client close connecion, then close server connecion
        else if(ret == 0)
        {
            CCommon::getInstance()->removefd(m_epollfd, m_sockfd);
            break;
        }
        else
        {
            m_read_idx += ret;
            printf("user content is :\n %s \n", m_buf);
            //received '\r\n' start to handlle clear data
            for(;idx < m_read_idx; ++idx)
            {
                if((idx >= -1) && (m_buf[idx -1 ] == '\r') && (m_buf[idx] == '\n'))
                {
                    break;
                }
            }
        }
        //if not received '\r\n' then read more client data
        if(idx == m_read_idx)
        {
            continue;
        }
        m_buf[idx -1] = '\0';

        char *file_name = m_buf;
        //check if the CGI server exit, which client request
        if( access(file_name, F_OK) == -1 )
        {
            printf("file %s not accessable\n", file_name);
            CCommon::getInstance()->removefd(m_epollfd, m_sockfd);
            break;
        }
        //fork child process to excute CGI server
        ret = fork();
        if(ret == -1)
        {
            printf("fork failure \n");
            CCommon::getInstance()->removefd(m_epollfd, m_sockfd);
            break;
        }
        else if( ret > 0 )
        {
            //only close parent connecion
            printf("close parent connecion \n");
            CCommon::getInstance()->removefd(m_epollfd, m_sockfd);
            break;
        }
        else
        {
            //child process redirect std output to m_sockfd and excute CGI server
            printf("execute CGI script \n");
            close(STDOUT_FILENO);
            dup(m_sockfd);
            //to do client request and response to client
            execl(m_buf, m_buf, (char *)0);
            printf("system execute result \n");
            exit(0);
        }
    }
}



