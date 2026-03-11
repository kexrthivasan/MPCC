#ifndef USER_REGISTRY_H
#define USER_REGISTRY_H

#include <string>
#include <pthread.h>

class UserRegistry {
public:
    static UserRegistry& getInstance();

    bool registerUser(const std::string& username, const std::string& password);
    bool authenticateUser(const std::string& username, const std::string& password);

private:
    UserRegistry();
    ~UserRegistry();
    
    // Prevent copy and assignment
    UserRegistry(const UserRegistry&) = delete;
    UserRegistry& operator=(const UserRegistry&) = delete;

    pthread_mutex_t m_mutex;
    const std::string FILE_NAME = "registered_users.dat";
};

#endif
