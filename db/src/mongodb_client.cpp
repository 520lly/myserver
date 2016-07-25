/*************************************************************************
	> File Name: db/mongodb_client.cpp
	> Author: jaycee
	> Mail: jaycee_wjq@163.com
    > Date  : 19/07/16 13:55:04 +0800
 ************************************************************************/

#include "mongodb_client.h"


using namespace mongo;
using std::auto_ptr;
using std::string;

CMongodbClient *CMongodbClient::msp_mongodb_instance = NULL;

CMongodbClient::CMongodbClient()
{

}

CMongodbClient::~CMongodbClient()
{
    if(msp_mongodb_instance != NULL)
    {
        delete msp_mongodb_instance;
        msp_mongodb_instance = NULL;
    }

}

CMongodbClient *CMongodbClient::getInstance()
{
   if (msp_mongodb_instance == NULL )
   {
       msp_mongodb_instance = new CMongodbClient();
   }
   return msp_mongodb_instance;
}

void CMongodbClient::connectMongodb()
{
    bool auto_connect = true;
    double so_timeout = 3;
    string errmessg = "";
    try 
    {
        mongo::client::initialize();
        clock_t start = clock();
        if (!m_conn.connect(hostname, errmessg))
        {
            printf("mongo client Connection failure! errmessg: %s\n", errmessg.c_str());
        }
        else
        {
            printf("mongo client Connection successfully!\n");
            printf("mongo server address %s\n",m_conn.getServerAddress().c_str());
            printf("collection nums %d \n",m_conn.getNumConnections());
            printf("host info %s\n",m_conn.getServerHostAndPort().toString().c_str());
            if(m_conn.createCollection(dbname))
            {
                printf("create collection successfully!\n");
            }
            else
            {
                printf("create collection failure!\n");
            }
        }
        clock_t finish = clock();
        printf("time: %f\n",(double)(finish - start)/CLOCKS_PER_SEC);
    } 
    catch( DBException &e ) 
    {
        printf("mongo client Connection failure!\n");
    }
}

CMongodbClient::EErrorCode CMongodbClient::query(const string &collection, Query query, CDbRetReuslt *result, const string &db)
{
    if (collection.compare("") == 0)
    {
        printf("not define collection\n");
        return EC_NO_COLLECTION;
    }
    if (query.toString().compare("") == 0)
    {
        return EC_NO_CONDITION;
        printf("not define condition\n");
    }
    int item_num = 0;
    int item_skip = 0;
    string ns = db + "." + collection;

    auto_ptr<DBClientCursor> cursor;
    try
    {
        printf("is still connected %d\n",m_conn.isStillConnected());
        if(m_conn.isStillConnected() && m_conn.exists(ns))
        {
            printf("query: %s \n",query.toString().c_str());
            cursor = m_conn.query(ns, query, item_num, item_skip, 0, 0);
        }
        string err = m_conn.getLastError();
        if (err.compare("") != 0)
        {
            printf("last errmessg: %s\n", err.c_str());
        }
    }
    catch( DBException &e )
    {
        return EC_FAILURE;
    }

    while(cursor->more())
    {
        BSONObj obj = cursor->next();
        printf("filename %s\n",obj["fname"].toString().c_str());
    }

    return EC_OK; 
}

CMongodbClient::EErrorCode CMongodbClient::insert(const std::string &collection, const mongo::BSONObj obj, int flag, const std::string &db)
{
    if (collection.compare("") == 0)
    {
        printf("not define collection\n");
        return EC_NO_COLLECTION;
    }
    if (obj.toString().compare("") == 0)
    {
        printf("empty obj data\n");
        return EC_EMPTY_DATA;
    }

    string ns = db + "." + collection;
    printf("table name is: %s\n",ns.c_str());
    try
    {
        printf("is still connected %d\n",m_conn.isStillConnected());
        if(m_conn.isStillConnected() && m_conn.exists(ns) && !(m_conn.query(ns, obj)->more()))
        {
            printf("insert %s \n",obj.toString().c_str());
            m_conn.insert(ns, obj, flag);
        }
        string err = m_conn.getLastError();
        if (err.compare("") != 0)
        {
            printf("last errmessg: %s\n", err.c_str());
        }
    }
    catch( DBException &e )
    {
        return EC_FAILURE;
    }

    return EC_OK;
}

CMongodbClient::EErrorCode CMongodbClient::update(const string &collection, Query query, BSONObj obj, bool upsert, bool multi, const string &db)
{
    if (collection.compare("") == 0)
    {
        printf("not define collection\n");
        return EC_NO_COLLECTION;
    }
    if (obj.toString().compare("") == 0)
    {
        printf("empty obj data\n");
        return EC_EMPTY_DATA;
    }   
    if(query.toString().compare("") ==0 )
    {
        printf("empty query data\n");
        return EC_QUERY_DATA;
    }

    string ns = db + "." + collection;
    printf("table name is: %s\n",ns.c_str());
    try
    {
        printf("is still connected %d\n",m_conn.isStillConnected());
        if(m_conn.isStillConnected() && m_conn.exists(ns))
        {
            printf("update: query %s obj: %s\n",query.toString().c_str(), obj.toString().c_str());
            m_conn.update(ns, query, obj, upsert, multi);
        }
        string err = m_conn.getLastError();
        if (err.compare("") != 0)
        {
            printf("last errmessg: %s\n", err.c_str());
        }
    }
    catch( DBException &e )
    {
        return EC_FAILURE;
    }

    return EC_OK;
}

CMongodbClient::EErrorCode CMongodbClient::remove(const string &collection, Query query, bool justone, const string &db)
{
    if (collection.compare("") == 0)
    {
        printf("not define collection\n");
        return EC_NO_COLLECTION;
    }
    if(query.toString().compare("") ==0 )
    {
        printf("empty query data\n");
        return EC_QUERY_DATA;
    }

    string ns = db + "." + collection;
    printf("table name is: %s\n",ns.c_str());
    try
    {
        printf("is still connected %d\n",m_conn.isStillConnected());
        if(m_conn.isStillConnected() && m_conn.exists(ns))
        {
            printf("remove: query %s \n",query.toString().c_str());
            m_conn.remove(ns, query, justone);
        }
        string err = m_conn.getLastError();
        if (err.compare("") != 0)
        {
            printf("last errmessg: %s\n", err.c_str());
        }
    }
    catch( DBException &e )
    {
        return EC_FAILURE;
    }

    return EC_OK;   
}





