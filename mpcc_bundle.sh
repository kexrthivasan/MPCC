#!/bin/bash

echo 'Setting up MPCC...'

mkdir -p include/client include/common include/server src/client src/common src/server

echo 'Creating Makefile...'
cat << 'EOL_MARKER' > Makefile
CXX = g++
CXXFLAGS = -std=c++11 -Wall -pthread
LDFLAGS = -pthread
BIN_DIR = bin

all: $(BIN_DIR)/mpcc_server $(BIN_DIR)/mpcc_client

SERVER_OBJS = $(BIN_DIR)/server/main.o $(BIN_DIR)/server/Server.o $(BIN_DIR)/server/ClientHandler.o $(BIN_DIR)/server/BroadcastManager.o $(BIN_DIR)/server/UserRegistry.o $(BIN_DIR)/server/Session.o $(BIN_DIR)/common/Logger.o
CLIENT_OBJS = $(BIN_DIR)/client/main.o $(BIN_DIR)/client/Client.o $(BIN_DIR)/common/Logger.o

$(BIN_DIR)/mpcc_server: $(SERVER_OBJS)
	@mkdir -p $(@D)
	$(CXX) $(CXXFLAGS) -o $@ $^ $(LDFLAGS)

$(BIN_DIR)/mpcc_client: $(CLIENT_OBJS)
	@mkdir -p $(@D)
	$(CXX) $(CXXFLAGS) -o $@ $^ $(LDFLAGS)

$(BIN_DIR)/%.o: src/%.cpp
	@mkdir -p $(@D)
	$(CXX) $(CXXFLAGS) -Iinclude -c -o $@ $<

