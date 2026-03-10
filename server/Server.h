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
