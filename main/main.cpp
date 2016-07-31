#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <cassert>
#include <libgen.h>
#include <string.h>
#include <vector>

#include "processpool.h"
#include "common.h"
#include "mongodb_client.h"

#ifdef CGI_SERVER 
#include "cgi_conn.h"
#endif

#ifdef HTTP_SERVER
#include "locker.h"
#include "threadpool.h"
#include "http_conn.h"
#endif

#ifdef HTTP_SERVER
#define MAX_FD 65536
#define MAX_EVENT_NUMBER 10000
#endif

using std::vector;

static const char* version = "1.0";

static void usage( const char* prog )
{
    log( LOG_INFO, "usage: %s [-h] [-v] [-f config_file]", prog );
}

int main( int argc, char* argv[] )
{
#ifdef XEA_DEBUG
    set_loglevel(LOG_DEBUG);
#endif
    if( argc < 2 )
    {
        log( LOG_INFO, "usage: %s [-h] [-v] [-f config_file]", basename( argv[0] ) );
        return 0;
    }
    char cfg_file[1024];
    memset( cfg_file, '\0', 100 );
    int option;
    while ( ( option = getopt( argc, argv, "f:xvh" ) ) != -1 )
    {
        switch ( option )
        {
            case 'x':
            {
                set_loglevel( LOG_DEBUG );
                break;
            }
            case 'v':
            {
                log( LOG_INFO, "%s %s", argv[0], version );
                return 0;
            }
            case 'h':
            {
                usage( basename( argv[ 0 ] ) );
                return 0;
            }
            case 'f':
            {
                memcpy( cfg_file, optarg, strlen( optarg ) );
                break;
            }
            case '?':
            {
                log( LOG_ERR, "un-recognized option %c", option );
                usage( basename( argv[ 0 ] ) );
                return 1;
            }
        }
    }    

    if( cfg_file[0] == '\0' )
    {
        log( LOG_ERR, __FILE__, __LINE__, "%s", "please specifiy the config file" );
        return 1;
    }
    int cfg_fd = open( cfg_file, O_RDONLY );
    if( !cfg_fd )
    {
        log( LOG_ERR, __FILE__, __LINE__, "read config file met error: %s", strerror( errno ) );
        return 1;
    }
    struct stat ret_stat;
    if( fstat( cfg_fd, &ret_stat ) < 0 )
    {
        log( LOG_ERR, __FILE__, __LINE__, "read config file met error: %s", strerror( errno ) );
        return 1;
    }
    char* buf = new char [ret_stat.st_size + 1];
    memset( buf, '\0', ret_stat.st_size + 1 );
    ssize_t read_sz = read( cfg_fd, buf, ret_stat.st_size );
    if ( read_sz < 0 )
    {
        log( LOG_ERR, __FILE__, __LINE__, "read config file met error: %s", strerror( errno ) );
        return 1;
    }
    vector< host > balance_srv;
    vector< host > logical_srv;
    host tmp_host;
    memset( tmp_host.m_hostname, '\0', 1024 );
    char* tmp_hostname;
    char* tmp_port;
    char* tmp_conncnt;
    bool opentag = false;
    char* tmp = buf;
    char* tmp2 = NULL;
    char* tmp3 = NULL;
    char* tmp4 = NULL;
    while( tmp2 = strpbrk( tmp, "\n" ) )
    {
        *tmp2++ = '\0';
        if( strstr( tmp, "<logical_host>" ) )
        {
            if( opentag )
            {
                log( LOG_ERR, __FILE__, __LINE__, "%s", "parse config file failed" );
                return 1;
            }
            opentag = true;
        }
        else if( strstr( tmp, "</logical_host>" ) )
        {
            if( !opentag )
            {
                log( LOG_ERR, __FILE__, __LINE__, "%s", "parse config file failed" );
                return 1;
            }
            logical_srv.push_back( tmp_host );
            memset( tmp_host.m_hostname, '\0', 1024 );
            opentag = false;
        }
        else if( tmp3 = strstr( tmp, "<name>" ) )
        {
            tmp_hostname = tmp3 + 6;
            tmp4 = strstr( tmp_hostname, "</name>" );
            if( !tmp4 )
            {
                log( LOG_ERR, __FILE__, __LINE__, "%s", "parse config file failed" );
                return 1;
            }
            *tmp4 = '\0';
            memcpy( tmp_host.m_hostname, tmp_hostname, strlen( tmp_hostname ) );
        }
        else if( tmp3 = strstr( tmp, "<port>" ) )
        {
            tmp_port = tmp3 + 6;
            tmp4 = strstr( tmp_port, "</port>" );
            if( !tmp4 )
            {
                log( LOG_ERR, __FILE__, __LINE__, "%s", "parse config file failed" );
                return 1;
            }
            *tmp4 = '\0';
            tmp_host.m_port = atoi( tmp_port );
        }
        else if( tmp3 = strstr( tmp, "<conns>" ) )
        {
            tmp_conncnt = tmp3 + 7;
            tmp4 = strstr( tmp_conncnt, "</conns>" );
            if( !tmp4 )
            {
                log( LOG_ERR, __FILE__, __LINE__, "%s", "parse config file failed" );
                return 1;
            }
            *tmp4 = '\0';
            tmp_host.m_conncnt = atoi( tmp_conncnt );
        }
        else if( tmp3 = strstr( tmp, "Listen" ) )
        {
            tmp_hostname = tmp3 + 6;
            tmp4 = strstr( tmp_hostname, ":" );
            if( !tmp4 )
            {
                log( LOG_ERR, __FILE__, __LINE__, "%s", "parse config file failed" );
                return 1;
            }
            *tmp4++ = '\0';
            tmp_host.m_port = atoi( tmp4 );
            memcpy( tmp_host.m_hostname, tmp3, strlen( tmp3 ) );
            balance_srv.push_back( tmp_host );
            memset( tmp_host.m_hostname, '\0', 1024 );
        }
        tmp = tmp2;
    }

    if( balance_srv.size() == 0 || logical_srv.size() == 0 )
    {
        log( LOG_ERR, __FILE__, __LINE__, "%s", "parse config file failed" );
        return 1;
    }
    const char* ip = balance_srv[0].m_hostname;
    int port = balance_srv[0].m_port;
    
    CMongodbClient::getInstance()->connectMongodb();
    
   // const char* ip = argv[1];
   // int port = atoi( argv[2] );
    int listenfd = socket( PF_INET,SOCK_STREAM, 0 );
    assert(listenfd >= 0);

    //close immediately and not finish sending data remain to be send 
    struct linger tmp_linger = { 1, 0 };
    setsockopt( listenfd, SOL_SOCKET, SO_LINGER, &tmp, sizeof( tmp_linger ) );

    int ret = 0;
    struct sockaddr_in address;
    bzero(&address, sizeof(address));
    address.sin_family = AF_INET;
    inet_pton(AF_INET, ip, &address.sin_addr);
    address.sin_port = htons(port);

    ret = bind(listenfd, (struct sockaddr *)&address, sizeof(address));
    assert(ret != -1);
    ret = listen(listenfd,5);

#ifdef CGI_SERVER 
    CProcessPool<CCgiConnection> *cgi_pool = CProcessPool<CCgiConnection> :: create(listenfd);
    if(cgi_pool)
    {
        cgi_pool->run();
        delete cgi_pool;
    }
#endif

#ifdef HTTP_SERVER
    threadpool< http_conn >* pool = NULL;
    try
    {
        pool = new threadpool< http_conn >;
    }
    catch( ... )
    {
        return 1;
    }

    http_conn* users = new http_conn[ MAX_FD ];
    assert( users );
    int user_count = 0;

    epoll_event events[ MAX_EVENT_NUMBER ];
    int epollfd = epoll_create( 5 );
    assert( epollfd != -1 );
    CCommon::getInstance()->addfd( epollfd, listenfd, false );
    http_conn::m_epollfd = epollfd;

    while( true )
    {
        int number = epoll_wait( epollfd, events, MAX_EVENT_NUMBER, -1 );
        if ( ( number < 0 ) && ( errno != EINTR ) )
        {
            printf( "epoll failure\n" );
            break;
        }

        for ( int i = 0; i < number; i++ )
        {
            int sockfd = events[i].data.fd;
            if( sockfd == listenfd )
            {
                struct sockaddr_in client_address;
                socklen_t client_addrlength = sizeof( client_address );
                int connfd = accept( listenfd, ( struct sockaddr* )&client_address, &client_addrlength );
                if ( connfd < 0 )
                {
                    printf( "errno is: %d\n", errno );
                    continue;
                }
                if( http_conn::m_user_count >= MAX_FD )
                {
                    CCommon::getInstance()->show_error( connfd, "Internal server busy" );
                    continue;
                }
                
                users[connfd].init( connfd, client_address );
            }
            else if( events[i].events & ( EPOLLRDHUP | EPOLLHUP | EPOLLERR ) )
            {
                printf( "++++++++++++++++++++++ user[%d] close ++++++++++++++++\n", sockfd);
                users[sockfd].close_conn();
            }
            else if( events[i].events & EPOLLIN )
            {
                printf( "++++++++++++++++++++++ user[%d] IN ++++++++++++++++\n", sockfd);
                if( users[sockfd].http_read() )
                {
                    pool->append( users + sockfd );
                }
                else
                {
                    users[sockfd].close_conn();
                }
            }
            else if( events[i].events & EPOLLOUT )
            {
                printf( "++++++++++++++++++++++ user[%d] OUT ++++++++++++++++\n", sockfd);
                printf("write event \n");
                if( !users[sockfd].http_write() )
                {
                    printf("write success and close conn\n");
                    users[sockfd].close_conn();
                }
            }
        }
    }

    close( epollfd );
    delete [] users;
    delete pool;
#endif

    close(listenfd);
    return 0;
}
