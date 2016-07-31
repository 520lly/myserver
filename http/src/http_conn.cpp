#include "json/json.h"
#include <Poco/Base64Decoder.h>
#include "http_conn.h"
#include "common.h"
#include "mongodb_client.h"

const char* ok_200_title = "OK";
const char* error_400_title = "Bad Request";
const char* error_400_form = "Your request has bad syntax or is inherently impossible to satisfy.\n";
const char* error_403_title = "Forbidden";
const char* error_403_form = "You do not have permission to get file from this server.\n";
const char* error_404_title = "Not Found";
const char* error_404_form = "The requested file was not found on this server.\n";
const char* error_500_title = "Internal Error";
const char* error_500_form = "There was an unusual problem serving the requested file.\n";
const char* web_root = "/home/jaycee/mycode/server/C/server/myserver/web/root/www/html";
const char* cgi_root = "/home/jaycee/mycode/server/C/server/myserver/cgi/scripts";
const char* rt_root = "/home/jaycee/mycode/server/C/server/myserver/output/";


int http_conn::m_user_count = 0;
int http_conn::m_epollfd = -1;

http_conn::~http_conn()
{
    if ( NULL != m_request_data )
    {
        delete[] m_request_data;
        m_request_data = NULL;
    }
    if ( NULL != m_read_buf )
    {
        delete[] m_read_buf;
        m_read_buf = NULL;
    }
//    if ( NULL != m_real_file )
//    {
//        delete[] m_real_file;
//        m_real_file = NULL;
//    }
}

void http_conn::close_conn( bool real_close )
{
    if( real_close && ( m_sockfd != -1 ) )
    {
        //CCommon::getInstance()->modfd( m_epollfd, m_sockfd, EPOLLIN );
        CCommon::getInstance()->removefd( m_epollfd, m_sockfd );
        m_sockfd = -1;
        m_user_count--;
    }
}

void http_conn::init( int sockfd, const sockaddr_in& addr )
{
    m_sockfd = sockfd;
    m_address = addr;
    int error = 0;
    socklen_t len = sizeof( error );
    getsockopt( m_sockfd, SOL_SOCKET, SO_ERROR, &error, &len );
    int reuse = 1;
    setsockopt( m_sockfd, SOL_SOCKET, SO_REUSEADDR, &reuse, sizeof( reuse ) );
    CCommon::getInstance()->addfd( m_epollfd, sockfd, true );
    m_user_count++;

    init();
}

void http_conn::init()
{
    m_check_state = CHECK_STATE_REQUESTLINE;
    m_linger = false;

    m_method = GET;
    m_request_type = NO_REQUEST;
    m_url = 0;
    m_version = 0;
    m_content_length = 0;
    m_host = 0;
    m_accept = 0;
    m_accept_charset = 0;
    m_accept_encoding = 0;
    m_accept_language = 0;
    m_accept_datetime = 0;
    m_cache_ctl = 0;
    m_upgrade_insecure_req = 0;
    m_referer = 0;
    m_user_agent = 0;
    m_start_line = 0;
    m_checked_idx = 0;
    m_read_idx = 0;
    m_write_idx = 0;
    m_parsed_header_idx = 0;
    m_read_buf = new char[ REQUEST_BUFFER_SIZE ];
    memset( m_read_buf, '\0', READ_BUFFER_SIZE );
    memset( m_write_buf, '\0', WRITE_BUFFER_SIZE );
    m_request_data = new char[ REQUEST_BUFFER_SIZE ];
    memset( m_request_data, '\0', REQUEST_BUFFER_SIZE );
   // m_real_file = new char[ REQUEST_BUFFER_SIZE ];
   // memset( m_real_file, '\0', REQUEST_BUFFER_SIZE);
}

http_conn::LINE_STATUS http_conn::parse_line()
{
    char temp;
    for ( ; m_checked_idx < m_read_idx; ++m_checked_idx )
    {
        temp = m_read_buf[ m_checked_idx ];
        if ( temp == '\r' )
        {
            if ( ( m_checked_idx + 1 ) == m_read_idx )
            {
                return LINE_OPEN;
            }
            else if ( m_read_buf[ m_checked_idx + 1 ] == '\n' )
            {
                m_read_buf[ m_checked_idx++ ] = '\0';
                m_read_buf[ m_checked_idx++ ] = '\0';
                return LINE_OK;
            }

            return LINE_BAD;
        }
        else if( temp == '\n' )
        {
            if( ( m_checked_idx > 1 ) && ( m_read_buf[ m_checked_idx - 1 ] == '\r' ) )
            {
                m_read_buf[ m_checked_idx-1 ] = '\0';
                m_read_buf[ m_checked_idx++ ] = '\0';
                return LINE_OK;
            }
            return LINE_BAD;
        }
    }

    return LINE_OPEN;
}

