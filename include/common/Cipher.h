#ifndef CIPHER_H
#define CIPHER_H

#include <string>

// Cipher: Stateless XOR encryption/decryption utility
class Cipher {
public:
    static const char KEY = 0x5A;

    // Encrypts or decrypts a string using XOR with a fixed key
    // Applied to username, password, chat messages
    static std::string process(const std::string& input) {
        std::string output = input;
        for (size_t i = 0; i < output.length(); ++i) {
            output[i] ^= KEY;
        }
        return output;
    }
};

#endif
