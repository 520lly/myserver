/*************************************************************************
	> File Name: ../src/common.cpp
	> Author: jaycee
	> Mail: jaycee_wjq@163.com
	> Created Time: 2016年07月01日 星期五 10时01分57秒
 ************************************************************************/

#include "common.h"
#include <fcntl.h>
#include <sys/epoll.h>
#include <errno.h>
#include <assert.h>



CCommon *CCommon::m_comm = nullptr;

CCommon *CCommon::getInstance()
{
    if(nullptr == m_comm)
    {
        m_comm = new CCommon();
        return m_comm;
    }
}

CCommon::CCommon()
{

}

CCommon::~CCommon()
{
    if(nullptr != m_comm)
    {
        delete m_comm;
        m_comm = nullptr;
    }
}

int CCommon::setnonblocking( int fd )
{
    int old_option = fcntl( fd, F_GETFL );
    int new_option = old_option | O_NONBLOCK;
    fcntl( fd, F_SETFL, new_option );
    return old_option;
}

void CCommon::addfd( int epollfd, int fd )
{
    epoll_event event;
    event.data.fd = fd;
    event.events = EPOLLIN | EPOLLET;
    epoll_ctl( epollfd, EPOLL_CTL_ADD, fd, &event );
    setnonblocking( fd );
}

void CCommon::addsig( int sig, void(*handler)(int), bool restart)
{
    struct sigaction sa;
    memset( &sa, '\0', sizeof( sa ) );
    sa.sa_handler = handler;
    if( restart )
    {
        sa.sa_flags |= SA_RESTART;
    }
    sigfillset( &sa.sa_mask );
    assert( sigaction( sig, &sa, NULL ) != -1 );
}

void CCommon::removefd( int epollfd, int fd )
{
    epoll_ctl( epollfd, EPOLL_CTL_DEL, fd, 0 );
    close( fd );
}

void CCommon::show_error( int connfd, const char* info )
{
    printf( "%s", info );
    send( connfd, info, strlen( info ), 0 );
    close( connfd );
}

void CCommon::addfd( int epollfd, int fd, bool one_shot )
{
    epoll_event event;
    event.data.fd = fd;
    event.events = EPOLLIN | EPOLLET | EPOLLRDHUP;
    if( one_shot )
    {
        event.events |= EPOLLONESHOT;
    }
    epoll_ctl( epollfd, EPOLL_CTL_ADD, fd, &event );
    setnonblocking( fd );
}

void CCommon::modfd( int epollfd, int fd, int ev )
{
    epoll_event event;
    event.data.fd = fd;
    event.events = ev | EPOLLET | EPOLLONESHOT | EPOLLRDHUP;
    epoll_ctl( epollfd, EPOLL_CTL_MOD, fd, &event );
}

char CCommon::dechex2char(short int n)
{
    if ( 0 <= n && n <= 9 ) 
    {
        return char( short('0') + n );
    }
    else if ( 10 <= n && n <= 15 ) 
    {
        return char( short('A') + n - 10 );
    } 
    else 
    {
        return char(0);
    }   
}

short int CCommon::decchar2hex(char c)
{
    if ( '0'<=c && c<='9' ) 
    {
        return short(c-'0');
    } 
    else if ( 'a'<=c && c<='f' ) 
    {
        return ( short(c-'a') + 10 );
    }
    else if ( 'A'<=c && c<='F' ) 
    {
        return ( short(c-'A') + 10 );
    } 
    else 
    {
        return -1;
    }
}

string CCommon::url_encode(const string &url)
{
    string strResult = "";
    for ( unsigned int i=0; i<url.size(); i++ )
    {
        char c = url[i];
        if (( '0'<=c && c<='9' ) ||
            ( 'a'<=c && c<='z' ) ||
            ( 'A'<=c && c<='Z' ) ||
            ( c=='/' || c=='.')) 
        {
                strResult += c;
        } 
        else 
        {
            int j = (short int)c;
            if ( j < 0 )
            {
                j += 256;
            }
            int i1, i0;
            i1 = j / 16;
            i0 = j - i1*16;
            strResult += '%';
            strResult += dechex2char(i1);
            strResult += dechex2char(i0);
        }
    }

    return strResult;   
}
    
string CCommon::url_decode(const string &url)
{
    string result = "";
    for ( unsigned int i=0; i<url.size(); i++ ) 
    {
        char c = url[i];
        if ( c != '%' ) 
        {
            result += c;
        } 
        else 
        {
            char c1 = url[++i];
            char c0 = url[++i];
            int num = 0;
            num += decchar2hex(c1) * 16 + decchar2hex(c0);
            result += char(num);
        }
    }
    return result;
}





