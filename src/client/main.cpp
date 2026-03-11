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



