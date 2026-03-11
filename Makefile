CXX = g++
CXXFLAGS = -std=c++11 -Wall -pthread
LDFLAGS = -pthread

all: mpcc_server mpcc_client

mpcc_server: src/server/main.o src/server/Server.o src/server/ClientHandler.o src/server/BroadcastManager.o src/server/UserRegistry.o src/common/Logger.o
	$(CXX) $(CXXFLAGS) -o $@ $^ $(LDFLAGS)

mpcc_client: src/client/main.o src/client/Client.o src/common/Logger.o
	$(CXX) $(CXXFLAGS) -o $@ $^ $(LDFLAGS)

%.o: %.cpp
	$(CXX) $(CXXFLAGS) -Iinclude -c -o $@ $<

clean:
	rm -f mpcc_server mpcc_client src/server/*.o src/client/*.o src/common/*.o

