#ifndef MESSAGE_H
#define MESSAGE_H

#include <string>

// Message Structure: represents messages exchanged between client and server
// Format: "TYPE|PAYLOAD"
enum MessageType {
    REGISTER = 1,
    LOGIN = 2,
    CHAT = 3,
    SYSTEM = 4, // for server broadcast/info
    EXIT = 5
};

class Message {
public:
    // Serializes a message
    static std::string serialize(MessageType type, const std::string& payload) {
        return std::to_string(type) + "|" + payload;
    }

    // Parses a message.
    static bool parse(const std::string& rawMsg, int& type, std::string& payload) {
        size_t delim = rawMsg.find('|');
        if (delim == std::string::npos) return false;
        
        std::string typeStr = rawMsg.substr(0, delim);
        type = std::stoi(typeStr);
        payload = rawMsg.substr(delim + 1);
        return true;
    }
};

#endif
