#ifndef LOCKER_H
#define LOCKER_H

#include <pthread.h>
#include <semaphore.h>

class CSem
{
public:
    CSem();
    ~CSem();
    bool wait();
    bool post();

private:
    sem_t m_sem;
};

class locker
{
public:
    locker();
    ~locker();
    bool lock();
    bool unlock();

private:
    pthread_mutex_t m_mutex;
};

class cond
{
public:
    cond();
    ~cond();
    bool wait();
    bool signal();

private:
    pthread_mutex_t m_mutex;
    pthread_cond_t m_cond;
};

#endif
