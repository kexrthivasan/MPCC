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