bool http_conn::http_read()
{
    printf("m_read_idx is %d \n",m_read_idx);
    if( m_read_idx >= REQUEST_BUFFER_SIZE )
    {
        return false;
    }

    int bytes_read = 0;
    while( true )
    {
        bytes_read = recv( m_sockfd, m_read_buf + m_read_idx, REQUEST_BUFFER_SIZE - m_read_idx, 0 );
        printf("bytes_read is %d \n",bytes_read);
        if ( bytes_read == -1 )
        {
            printf("errno %d EAGAIN %d EWOULDBLOCK %d \n",errno, EAGAIN, EWOULDBLOCK);
            if( errno == EAGAIN || errno == EWOULDBLOCK )
            {
                break;
            }
            return false;
        }
        else if ( bytes_read == 0 )
        {
            return false;
        }
        
        m_read_idx += bytes_read;
    }
    printf("m_read_idx is %d \n",m_read_idx);
    return true;
}

http_conn::HTTP_CODE http_conn::parse_request_line( char* text )
{
    m_url = strpbrk( text, " \t" );
    //printf("m_url: %s\n",m_url);
    //check request contain space or horizontal tab char
    if ( ! m_url )
    {
        return BAD_REQUEST;
    }
    *m_url++ = '\0';

    char* method = text;
    if ( strcasecmp( method, "GET" ) == 0 )
    {
        m_method = GET;
    }
    else if ( strcasecmp( method, "POST" ) == 0 )
    {
        m_method = POST;
    }
    else
    {
        return BAD_REQUEST;
    }
    printf("m_method: %d\n",m_method);

    m_url += strspn( m_url, " \t" );
    m_version = strpbrk( m_url, " \t" );
    if ( ! m_version )
    {
        return BAD_REQUEST;
    }
    *m_version++ = '\0';
    m_version += strspn( m_version, " \t" );
    printf("m_version: %s\n",m_version);

    if ( strcasecmp( m_version, "HTTP/1.1" ) != 0 )
    {
        return BAD_REQUEST;
    }

    //printf("m_url: %s\n",m_url);
    if ( strncasecmp( m_url, "http://", 7 ) == 0 )
    {
        m_url += 5;
        m_url = strchr( m_url, '/' );
    }

    printf("m_url: %s\n",m_url);
    if ( ! m_url || m_url[ 0 ] != '/' )
    {
        return BAD_REQUEST;
    }

    m_check_state = CHECK_STATE_HEADER;
    return NO_REQUEST;
}

