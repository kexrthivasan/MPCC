#ifndef BROADCAST_MANAGER_H
#define BROADCAST_MANAGER_H

#include "Session.h"
#include <vector>
#include <pthread.h>
#include <string>

class BroadcastManager {
public:
    static BroadcastManager& getInstance();

    void add_client(Session* session);
    void remove_client(Session* session);
    void broadcast(const std::string& message, Session* sender);

private:
    BroadcastManager();
    ~BroadcastManager();
    
    // Prevent copy and assignment
    BroadcastManager(const BroadcastManager&) = delete;
    BroadcastManager& operator=(const BroadcastManager&) = delete;

    std::vector<Session*> m_clients;
    pthread_mutex_t m_mutex;
};

#endif
