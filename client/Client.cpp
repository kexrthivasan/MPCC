#include "Client.h"
#include "../common/Message.h"
#include "../common/Cipher.h"
#include "../common/Logger.h"
#include <sys/socket.h>
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

    struct sockaddr_in server_addr;
    memset(&server_addr, 0, sizeof(server_addr));
    server_addr.sin_family = AF_INET;
    server_addr.sin_port = htons(m_port);

    if (inet_pton(AF_INET, m_server_ip.c_str(), &server_addr.sin_addr) <= 0) {
        LOG_FATAL("Invalid address / Address not supported");
        return;
    }

    if (connect(m_client_fd, (struct sockaddr*)&server_addr, sizeof(server_addr)) < 0) {
        LOG_FATAL("Connection Failed");
        return;
    }

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

void* Client::receiveThread(void* arg) {
    Client* client = static_cast<Client*>(arg);
    char buffer[1024];

    while (client->m_connected) {
        memset(buffer, 0, sizeof(buffer));
        int bytes_read = recv(client->m_client_fd, buffer, sizeof(buffer) - 1, 0);
        
        if (bytes_read <= 0) {
            std::cout << "\nDisconnected from server.\n";
            client->m_connected = false;
            break;
        }

        int type;
        std::string payload;
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