http_conn::HTTP_CODE http_conn::parse_headers( char* text )
{
    m_parsed_header_idx = m_parsed_header_idx; 
    printf("text: %s\n",text);
    if( text[ 0 ] == '\0' )
    {
        printf("m_method = %d m_content_length = %d \n", m_method, m_content_length);
        if ( m_method == HEAD )
        {
            return GET_REQUEST;
        }

        if ( m_content_length != 0 )
        {
            m_check_state = CHECK_STATE_CONTENT;
            return NO_REQUEST;
        }

        return GET_REQUEST;
    }
    else if ( strncasecmp( text, "Connection:", 11 ) == 0 )
    {
        text += 11;
        text += strspn( text, " \t" );
        if ( strcasecmp( text, "keep-alive" ) == 0 )
        {
            m_linger = true;
        }
    }
    else if ( strncasecmp( text, "Content-Length:", 15 ) == 0 )
    {
        text += 15;
        text += strspn( text, " \t" );
        m_content_length = atol( text );
    }
    else if ( strncasecmp( text, "Content-Type:", 13 ) == 0 )
    {
        text += 13;
        text += strspn( text, " \t" );
        m_content_type = text;
    }
    else if ( strncasecmp( text, "Host:", 5 ) == 0 )
    {
        text += 5;
        text += strspn( text, " \t" );
        m_host = text;
    }
    else if ( strncasecmp( text, "Accept:", 7 ) == 0 )
    {
        text += 7;
        text += strspn( text, " \t" );
        m_accept = text;
    }
    else if ( strncasecmp( text, "Accept-Charset:", 15 ) == 0 )
    {
        text += 15;
        text += strspn( text, " \t" );
        m_accept_charset = text;
    }
    else if ( strncasecmp( text, "Accept-Encoding:", 16 ) == 0 )
    {
        text += 16;
        text += strspn( text, " \t" );
        m_accept_encoding = text;
    }
    else if ( strncasecmp( text, "Accept-Language:", 16 ) == 0 )
    {
        text += 16;
        text += strspn( text, " \t" );
        m_accept_language = text;
    }
    else if ( strncasecmp( text, "Accept-Datetime:", 16 ) == 0 )
    {
        text += 16;
        text += strspn( text, " \t" );
        m_accept_datetime = text;
    }
    else if ( strncasecmp( text, "Cache-Control:", 14 ) == 0 )
    {
        text += 14;
        text += strspn( text, " \t" );
        m_cache_ctl = text;
    }
    else if ( strncasecmp( text, "User-Agent:", 11 ) == 0 )
    {
        text += 14;
        text += strspn( text, " \t" );
        m_user_agent = text;
    }
    else if ( strncasecmp( text, "Upgrade-Insecure-Requests:", 26 ) == 0 )
    {
        text += 26;
        text += strspn( text, " \t" );
        m_upgrade_insecure_req = text;
    }
   else if ( strncasecmp( text, "Referer:", 8 ) == 0 )
    {
        text += 8;
        text += strspn( text, " \t" );
        m_referer = text;
    }
    else
    {
        printf( "[oop! unknow header content %s]\n", text );
    }

    return NO_REQUEST;

}

http_conn::HTTP_CODE http_conn::parse_content( char* text )
{
    printf("parse_content text:  m_read_idx = %d  m_content_length = %d m_checked_idx = %d \n", m_read_idx, m_content_length, m_checked_idx); 
    //if ( m_read_idx >= ( m_content_length + m_parsed_header_idx ) )
    if ( m_read_idx >= ( m_content_length + m_checked_idx ) )
    {
        if ( m_content_length > REQUEST_BUFFER_SIZE )
        {
            return DATA_OVERFLOW;
        }
        text[ m_content_length ] = '\0';
        strcpy ( m_request_data, text);
        //printf("m_request_data %s \n", m_request_data);

        if ( m_method == GET  )
        {
            return GET_REQUEST;
        }
        else if ( m_method == POST  )
        {
            return POST_REQUEST;
        }
    }
    else
    {
       return MORE_DATA_REQUEST;
    }

    return NO_REQUEST;
}

http_conn::HTTP_CODE http_conn::process_read()
{
    LINE_STATUS line_status = LINE_OK;
    HTTP_CODE ret = NO_REQUEST;
    char* text = 0;

    while ( ( ( m_check_state == CHECK_STATE_CONTENT ) && ( line_status == LINE_OK  ) )
                || ( ( line_status = parse_line() ) == LINE_OK ) )
    {
        text = get_line();
        m_start_line = m_checked_idx;
        printf( "got 1 http line >>> m_check_state: %d\n", m_check_state );

        switch ( m_check_state )
        {
            case CHECK_STATE_REQUESTLINE:
            {
                ret = parse_request_line( text );
                m_request_type = ret;
                printf("parse request line ret = %d \n",ret);
                if ( ret == BAD_REQUEST )
                {
                    return BAD_REQUEST;
                }
                break;
            }
            case CHECK_STATE_HEADER:
            {
                ret = parse_headers( text );
                m_request_type = ret;
                printf("parse_headers ret = %d\n",ret);
                if ( ret == BAD_REQUEST )
                {
                    return BAD_REQUEST;
                }
                else if ( ret == GET_REQUEST )
                {
                    return do_request();
                }
                break;
            }
            case CHECK_STATE_CONTENT:
            {
                ret = parse_content( text );
                m_request_type = ret;
                printf("parse_content ret = %d MORE_DATA_REQUEST %d \n",ret, MORE_DATA_REQUEST);
                if ( ret == GET_REQUEST )
                {
                    return do_request();
                }
                else if ( ret == POST_REQUEST )
                {
                    return do_request();
                }
                else if (ret == MORE_DATA_REQUEST )
                {
                    printf("return MORE_DATA_REQUEST \n");
                    return MORE_DATA_REQUEST;
                }
                line_status = LINE_OPEN;
                break;
            }
            default:
            {
                return INTERNAL_ERROR;
            }
        }
    }

    return NO_REQUEST;
}

