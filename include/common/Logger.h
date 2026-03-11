#ifndef LOGGER_H
#define LOGGER_H

#include <string>
#include <pthread.h>
#include <fstream>

enum LogLevel {
    FATAL = 0,
    INFO = 1,
    WARNING = 2,
    DEBUG = 3
};

// Logger: Thread-safe logger with mutex protection
class Logger {
public:
    static Logger& getInstance();

    // Writes logs to console and mpcc_server.log
    void log(LogLevel level, const std::string& message);

private:
    Logger();
    ~Logger();
    
    // Prevent copy and assignment
    Logger(const Logger&) = delete;
    Logger& operator=(const Logger&) = delete;

    pthread_mutex_t m_mutex;
    std::ofstream m_logFile;
    const char* levelToString(LogLevel level);
};

#define LOG_FATAL(msg) Logger::getInstance().log(FATAL, msg)
#define LOG_INFO(msg)  Logger::getInstance().log(INFO, msg)
#define LOG_WARN(msg)  Logger::getInstance().log(WARNING, msg)
#define LOG_DEBUG(msg) Logger::getInstance().log(DEBUG, msg)

#endif
