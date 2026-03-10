CXX = g++
CXXFLAGS = -std=c++11 -Wall -pthread
LDFLAGS = -pthread

all: mpcc_server mpcc_client

mpcc_server: server/main.o server/Server.o server/ClientHandler.o server/BroadcastManager.o server/UserRegistry.o common/Logger.o
	$(CXX) $(CXXFLAGS) -o $@ $^ $(LDFLAGS)

mpcc_client: client/main.o client/Client.o common/Logger.o
	$(CXX) $(CXXFLAGS) -o $@ $^ $(LDFLAGS)

%.o: %.cpp
	$(CXX) $(CXXFLAGS) -c -o $@ $<

clean:
	rm -f mpcc_server mpcc_client server/*.o client/*.o common/*.o
