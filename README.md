# MPCC (Multi-Party Conference Chat)

MPCC is a secure, thread-per-connection concurrent chat system written in C++ with native Linux socket networking. It supports multiple clients simultaneously broadcasting encrypted messages over TCP to a centralized server. 

## Features
- **Concurrent Server:** Utilizes `pthread` to spawn individual, non-blocking threads for each connected client.
- **XOR Encrypted Communications:** All payloads, passwords, and chat messages transmit over the wire with lightweight custom XOR encryption.
- **Client Registry:** Persistent user registration and authentication mapped out of a `registered_users.dat` file.
- **Dynamic Configuration:** Host IPs and Ports are completely runtime-configurable for internal networking.
- **Standalone Delivery:** Environmentally independent installer (`mpcc_bundle.sh`) dynamically rebuilds all headers, source scripts, and makefiles without Git.

---

## Standalone Setup Instructions (For PuTTY / Secure Workstations)

If you are using an organizational PuTTY terminal and do not have access to Git to clone the repository natively, use the standalone `mpcc_bundle.sh` script to recreate the entire codebase instantly and compile the binaries.

### Step 1: Deploy the Code
1. Open your PuTTY terminal.
2. Type `nano setup-mpcc.sh` to create the file.
3. Completely copy the contents of `mpcc_bundle.sh` from your local machine and **Right-Click** inside the PuTTY window to paste.
4. Press `Ctrl+O`, hit `Enter`, and then `Ctrl+X` to save and exit.
5. Make the script executable: 
   ```bash
   chmod +x setup-mpcc.sh
   ```
6. Run the script:
   ```bash
   ./setup-mpcc.sh
   ```

*(The script will automatically unpack the C++ codebase into clean `/src` and `/include` folders, check dependencies, and compile your final executables into a new `/bin` directory).*

---

## How to Play / Run

Once compiled, you must start the server *before* any clients can connect. 

### Starting the Server (Terminal 1)
Open your first PuTTY window and start the listening server:
```bash
./bin/mpcc_server
```

### Joining the Chat room (Client Terminals)

**Scenario A: You and your friends are logged into the same Linux machine**
Open additional PuTTY terminal windows connecting to the *same server*. Since you share the machine, you connect to `127.0.0.1` (localhost).
```bash
./bin/mpcc_client 127.0.0.1 8080
```

**Scenario B: You and your friends are on different organizational Linux machines**
1. In your **Server Terminal** (before starting the server), find your machine's IP address:
   ```bash
   hostname -I
   ```
   *(E.g., `10.0.5.55`)*

2. Start your server.
3. Have your friends deploy the application on their own machines using Step 1 above. 
4. Your friends will then start their clients by connecting directly to **your IP address**:
   ```bash
   ./bin/mpcc_client 10.0.5.55 8080
   ```
   *(Note: This requires port 8080 to be unblocked across your internal organizational network).*

### Using the App
- When a client launches, it presents a menu: `1 - Register`, `2 - Login`, `3 - Exit`.
- **Register** a new username and password.
- **Login** with those credentials.
- Write your messages! Broadcasts are automatically sent to all active users. Type `exit` to disconnect.
