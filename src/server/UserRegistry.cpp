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

