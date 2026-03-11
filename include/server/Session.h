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
