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
