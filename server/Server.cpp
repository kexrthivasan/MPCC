#include "Server.h"
#include "ClientHandler.h"
#include "Session.h"
#include "../common/Logger.h"
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <pthread.h>
#include <cstring>
#include <iostream>

Server::Server(int port) : m_port(port), m_server_fd(-1) {
}

Server::~Server() {
    if (m_server_fd >= 0) {
        close(m_server_fd);
    }
}

void Server::start() {
    m_server_fd = socket(AF_INET, SOCK_STREAM, 0);
    if (m_server_fd == -1) {
        LOG_FATAL("Failed to create socket");
        return;
    }

    struct sockaddr_in server_addr;
    memset(&server_addr, 0, sizeof(server_addr));
    server_addr.sin_family = AF_INET;
    server_addr.sin_addr.s_addr = INADDR_ANY;
    server_addr.sin_port = htons(m_port);

    if (bind(m_server_fd, (struct sockaddr*)&server_addr, sizeof(server_addr)) < 0) {
        LOG_FATAL("Failed to bind to port " + std::to_string(m_port));
        return;
    }

    if (listen(m_server_fd, 10) < 0) {
        LOG_FATAL("Failed to listen on socket");
        return;
    }

    LOG_INFO("Server started, listening on port " + std::to_string(m_port));

    while (true) {
        struct sockaddr_in client_addr;
        socklen_t client_len = sizeof(client_addr);
        
        int client_fd = accept(m_server_fd, (struct sockaddr*)&client_addr, &client_len);
        if (client_fd < 0) {
            LOG_WARN("Failed to accept client connection");
            continue;
        }

        std::string ip = inet_ntoa(client_addr.sin_addr);
        LOG_INFO("Accepted new connection from IP: " + ip);

        // Memory Management: Session objects allocated with new on connection
        Session* session = new Session(client_fd, ip);
        
        pthread_t thread_id;
        // Concurrent Server: Server must support multiple clients simultaneously.
        // Use pthread_create() to spawn a new thread per client.
        if (pthread_create(&thread_id, NULL, handleClient, session) != 0) {
            LOG_WARN("Failed to create thread for client IP: " + ip);
            delete session;
            continue;
        }
        
        pthread_detach(thread_id);
    }
}
