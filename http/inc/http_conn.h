#ifndef HTTP_CONNECTION_H
#define HTTP_CONNECTION_H

#include <unistd.h>
#include <signal.h>
#include <sys/types.h>
#include <sys/epoll.h>
#include <fcntl.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <assert.h>
#include <sys/stat.h>
#include <string.h>
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/mman.h>
#include <stdarg.h>
#include <errno.h>
#include <string>
#include "locker.h"




class http_conn
{
public:
    static const int FILENAME_LEN = 200;
    static const int READ_BUFFER_SIZE = 2048;
    static const int WRITE_BUFFER_SIZE = 1024;
    static const int REQUEST_BUFFER_SIZE = 512000 ;    // max size of request data is 200Kb

    enum METHOD { GET = 0, POST, HEAD, PUT, DELETE, TRACE, OPTIONS, CONNECT, PATCH };
    enum CHECK_STATE { CHECK_STATE_REQUESTLINE = 0, CHECK_STATE_HEADER, CHECK_STATE_CONTENT };
    enum HTTP_CODE { NO_REQUEST, GET_REQUEST, POST_REQUEST, BAD_REQUEST, NO_RESOURCE, FORBIDDEN_REQUEST, FILE_REQUEST, 
         INTERNAL_ERROR, CLOSED_CONNECTION, DATA_OVERFLOW, REQUEST_OK, MORE_DATA_REQUEST };
    enum LINE_STATUS { LINE_OK = 0, LINE_BAD, LINE_OPEN };

public:
    http_conn(){}
    ~http_conn();

public:
    void init( int sockfd, const sockaddr_in& addr );
    void close_conn( bool real_close = true );
    void process();
    bool http_read();
    bool http_write();

private:
    void init();
    HTTP_CODE process_read();
    bool process_write( HTTP_CODE ret );

    HTTP_CODE parse_request_line( char* text );
    HTTP_CODE parse_headers( char* text );
    HTTP_CODE parse_content( char* text );
    HTTP_CODE do_request();
    char* get_line() { return m_read_buf + m_start_line; }
    LINE_STATUS parse_line();
    HTTP_CODE do_save_file(const char *str);
    HTTP_CODE do_cgi_request(const char *str);
    HTTP_CODE do_file_request();

    void unmap();
    bool add_response( const char* format, ... );
    bool add_content( const char* content );
    bool add_status_line( int status, const char* title );
    bool add_headers( int content_length );
    bool add_content_length( int content_length );
    bool add_linger();
    bool add_blank_line();

public:
    static int m_epollfd;
    static int m_user_count;

private:
    int m_sockfd;
    sockaddr_in m_address;

   // char m_read_buf[ READ_BUFFER_SIZE ];
    char* m_read_buf;
    int m_read_idx;
    int m_checked_idx;
    int m_start_line;
    char m_write_buf[ WRITE_BUFFER_SIZE ];
    int m_write_idx;
    char* m_request_data;
    int m_parsed_header_idx;

    CHECK_STATE m_check_state;
    METHOD m_method;
    HTTP_CODE m_request_type;

    char m_real_file[ FILENAME_LEN ];
    //char *m_real_file;
    char* m_url;
    char* m_version;
    char* m_host;
    int m_content_length;
    char* m_content_type;
    bool m_linger;
    char* m_accept;
    char* m_accept_charset;
    char* m_accept_encoding;
    char* m_accept_language;
    char* m_accept_datetime;
    char* m_cache_ctl;
    char* m_upgrade_insecure_req;
    char* m_user_agent;
    char* m_file_address;
    char* m_referer;
    struct stat m_file_stat;
    struct iovec m_iv[2];
    int m_iv_count;

};

#endif
