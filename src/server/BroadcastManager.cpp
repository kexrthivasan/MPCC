#include "server/BroadcastManager.h"
#include "common/Logger.h"
#include <sys/socket.h>
#include <algorithm>
#include <iostream>

BroadcastManager& BroadcastManager::getInstance() {
    static BroadcastManager instance;
    return instance;
}

BroadcastManager::BroadcastManager() {
    pthread_mutex_init(&m_mutex, NULL);
}

BroadcastManager::~BroadcastManager() {
    pthread_mutex_destroy(&m_mutex);
}

void BroadcastManager::add_client(Session* session) {
    pthread_mutex_lock(&m_mutex);
    m_clients.push_back(session);
    LOG_INFO("Client added to BroadcastManager. IP: " + session->ip_addr);
    pthread_mutex_unlock(&m_mutex);
}

void BroadcastManager::remove_client(Session* session) {
    pthread_mutex_lock(&m_mutex);
    auto it = std::find(m_clients.begin(), m_clients.end(), session);
    if (it != m_clients.end()) {
        m_clients.erase(it);
        LOG_INFO("Client removed from BroadcastManager. IP: " + session->ip_addr);
    }
    pthread_mutex_unlock(&m_mutex);
}

void BroadcastManager::broadcast(const std::string& message, Session* sender) {
    pthread_mutex_lock(&m_mutex);
    for (Session* client : m_clients) {
        if (client != sender && client->active) {
            // Send encrypted message
            if (send(client->client_fd, message.c_str(), message.length(), 0) < 0) {
                LOG_WARN("Failed to send message to user: " + client->username);
            }
        }
    }
    pthread_mutex_unlock(&m_mutex);
}