http_conn::HTTP_CODE http_conn::do_request()
{
    if ( m_method == POST )
    {
        do_save_file(m_request_data);
        return REQUEST_OK;
    }
    if ( m_method == GET )
    {
        if(strncasecmp( m_url, "/cgi" , 4) == 0)
        {
            m_url += 4;
            strcpy( m_real_file, cgi_root );
            int len = strlen( cgi_root );
            strncpy( m_real_file + len, m_url, FILENAME_LEN - len - 1 );
            printf("cgi file request fpath: %s\n",m_real_file);
            return do_cgi_request(m_real_file);
        } 
        else if (strncasecmp( m_url, "/web", 4 ) == 0)
        {
            m_url += 4;
            strcpy( m_real_file, web_root );
            int len = strlen( web_root );
            strncpy( m_real_file + len, m_url, FILENAME_LEN - len - 1 );
            printf("web file request fpath: %s\n",m_real_file);
            
            return do_file_request();
        }

    }

}

void http_conn::unmap()
{
    if( m_file_address )
    {
        munmap( m_file_address, m_file_stat.st_size );
        m_file_address = 0;
    }
}

bool http_conn::http_write()
{
    int temp = 0;
    int bytes_have_send = 0;
    int bytes_to_send = m_write_idx;
    int retry_write_count = 10;
    printf("bytes_to_send %d \n",bytes_to_send);
    if ( bytes_to_send == 0 )
    {
        CCommon::getInstance()->modfd( m_epollfd, m_sockfd, EPOLLIN );
        init();
        return true;
    }
    printf("m_request_type :%d\n",m_request_type);

    while( true && retry_write_count )
    {
        if ( m_request_type == GET_REQUEST )
        {
            temp = writev( m_sockfd, m_iv, m_iv_count );
        }
        else
        {
            temp = send( m_sockfd, m_write_buf, m_write_idx, 0 );
        }
        printf("retry_write_count: %d   temp %d \n",retry_write_count, temp);
        if ( temp <= -1 )
        {
            if( errno == EAGAIN )
            {
                CCommon::getInstance()->modfd( m_epollfd, m_sockfd, EPOLLOUT );
                return true;
            }
            unmap();
            return false;
        }
        else if ( temp == 0 )
        {
            retry_write_count--;    
            continue;
        }

        bytes_to_send -= temp;
        bytes_have_send += temp;
        if ( bytes_to_send <= bytes_have_send )
        {
            if (m_request_type == GET_REQUEST )
            {
                unmap();
            }
            if( m_linger )
            {
                init();
                CCommon::getInstance()->modfd( m_epollfd, m_sockfd, EPOLLIN );
                return true;
            }
            else
            {
                CCommon::getInstance()->modfd( m_epollfd, m_sockfd, EPOLLIN );
                return false;
            } 
        }
    }
}

bool http_conn::add_response( const char* format, ... )
{
    if( m_write_idx >= WRITE_BUFFER_SIZE )
    {
        return false;
    }
    va_list arg_list;
    va_start( arg_list, format );
    int len = vsnprintf( m_write_buf + m_write_idx, WRITE_BUFFER_SIZE - 1 - m_write_idx, format, arg_list );
    if( len >= ( WRITE_BUFFER_SIZE - 1 - m_write_idx ) )
    {
        return false;
    }
    m_write_idx += len;
    va_end( arg_list );
    return true;
}

bool http_conn::add_status_line( int status, const char* title )
{
    return add_response( "%s %d %s\r\n", "HTTP/1.1", status, title );
}

bool http_conn::add_headers( int content_len )
{
    add_content_length( content_len );
    add_linger();
    add_blank_line();
}

bool http_conn::add_content_length( int content_len )
{
    return add_response( "Content-Length: %d\r\n", content_len );
}

bool http_conn::add_linger()
{
    return add_response( "Connection: %s\r\n", ( m_linger == true ) ? "keep-alive" : "close" );
}

bool http_conn::add_blank_line()
{
    return add_response( "%s", "\r\n" );
}

bool http_conn::add_content( const char* content )
{
    return add_response( "%s", content );
}