clean:
	rm -rf $(BIN_DIR) src/server/*.o src/client/*.o src/common/*.o

EOL_MARKER

echo 'Creating include/client/Client.h...'
cat << 'EOL_MARKER' > include/client/Client.h
#ifndef CLIENT_H
#define CLIENT_H

#include <string>

class Client {
public:
    Client(const std::string& ip, int port);
    ~Client();

    void start();

private:
    std::string m_server_ip;
    int m_port;
    int m_client_fd;
    bool m_connected;
    
    void displayMenu();
    void registerUser();
    void loginUser();
    void chatLoop();

    static void* receiveThread(void* arg);
};

#endif
EOL_MARKER

echo 'Creating include/common/Cipher.h...'
cat << 'EOL_MARKER' > include/common/Cipher.h
#ifndef CIPHER_H
#define CIPHER_H

#include <string>

// Cipher: Stateless XOR encryption/decryption utility
class Cipher {
public:
    static const char KEY = 0x5A;

    // Encrypts or decrypts a string using XOR with a fixed key
    // Applied to username, password, chat messages
    static std::string process(const std::string& input) {
        std::string output = input;
        for (size_t i = 0; i < output.length(); ++i) {
            output[i] ^= KEY;
        }
        return output;
    }
};

#endif
EOL_MARKER

echo 'Creating include/common/Logger.h...'
cat << 'EOL_MARKER' > include/common/Logger.h
#ifndef LOGGER_H
#define LOGGER_H

#include <string>
#include <pthread.h>
#include <fstream>

enum LogLevel {
    FATAL = 0,
    INFO = 1,
    WARNING = 2,
    DEBUG = 3
};

// Logger: Thread-safe logger with mutex protection
class Logger {
public:
    static Logger& getInstance();

    // Writes logs to console and mpcc_server.log
    void log(LogLevel level, const std::string& message);

private:
    Logger();
    ~Logger();
    
    // Prevent copy and assignment
    Logger(const Logger&) = delete;
    Logger& operator=(const Logger&) = delete;

    pthread_mutex_t m_mutex;
    std::ofstream m_logFile;
    const char* levelToString(LogLevel level);
};

#define LOG_FATAL(msg) Logger::getInstance().log(FATAL, msg)
#define LOG_INFO(msg)  Logger::getInstance().log(INFO, msg)
#define LOG_WARN(msg)  Logger::getInstance().log(WARNING, msg)
#define LOG_DEBUG(msg) Logger::getInstance().log(DEBUG, msg)

#endif
EOL_MARKER

echo 'Creating include/common/Message.h...'
cat << 'EOL_MARKER' > include/common/Message.h
#ifndef MESSAGE_H
#define MESSAGE_H

#include <string>

// Message Structure: represents messages exchanged between client and server
// Format: "TYPE|PAYLOAD"
enum MessageType {
    REGISTER = 1,
    LOGIN = 2,
    CHAT = 3,
    SYSTEM = 4, // for server broadcast/info
    EXIT = 5
};

class Message {
public:
    // Serializes a message
    static std::string serialize(MessageType type, const std::string& payload) {
        return std::to_string(type) + "|" + payload;
    }

    // Parses a message.
    static bool parse(const std::string& rawMsg, int& type, std::string& payload) {
        size_t delim = rawMsg.find('|');
        if (delim == std::string::npos) return false;
        
        std::string typeStr = rawMsg.substr(0, delim);
        type = std::stoi(typeStr);
        payload = rawMsg.substr(delim + 1);
        return true;
    }
};

#endif
EOL_MARKER

echo 'Creating include/server/BroadcastManager.h...'
cat << 'EOL_MARKER' > include/server/BroadcastManager.h
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
EOL_MARKER

echo 'Creating include/server/ClientHandler.h...'
cat << 'EOL_MARKER' > include/server/ClientHandler.h
#ifndef CLIENT_HANDLER_H
#define CLIENT_HANDLER_H

void* handleClient(void* arg);

#endif
EOL_MARKER

echo 'Creating include/server/Server.h...'
cat << 'EOL_MARKER' > include/server/Server.h
#ifndef SERVER_H
#define SERVER_H

class Server {
public:
    Server(int port);
    ~Server();

    void start();

private:
    int m_port;
    int m_server_fd;
};

#endif
EOL_MARKER

echo 'Creating include/server/Session.h...'
cat << 'EOL_MARKER' > include/server/Session.h
#ifndef SESSION_H
#define SESSION_H

#include <string>

// Session Class
// Stores client_fd, username, ip_addr, active flag
class Session {
public:
    Session(int fd, const std::string& ip);
    ~Session();

    int client_fd;
    std::string username;
    std::string ip_addr;
    bool active;
};

#endif
EOL_MARKER

echo 'Creating include/server/UserRegistry.h...'
cat << 'EOL_MARKER' > include/server/UserRegistry.h
#ifndef USER_REGISTRY_H
#define USER_REGISTRY_H

#include <string>
#include <pthread.h>

class UserRegistry {
public:
    static UserRegistry& getInstance();

    bool registerUser(const std::string& username, const std::string& password);
    bool authenticateUser(const std::string& username, const std::string& password);

private:
    UserRegistry();
    ~UserRegistry();
    
    // Prevent copy and assignment
    UserRegistry(const UserRegistry&) = delete;
    UserRegistry& operator=(const UserRegistry&) = delete;

    pthread_mutex_t m_mutex;
    const std::string FILE_NAME = "registered_users.dat";
};

#endif
EOL_MARKER

echo 'Creating src/client/Client.cpp...'
cat << 'EOL_MARKER' > src/client/Client.cpp
#include "client/Client.h"
#include "common/Message.h"
#include "common/Cipher.h"
#include "common/Logger.h"
#include <sys/socket.h>
#include <netdb.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <iostream>
#include <cstring>
#include <pthread.h>

Client::Client(const std::string& ip, int port) 
    : m_server_ip(ip), m_port(port), m_client_fd(-1), m_connected(false) {
}

Client::~Client() {
    if (m_client_fd >= 0) {
        close(m_client_fd);
    }
}

void Client::start() {
    m_client_fd = socket(AF_INET, SOCK_STREAM, 0);
    if (m_client_fd == -1) {
        LOG_FATAL("Failed to create socket");
        return;
    }

    // Use getaddrinfo to resolve hostname or IP address
    struct addrinfo hints, *res;
    memset(&hints, 0, sizeof(hints));
    hints.ai_family   = AF_INET;      // IPv4
    hints.ai_socktype = SOCK_STREAM;  // TCP

    std::string port_str = std::to_string(m_port);
    int status = getaddrinfo(m_server_ip.c_str(), port_str.c_str(), &hints, &res);
    if (status != 0) {
        LOG_FATAL(std::string("Could not resolve host: ") + gai_strerror(status));
        close(m_client_fd);
        m_client_fd = -1;
        return;
    }

    // Connect using the resolved address
    if (connect(m_client_fd, res->ai_addr, res->ai_addrlen) < 0) {
        LOG_FATAL("Connection Failed");
        freeaddrinfo(res);
        close(m_client_fd);
        m_client_fd = -1;
        return;
    }

    freeaddrinfo(res);
    m_connected = true;
    displayMenu();
}

void Client::displayMenu() {
    int choice;
    while (m_connected) {
        std::cout << "\n1 - Register\n2 - Login\n3 - Exit\nChoice: ";
        std::cin >> choice;
        
        if (choice == 1) {
            registerUser();
        } else if (choice == 2) {
            loginUser();
        } else if (choice == 3) {
            std::string exitMsg = Message::serialize(EXIT, "");
            send(m_client_fd, exitMsg.c_str(), exitMsg.length(), 0);
            m_connected = false;
            break;
        } else {
            std::cout << "Invalid choice.\n";
            std::cin.clear();
            std::cin.ignore(10000, '\n');
        }
    }
}

void Client::registerUser() {
    std::string user, pass;
    std::cout << "Enter username: ";
    std::cin >> user;
    std::cout << "Enter password: ";
    std::cin >> pass;
    
    std::string payload = Cipher::process(user) + ":" + Cipher::process(pass);
    std::string msg = Message::serialize(REGISTER, payload);
    
    send(m_client_fd, msg.c_str(), msg.length(), 0);
    
    char buffer[1024] = {0};
    int bytes_read = recv(m_client_fd, buffer, sizeof(buffer) - 1, 0);
    if (bytes_read > 0) {
        int type;
        std::string resp_payload;
        if (Message::parse(std::string(buffer), type, resp_payload)) {
            if (type == SYSTEM) {
                std::cout << "\nServer: " << Cipher::process(resp_payload) << "\n";
            }
        }
    }
}

void Client::loginUser() {
    std::string user, pass;
    std::cout << "Enter username: ";
    std::cin >> user;
    std::cout << "Enter password: ";
    std::cin >> pass;
    
    std::string payload = Cipher::process(user) + ":" + Cipher::process(pass);
    std::string msg = Message::serialize(LOGIN, payload);
    
    send(m_client_fd, msg.c_str(), msg.length(), 0);
    
    char buffer[1024] = {0};
    int bytes_read = recv(m_client_fd, buffer, sizeof(buffer) - 1, 0);
    if (bytes_read > 0) {
        int type;
        std::string resp_payload;
        if (Message::parse(std::string(buffer), type, resp_payload)) {
            if (type == SYSTEM) {
                std::string serverMsg = Cipher::process(resp_payload);
                std::cout << "\nServer: " << serverMsg << "\n";
                if (serverMsg.find("successful") != std::string::npos) {
                    chatLoop();
                }
            }
        }
    }
}

// Thread function specifically running to constantly check for incoming broadcast messages 
// so the CLI doesn't block while waiting for user input via standard in (std::cin).
void* Client::receiveThread(void* arg) {
    Client* client = static_cast<Client*>(arg);
    char buffer[1024];

    while (client->m_connected) {
        memset(buffer, 0, sizeof(buffer));
        
        // Blocking socket receive call. Will hold execution of this specific thread 
        // until the MPCC server sends a payload or closes the socket.
        int bytes_read = recv(client->m_client_fd, buffer, sizeof(buffer) - 1, 0);
        
        if (bytes_read <= 0) {
            std::cout << "\nDisconnected from server.\n";
            client->m_connected = false;
            break;
        }

        int type;
        std::string payload;
        // The message type could be SYSTEM (like join/leave) or CHAT (user messages)
        if (Message::parse(std::string(buffer), type, payload)) {
            if (type == CHAT) {
                std::cout << "\n" << Cipher::process(payload) << "\n";
            } else if (type == SYSTEM) {
                std::cout << "\n[System]: " << Cipher::process(payload) << "\n";
            }
        }
    }
    return NULL;
}

void Client::chatLoop() {
    std::cout << "\n--- Entered Chat Mode ---\nType 'exit' or 'quit' to disconnect.\n";

    pthread_t recv_thread;
    pthread_create(&recv_thread, NULL, receiveThread, this);

    std::string input;
    std::cin.ignore(10000, '\n');
    while (m_connected) {
        std::getline(std::cin, input);
        
        if (input == "exit" || input == "quit" || input == "EXIT") {
            std::string payload = Cipher::process("EXIT"); 
            std::string exitMsg = Message::serialize(CHAT, payload);
            send(m_client_fd, exitMsg.c_str(), exitMsg.length(), 0);
            m_connected = false;
            break;
        }

        if (!input.empty() && m_connected) {
            std::string payload = Cipher::process(input);
            std::string chatMsg = Message::serialize(CHAT, payload);
            send(m_client_fd, chatMsg.c_str(), chatMsg.length(), 0);
        }
    }
    
    // Wait for receive thread to exit
    pthread_join(recv_thread, NULL);
}



EOL_MARKER

echo 'Creating src/client/main.cpp...'
cat << 'EOL_MARKER' > src/client/main.cpp
#include "client/Client.h"
#include <string>
#include <cstdlib>
#include <iostream>

int main(int argc, char* argv[]) {
    // Default server address; override with: ./mpcc_client <ip> <port>
    std::string server_ip = "127.0.0.1";
    int port = 8080;

    if (argc >= 2) {
        server_ip = argv[1];
    }
    if (argc >= 3) {
        port = std::atoi(argv[2]);
    }

    std::cout << "Connecting to " << server_ip << ":" << port << "...\n";
    Client client(server_ip, port);
    client.start();
    return 0;
}



EOL_MARKER

echo 'Creating src/common/Logger.cpp...'
cat << 'EOL_MARKER' > src/common/Logger.cpp
#include "common/Logger.h"
#include <iostream>
#include <ctime>

Logger& Logger::getInstance() {
    static Logger instance;
    return instance;
}

Logger::Logger() {
    pthread_mutex_init(&m_mutex, NULL);
    m_logFile.open("mpcc_server.log", std::ios::app);
}

Logger::~Logger() {
    m_logFile.close();
    pthread_mutex_destroy(&m_mutex);
}

const char* Logger::levelToString(LogLevel level) {
    switch(level) {
        case FATAL: return "FATAL";
        case INFO: return "INFO";
        case WARNING: return "WARNING";
        case DEBUG: return "DEBUG";
        default: return "UNKNOWN";
    }
}

void Logger::log(LogLevel level, const std::string& message) {
    // Thread-safe logger with mutex protection
    pthread_mutex_lock(&m_mutex);
    
    // Get current time
    time_t rawtime;
    struct tm * timeinfo;
    char buffer[80];
    time(&rawtime);
    timeinfo = localtime(&rawtime);
    strftime(buffer, sizeof(buffer), "%Y-%m-%d %H:%M:%S", timeinfo);
    
    std::string logMsg = std::string("[") + buffer + "] [" + levelToString(level) + "] " + message;
    
    // Writes logs to console (flushed immediately)
    std::cout << logMsg << std::endl;
    std::cout.flush();
    // Writes logs to mpcc_server.log
    if (m_logFile.is_open()) {
        m_logFile << logMsg << std::endl;
        m_logFile.flush();
    }
    
    pthread_mutex_unlock(&m_mutex);
}


EOL_MARKER

echo 'Creating src/server/BroadcastManager.cpp...'
cat << 'EOL_MARKER' > src/server/BroadcastManager.cpp
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

EOL_MARKER

echo 'Creating src/server/ClientHandler.cpp...'
cat << 'EOL_MARKER' > src/server/ClientHandler.cpp
#include "server/ClientHandler.h"
#include "server/Session.h"
#include "server/UserRegistry.h"
#include "server/BroadcastManager.h"
#include "common/Message.h"
#include "common/Cipher.h"
#include "common/Logger.h"
#include <sys/socket.h>
#include <unistd.h>
#include <cstring>
#include <iostream>

void* handleClient(void* arg) {
    Session* session = static_cast<Session*>(arg);
    char buffer[2048];

    // Read loop
    while (session->active) {
        memset(buffer, 0, sizeof(buffer));
        int bytes_read = recv(session->client_fd, buffer, sizeof(buffer) - 1, 0);
        
        if (bytes_read <= 0) {
            LOG_INFO("Client disconnected. IP: " + session->ip_addr);
            session->active = false;
            break;
        }

        std::string rawMsg(buffer);
        int type;
        std::string payload;

        if (!Message::parse(rawMsg, type, payload)) {
            LOG_WARN("Invalid message format received from IP: " + session->ip_addr);
            continue;
        }

        switch (type) {
            case REGISTER: {
                // The received payload format from the client is: encrypted_username:encrypted_password
                size_t delim = payload.find(':');
                if (delim != std::string::npos) {
                    std::string user = payload.substr(0, delim);
                    std::string pass = payload.substr(delim + 1);
                    
                    // XOR Decrypt credentials to use them for registration
                    user = Cipher::process(user);
                    pass = Cipher::process(pass);
                    
                    // Hand off to UserRegistry for persistent storage of credentials
                    if (UserRegistry::getInstance().registerUser(user, pass)) {
                        LOG_INFO("User registered successfully: " + user);
                        std::string resp = Message::serialize(SYSTEM, Cipher::process("Registration successful. You can login now."));
                        send(session->client_fd, resp.c_str(), resp.length(), 0);
                    } else {
                        LOG_WARN("Failed registration for user: " + user);
                        std::string resp = Message::serialize(SYSTEM, Cipher::process("Registration failed. User may already exist."));
                        send(session->client_fd, resp.c_str(), resp.length(), 0);
                    }
                }
                break;
            }
            case LOGIN: {
                size_t delim = payload.find(':');
                if (delim != std::string::npos) {
                    std::string user = payload.substr(0, delim);
                    std::string pass = payload.substr(delim + 1);
                    
                    user = Cipher::process(user);
                    pass = Cipher::process(pass);
                    
                    if (UserRegistry::getInstance().authenticateUser(user, pass)) {
                        LOG_INFO("User logged in successfully: " + user);
                        session->username = user;
                        BroadcastManager::getInstance().add_client(session);
                        
                        std::string resp = Message::serialize(SYSTEM, Cipher::process("Login successful. Welcome to MPCC!"));
                        send(session->client_fd, resp.c_str(), resp.length(), 0);
                        
                        // broadcast entry
                        std::string joinMsg = session->username + " has joined the chat.";
                        std::string encryptedJoin = Cipher::process(joinMsg);
                        std::string bcastMsg = Message::serialize(CHAT, encryptedJoin);
                        BroadcastManager::getInstance().broadcast(bcastMsg, session);
                    } else {
                        LOG_WARN("Failed login for user: " + user);
                        std::string resp = Message::serialize(SYSTEM, Cipher::process("Login failed. Check credentials."));
                        send(session->client_fd, resp.c_str(), resp.length(), 0);
                    }
                }
                break;
            }
            case CHAT: {
                if (session->username == "Guest") {
                    std::string resp = Message::serialize(SYSTEM, Cipher::process("Please login first."));
                    send(session->client_fd, resp.c_str(), resp.length(), 0);
                } else {
                    // payload is encrypted chat message. Let's decrypt, prepend username, encrypt and broadcast
                    std::string decrypted_chat = Cipher::process(payload);
                    if (decrypted_chat == "EXIT" || decrypted_chat == "exit" || decrypted_chat == "quit") {
                        session->active = false;
                    } else {
                        LOG_DEBUG("Chat from " + session->username + ": " + decrypted_chat);
                        std::string broadcast_text = "[" + session->username + "]: " + decrypted_chat;
                        std::string encrypted_broadcast = Cipher::process(broadcast_text);
                        std::string bcastMsg = Message::serialize(CHAT, encrypted_broadcast);
                        BroadcastManager::getInstance().broadcast(bcastMsg, session);
                    }
                }
                break;
            }
            case EXIT: {
                session->active = false;
                break;
            }
            default:
                LOG_WARN("Unknown message type received from IP: " + session->ip_addr);
                break;
        }
    }

    if (session->username != "Guest") {
        BroadcastManager::getInstance().remove_client(session);
        std::string leaveMsg = session->username + " has left the chat.";
        std::string encryptedLeave = Cipher::process(leaveMsg);
        std::string bcastMsg = Message::serialize(CHAT, encryptedLeave);
        BroadcastManager::getInstance().broadcast(bcastMsg, session);
    }
    
    // Clean up
    delete session;
    return NULL;
}



EOL_MARKER

echo 'Creating src/server/Server.cpp...'
cat << 'EOL_MARKER' > src/server/Server.cpp
#include "server/Server.h"
#include "server/ClientHandler.h"
#include "server/Session.h"
#include "common/Logger.h"
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

EOL_MARKER

echo 'Creating src/server/Session.cpp...'
cat << 'EOL_MARKER' > src/server/Session.cpp
#include "server/Session.h"
#include <unistd.h>
#include "common/Logger.h"

Session::Session(int fd, const std::string& ip) 
    : client_fd(fd), username("Guest"), ip_addr(ip), active(true) {
}

Session::~Session() {
    if (client_fd >= 0) {
        close(client_fd);
    }
}

EOL_MARKER

echo 'Creating src/server/UserRegistry.cpp...'
cat << 'EOL_MARKER' > src/server/UserRegistry.cpp
#include "server/UserRegistry.h"
#include "common/Cipher.h"
#include "common/Logger.h"
#include <fstream>
#include <iostream>

UserRegistry& UserRegistry::getInstance() {
    static UserRegistry instance;
    return instance;
}

UserRegistry::UserRegistry() {
    pthread_mutex_init(&m_mutex, NULL);
}

UserRegistry::~UserRegistry() {
    pthread_mutex_destroy(&m_mutex);
}

bool UserRegistry::registerUser(const std::string& username, const std::string& password) {
    pthread_mutex_lock(&m_mutex);
    
    // Check if user exists
    std::ifstream infile(FILE_NAME);
    std::string line;
    bool exists = false;
    while (std::getline(infile, line)) {
        size_t delim = line.find(':');
        if (delim != std::string::npos) {
            std::string u = line.substr(0, delim);
            if (u == username) {
                exists = true;
                break;
            }
        }
    }
    infile.close();

    if (exists) {
        pthread_mutex_unlock(&m_mutex);
        return false;
    }

    // Encrypt password before storing
    std::string encrypted_pw = Cipher::process(password);
    
    std::ofstream outfile(FILE_NAME, std::ios::app);
    if (!outfile.is_open()) {
        LOG_FATAL("Failed to open registered_users.dat for writing");
        pthread_mutex_unlock(&m_mutex);
        return false;
    }
    
    // registered_users.dat stores user data in the format: username:encrypted_password
    outfile << username << ":" << encrypted_pw << "\n";
    outfile.close();
    
    pthread_mutex_unlock(&m_mutex);
    return true;
}

bool UserRegistry::authenticateUser(const std::string& username, const std::string& password) {
    pthread_mutex_lock(&m_mutex);
    
    std::ifstream infile(FILE_NAME);
    if (!infile.is_open()) {
        LOG_WARN("registered_users.dat not found, no users registered yet");
        pthread_mutex_unlock(&m_mutex);
        return false;
    }

    std::string line;
    bool authenticated = false;
    while (std::getline(infile, line)) {
        size_t delim = line.find(':');
        if (delim != std::string::npos) {
            std::string u = line.substr(0, delim);
            std::string p = line.substr(delim + 1);
            if (u == username) {
                // Decrypt password
                std::string decrypted_pw = Cipher::process(p);
                if (decrypted_pw == password) {
                    authenticated = true;
                }
                break;
            }
        }
    }
    infile.close();
    
    pthread_mutex_unlock(&m_mutex);
    return authenticated;
}

EOL_MARKER

echo 'Creating src/server/main.cpp...'
cat << 'EOL_MARKER' > src/server/main.cpp
#include "server/Server.h"
#include "common/Logger.h"

int main() {
    LOG_INFO("Starting MPCC Server...");
    Server server(8080);
    server.start();
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

EOL_MARKER

echo 'Creating src/server/Session.cpp...'
cat << 'EOL_MARKER' > src/server/Session.cpp
#include "server/Session.h"
#include <unistd.h>
#include "common/Logger.h"

Session::Session(int fd, const std::string& ip) 
    : client_fd(fd), username("Guest"), ip_addr(ip), active(true) {
}

Session::~Session() {
    if (client_fd >= 0) {
        close(client_fd);
    }
}

EOL_MARKER

echo 'Creating src/server/UserRegistry.cpp...'
cat << 'EOL_MARKER' > src/server/UserRegistry.cpp
#include "server/UserRegistry.h"
#include "common/Cipher.h"
#include "common/Logger.h"
#include <fstream>
#include <iostream>

UserRegistry& UserRegistry::getInstance() {
    static UserRegistry instance;
    return instance;
}

UserRegistry::UserRegistry() {
    pthread_mutex_init(&m_mutex, NULL);
}

UserRegistry::~UserRegistry() {
    pthread_mutex_destroy(&m_mutex);
}

bool UserRegistry::registerUser(const std::string& username, const std::string& password) {
    pthread_mutex_lock(&m_mutex);
    
    // Check if user exists
    std::ifstream infile(FILE_NAME);
    std::string line;
    bool exists = false;
    while (std::getline(infile, line)) {
        size_t delim = line.find(':');
        if (delim != std::string::npos) {
            std::string u = line.substr(0, delim);
            if (u == username) {
                exists = true;
                break;
            }
        }
    }
    infile.close();

    if (exists) {
        pthread_mutex_unlock(&m_mutex);
        return false;
    }

    // Encrypt password before storing
    std::string encrypted_pw = Cipher::process(password);
    
    std::ofstream outfile(FILE_NAME, std::ios::app);
    if (!outfile.is_open()) {
        LOG_FATAL("Failed to open registered_users.dat for writing");
        pthread_mutex_unlock(&m_mutex);
        return false;
    }
    
    // registered_users.dat stores user data in the format: username:encrypted_password
    outfile << username << ":" << encrypted_pw << "\n";
    outfile.close();
    
    pthread_mutex_unlock(&m_mutex);
    return true;
}

bool UserRegistry::authenticateUser(const std::string& username, const std::string& password) {
    pthread_mutex_lock(&m_mutex);
    
    std::ifstream infile(FILE_NAME);
    if (!infile.is_open()) {
        LOG_WARN("registered_users.dat not found, no users registered yet");
        pthread_mutex_unlock(&m_mutex);
        return false;
    }

    std::string line;
    bool authenticated = false;
    while (std::getline(infile, line)) {
        size_t delim = line.find(':');
        if (delim != std::string::npos) {
            std::string u = line.substr(0, delim);
            std::string p = line.substr(delim + 1);
            if (u == username) {
                // Decrypt password
                std::string decrypted_pw = Cipher::process(p);
                if (decrypted_pw == password) {
                    authenticated = true;
                }
                break;
            }
        }
    }
    infile.close();
    
    pthread_mutex_unlock(&m_mutex);
    return authenticated;
}

EOL_MARKER

echo 'Creating src/server/main.cpp...'
cat << 'EOL_MARKER' > src/server/main.cpp
#include "server/Server.h"
#include "common/Logger.h"

int main() {
    LOG_INFO("Starting MPCC Server...");
    Server server(8080);
    server.start();
    return 0;
}

EOL_MARKER

echo 'Building MPCC...'
make clean && make all
echo '========================================'
echo '        MPCC BUILD SUCCESSFUL!          '
echo '========================================'
echo 'To start the Server (Terminal 1):'
echo '   ./bin/mpcc_server'
echo ''
echo 'To start Client 1 (Terminal 2):'
echo '   ./bin/mpcc_client 127.0.0.1 8080'
echo '   1) Select 1 to Register a username/password'
echo '   2) Select 2 to Login'
echo ''
echo 'To start Client 2 (Terminal 3):'
echo '   ./bin/mpcc_client 127.0.0.1 8080'
echo '   1) Select 1 to Register a different username/password'
echo '   2) Select 2 to Login'
echo ''
echo 'To stop everything:'
echo '   Press Ctrl+C in Terminal 1'
echo '========================================'
