#include <iostream>
#include <string>
#include <cstdlib>
#include <cstring>
#include <unistd.h>
#include <netinet/in.h>
#include <sys/socket.h>

std::string getEnv(const char* key, const std::string& defaultVal) {
    const char* val = std::getenv(key);
    return val ? std::string(val) : defaultVal;
}

int main() {
    std::string appName = getEnv("APP_NAME", "unknown-cpp-app");
    std::string appPort = getEnv("APP_PORT", "8002");
    std::string logLevel = getEnv("LOG_LEVEL", "info");

    std::cout << "[" << appName << "] Starting on port " << appPort 
              << " (log_level=" << logLevel << ")" << std::endl;

    int port = std::stoi(appPort);
    int serverFd = socket(AF_INET, SOCK_STREAM, 0);

    // Biar port bisa langsung reuse kalau container direstart
    int opt = 1;
    setsockopt(serverFd, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));

    sockaddr_in address{};
    address.sin_family = AF_INET;
    address.sin_addr.s_addr = INADDR_ANY;
    address.sin_port = htons(port);

    bind(serverFd, (sockaddr*)&address, sizeof(address));
    listen(serverFd, 10);

    while (true) {
        int clientFd = accept(serverFd, nullptr, nullptr);

        std::string body = "{\"service\":\"" + appName + "\","
                           "\"port\":\"" + appPort + "\","
                           "\"log_level\":\"" + logLevel + "\","
                           "\"config_source\":\"environment variable\","
                           "\"message\":\"Config loaded successfully!\"}";

        std::string response =
            "HTTP/1.1 200 OK\r\n"
            "Content-Type: application/json\r\n"
            "Content-Length: " + std::to_string(body.size()) + "\r\n"
            "\r\n" + body;

        send(clientFd, response.c_str(), response.size(), 0);
        close(clientFd);
    }

    return 0;
}
