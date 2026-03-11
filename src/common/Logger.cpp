#include "common/Logger.h"
#include <iostream>
#include <ctime>

Logger& Logger::getInstance() {
    static Logger instance;
    return instance;
}

Logger::Logger() {
    pthread_mutex_init(&m_mutex, NULL);
    m_logFile.open("mpcc_server.log", std::ios::app);
}

Logger::~Logger() {
    m_logFile.close();
    pthread_mutex_destroy(&m_mutex);
}

const char* Logger::levelToString(LogLevel level) {
    switch(level) {
        case FATAL: return "FATAL";
        case INFO: return "INFO";
        case WARNING: return "WARNING";
        case DEBUG: return "DEBUG";
        default: return "UNKNOWN";
    }
}

void Logger::log(LogLevel level, const std::string& message) {
    // Thread-safe logger with mutex protection
    pthread_mutex_lock(&m_mutex);
    
    // Get current time
    time_t rawtime;
    struct tm * timeinfo;
    char buffer[80];
    time(&rawtime);
    timeinfo = localtime(&rawtime);
    strftime(buffer, sizeof(buffer), "%Y-%m-%d %H:%M:%S", timeinfo);
    
    std::string logMsg = std::string("[") + buffer + "] [" + levelToString(level) + "] " + message;
    
    // Writes logs to console (flushed immediately)
    std::cout << logMsg << std::endl;
    std::cout.flush();
    // Writes logs to mpcc_server.log
    if (m_logFile.is_open()) {
        m_logFile << logMsg << std::endl;
        m_logFile.flush();
    }
    
    pthread_mutex_unlock(&m_mutex);
}


