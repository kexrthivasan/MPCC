CXX = g++
CXXFLAGS = -std=c++11 -Wall -pthread
LDFLAGS = -pthread
BIN_DIR = bin

all: $(BIN_DIR)/mpcc_server $(BIN_DIR)/mpcc_client

SERVER_OBJS = $(BIN_DIR)/server/main.o $(BIN_DIR)/server/Server.o $(BIN_DIR)/server/ClientHandler.o $(BIN_DIR)/server/BroadcastManager.o $(BIN_DIR)/server/UserRegistry.o $(BIN_DIR)/server/Session.o $(BIN_DIR)/common/Logger.o
CLIENT_OBJS = $(BIN_DIR)/client/main.o $(BIN_DIR)/client/Client.o $(BIN_DIR)/common/Logger.o

$(BIN_DIR)/mpcc_server: $(SERVER_OBJS)
	@mkdir -p $(@D)
	$(CXX) $(CXXFLAGS) -o $@ $^ $(LDFLAGS)

$(BIN_DIR)/mpcc_client: $(CLIENT_OBJS)
	@mkdir -p $(@D)
	$(CXX) $(CXXFLAGS) -o $@ $^ $(LDFLAGS)

$(BIN_DIR)/%.o: src/%.cpp
	@mkdir -p $(@D)
	$(CXX) $(CXXFLAGS) -Iinclude -c -o $@ $<

clean:
	rm -rf $(BIN_DIR) src/server/*.o src/client/*.o src/common/*.o

