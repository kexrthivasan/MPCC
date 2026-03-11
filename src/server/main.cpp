#include "server/Server.h"
#include "common/Logger.h"

int main() {
    LOG_INFO("Starting MPCC Server...");
    Server server(8080);
    server.start();
    return 0;
}

