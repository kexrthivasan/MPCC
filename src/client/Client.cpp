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