bool http_conn::process_write( HTTP_CODE ret )
{
    switch ( ret )
    {
        case INTERNAL_ERROR:
        {
            add_status_line( 500, error_500_title );
            add_headers( strlen( error_500_form ) );
            if ( ! add_content( error_500_form ) )
            {
                return false;
            }
            break;
        }
        case BAD_REQUEST:
        {
            add_status_line( 400, error_400_title );
            add_headers( strlen( error_400_form ) );
            if ( ! add_content( error_400_form ) )
            {
                return false;
            }
            break;
        }
        case NO_RESOURCE:
        {
            add_status_line( 404, error_404_title );
            add_headers( strlen( error_404_form ) );
            if ( ! add_content( error_404_form ) )
            {
                return false;
            }
            break;
        }
        case FORBIDDEN_REQUEST:
        {
            add_status_line( 403, error_403_title );
            add_headers( strlen( error_403_form ) );
            if ( ! add_content( error_403_form ) )
            {
                return false;
            }
            break;
        }
        case FILE_REQUEST:
        {
            printf("FILE_REQUEST file size %d \n", (int)m_file_stat.st_size);
            add_status_line( 200, ok_200_title );
            if ( m_file_stat.st_size != 0 )
            {
                add_headers( m_file_stat.st_size );
                m_iv[ 0 ].iov_base = m_write_buf;
                m_iv[ 0 ].iov_len = m_write_idx;
                m_iv[ 1 ].iov_base = m_file_address;
                m_iv[ 1 ].iov_len = m_file_stat.st_size;
                m_iv_count = 2;
                return true;
            }
            else
            {
                const char* ok_string = "<html><body></body></html>";
                add_headers( strlen( ok_string ) );
                if ( ! add_content( ok_string ) )
                {
                    return false;
                }
                return true;
            }
            break;
        }
        case REQUEST_OK:
        {
            add_status_line( 200, ok_200_title );
            const char* ok_string = "<html><body></body></html>";
            add_headers( strlen( ok_string ) );
            Json::Value ret;
            ret["data"] = "";
            ret["req_id"] = "hah";
            Json::FastWriter writer;
            string out = writer.write(ret);
            printf("out %s\n",out.c_str());
            if ( ! add_content( out.c_str() ) )
            {
                return false;
            }
            return true;
        }
        default:
        {
            return false;
        }
    }

    m_iv[ 0 ].iov_base = m_write_buf;
    m_iv[ 0 ].iov_len = m_write_idx;
    m_iv_count = 1;
    return true;
}

void http_conn::process()
{
    HTTP_CODE read_ret = process_read();
    printf("process_read read_ret %d \n", read_ret);
    if ( read_ret == NO_REQUEST )
    {
        CCommon::getInstance()->modfd( m_epollfd, m_sockfd, EPOLLIN );
        return;
    }else if (read_ret == MORE_DATA_REQUEST )
    {
        CCommon::getInstance()->modfd( m_epollfd, m_sockfd, EPOLLIN );
        return;
    }

    bool write_ret = process_write( read_ret );
    printf("write_ret %d \n",write_ret);
    if ( ! write_ret )
    {
        close_conn();
    }

    CCommon::getInstance()->modfd( m_epollfd, m_sockfd, EPOLLOUT );
}

