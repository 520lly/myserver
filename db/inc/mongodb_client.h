/*************************************************************************
    > File Name: mongodb_client.h
    > Author: jaycee
    > Mail: jaycee_wjq@163.com
    > Date  : 19/07/16 13:50:54 +0800
 ************************************************************************/

#ifndef _MONGODB_CLIENT_H
#define _MONGODB_CLIENT_H

#include <memory>
#include "client/dbclient.h"

//query return result 
struct CDbRetReuslt
{
    int num;                           //items numbers
    mongo::BSONObj *fieldsToReturn;    //returned result collection 
};

const std::string dbname = "test"; 
const std::string hostname = "127.0.0.1";
const std::string port = "28017";

class CMongodbClient
{
public:
    enum EErrorCode
    {
        EC_OK               = 0,
        EC_NO_COLLECTION,
        EC_NO_CONDITION,
        EC_EMPTY_DATA,
        EC_QUERY_DATA,
        EC_FAILURE
    };

public:
    CMongodbClient();
    ~CMongodbClient();
    static CMongodbClient *getInstance();
    void connectMongodb();

    EErrorCode insert(const std::string &collection, const mongo::BSONObj obj, int flag = 0, const std::string &db = dbname);

    EErrorCode query(const std::string &collection, mongo::Query query, CDbRetReuslt *resulti, const std::string &db = dbname);

    EErrorCode update(const std::string &collection, mongo::Query query, mongo::BSONObj obj, bool upsert = false, bool multi = false, const std::string &db = dbname);

    EErrorCode remove(const std::string &collection, mongo::Query query, bool justone, const std::string &db = dbname);



private:
    static CMongodbClient *msp_mongodb_instance;
    mongo::DBClientConnection m_conn;

private:

};




#endif //MONGODB_CLIENT_H
