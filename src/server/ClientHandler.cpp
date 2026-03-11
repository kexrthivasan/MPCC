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