http_conn::HTTP_CODE http_conn::do_save_file(const char *str)
{
    string tmp(str);  
    if(tmp.length() == 0)
    {
        return BAD_REQUEST;
    }
    string str_data = CCommon::getInstance()->url_decode(tmp);
    //printf("str_data = %s \n", str_data.c_str());
    
    string DataPrefix = tmp.substr(0,5);
    printf("DataPrefix = %s \n",DataPrefix.c_str());
    if(DataPrefix.compare("data=") != 0)
    {
        return BAD_REQUEST;
    }

    string data = str_data.substr(5,tmp.length()-5);
    //printf("%s \n",data.c_str());
    Json::Reader reader;
    Json::Value root;
    if(!reader.parse(data, root))
    {
        return BAD_REQUEST;
    }

    int platform = root["platform"].asInt();
    //printf("platform is %d\n",platform);
    string fname = root["fileName"].asString();
    //printf("fname is %s\n",fname.c_str());
    string zxqToken = root["zxqToken"].asString();
    //printf("zxqToken is %s\n",zxqToken.c_str());
    string fbdata = root["fileBinaryData"].asString();
    //printf("fbdata is %s\n",fbdata.c_str());
    CCommon::getInstance()->save_base64_to_gz(fname, fbdata);
    string srcType = root["srcType"].asString();
    //printf("srcType is %s\n",srcType.c_str());
    string appType = root["appType"].asString();
    //printf("appType is %s\n",appType.c_str());
    string uuid = root["uuid"].asString();
    //printf("uuid is %s\n",uuid.c_str());
    string bType = root["businessType"].asString();
    //printf("bType is %s\n",bType.c_str());
    string date = root["date"].asString();
    //printf("date is %s\n",date.c_str());
    string vin = root["vin"].asString();
    //printf("vin is %s\n",vin.c_str());

    mongo::BSONObjBuilder builder;
    builder<<"vin"<<vin<<"uuid"<<uuid<<"platform"<<platform;
    builder<<"zxqToken"<<zxqToken<<"fname"<<fname;
    builder<<"srcType"<<srcType<<"appType"<<appType;
    builder<<"bType"<<bType<<"date"<<date;

    CMongodbClient::getInstance()->insert("zxq.nt", builder.obj());

    return REQUEST_OK;
}

http_conn::HTTP_CODE http_conn::do_cgi_request(const char *file_name)
{
    int ret = -1;
    //check if the CGI server exit, which client request
    if( access(file_name, F_OK) == -1 )
    {
        printf("file %s not accessable\n", file_name);
        CCommon::getInstance()->removefd(m_epollfd, m_sockfd);
        return NO_RESOURCE;
    }
    int pfd[2], nbytes;
    int *read_fd = &pfd[0];
    int *write_fd = &pfd[1];
    char buf[1024];
    memset(buf, '\0', 1024);

    //fork child process to excute CGI server
    ret = fork();
    if(ret == -1)
    {
        printf("fork failure \n");
        CCommon::getInstance()->removefd(m_epollfd, m_sockfd);
        return FORBIDDEN_REQUEST;
    }
    else if (ret == 0)
    {
        close(*read_fd);  //close read fd in child thread 
        //child process redirect std output to m_sockfd and excute CGI server
        printf("execute CGI script %s\n",file_name);
       // fflush(stdout);
        //setvbuf(stdout, NULL, _IONBF, 0);
        //int fd = open("cgi.html", (O_RDWR | O_CREAT), 0644);
        //dup2(fd, STDOUT_FILENO);
        //int backfd = dup(STDOUT_FILENO);
        //close(STDOUT_FILENO);
        //dup(m_sockfd);
        //dup(*write_fd);
        //FILE *fd = freopen("cgi.txt", "w", stdout);
        //to do client request and response to client
        fclose(stdout);
        printf("HTTP/1.1 200 OK\r\n");
        execl(file_name, file_name, (char *)0);
        //int fd;
        //dup2(fd, backfd);
        //close(fd);
        puts("puts");
        freopen("/dev/tty", "w", stdout);
        //dup2(backfd, STDOUT_FILENO);
        //strcpy(m_real_file, rt_root);
        //int len = strlen("cgi.html");
        //strncpy(m_real_file+len, "cgi.html", FILENAME_LEN - len - 1);
        printf("file is : %s\n",m_real_file);
        do_file_request();
        exit(0);
        return REQUEST_OK;
    }
    else if( ret > 0 )
    {
        //only close parent connecion
        //printf("close parent connecion \n");
        //CCommon::getInstance()->removefd(m_epollfd, m_sockfd);
        close(*write_fd);
        nbytes = read(*write_fd, buf, 1024);
        printf("pipe read nbytes %d \n", nbytes);
    }
}

http_conn::HTTP_CODE http_conn::do_file_request()
{
    if ( stat( m_real_file, &m_file_stat ) < 0 )
    {
        return NO_RESOURCE;
    }

    if ( ! ( m_file_stat.st_mode & S_IROTH ) )
    {
        return FORBIDDEN_REQUEST;
    }

    if ( S_ISDIR( m_file_stat.st_mode ) )
    {
        return BAD_REQUEST;
    }

    int fd = open( m_real_file, O_RDONLY );
    m_file_address = ( char* )mmap( 0, m_file_stat.st_size, PROT_READ, MAP_PRIVATE, fd, 0 );
    close( fd );
    return FILE_REQUEST;
}
