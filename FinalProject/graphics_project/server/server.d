/***
 * Class that runs a server that accepts multiple client connections.
 * A thread is spwaned for each client to broadcast packets.
 * Authors: Agastya Das, Heekyung Kim, Roydon Pereira, Jake Stringfellow, Jiayue Zhao
 */
module server;

import std.socket;
import std.stdio;
import core.thread.osthread;
import std.conv;
import core.stdc.string;

/**
Function that retrieves local IP address of server
Returns: local IP address of server as char array
*/
char[] getIP()
{
    auto r = getAddress("8.8.8.8", 53);
    auto sockfd = new Socket(AddressFamily.INET, SocketType.STREAM);

    import std.conv;

    const char[] address = r[0].toAddrString().dup;
    ushort port = to!ushort(r[0].toPortString());
    sockfd.connect(new InternetAddress(address, port));

    auto localIP = sockfd.localAddress.toAddrString().dup;
    // auto localPort = to!ushort(sockfd.localAddress.toPortString.dup);

    sockfd.shutdown(SocketShutdown.BOTH);
    sockfd.close();
    return localIP;

}

/***
 Class that runs server. 
 It uses TCP to communciate with clients.
 This code is based upon code from Professor Mike Shah's lecture. 
 */
class TCPServer
{
    /**
	Constructs a TCP Server class with given ip address and port
	Params:
		host = IP address of server (default is localhost)
		port = port to open to communicate with clients (default is 50002)
		maxConnectionsBacklog = number of pending connections the server queue will hold (default is 4)
	*/
    this(string host = "localhost", ushort port = 50_002, ushort maxConnectionsBacklog = 4)
    {

        host = to!string(getIP());
        writeln("Starting server at: ", host, ":", port);
        writeln("Server must be started before clients may join");

        mListeningSocket = new Socket(AddressFamily.INET, SocketType.STREAM);

        mListeningSocket.bind(new InternetAddress(host, port));

        mListeningSocket.listen(maxConnectionsBacklog);
    }

    /**
	Destructs the instantiated TCP Server class.
	Close all sockets upon destruction.
	*/
    ~this()
    {
        mListeningSocket.close();
    }

    /**
	Method that runs TCP server.
	It listens to client calls to join the server,
	and spawns new thread that broadcasts all received packets to clients
	*/
    void run()
    {
        bool serverIsRunning = true;
        while (serverIsRunning)
        {

            // The servers job now is to just accept connections
            writeln("Waiting to accept more connections");

            /// Accept is a blocking call.
            auto newClientSocket = mListeningSocket.accept();

            // After a new connection is accepted, let's confirm.
            writeln("Hey, a new client joined!");
            writeln("(me)", newClientSocket.localAddress(), "<---->",
                    newClientSocket.remoteAddress(), "(client)");

            // Add newly joined client's socket to array of client sockets
            mClientsConnectedToServer ~= newClientSocket;

            // Set the current client to have '0' total messages received
            mCurrentMessageToSend ~= 0;

            writeln("Friends on server = ", mClientsConnectedToServer.length);

            // Spawn a new thread for each newly joined client
            // that relay messages to clients.
            new Thread({ clientLoop(newClientSocket); }).start();

        }
    }

    /**
	Method that is spawned to listen and broadcast data recevied from client
	Params:
		clientSocket = Socket to listen and broadcast to client
	*/
    void clientLoop(Socket clientSocket)
    {
        writeln("\t Starting clientLoop:(me)", clientSocket.localAddress(),
                "<---->", clientSocket.remoteAddress(), "(client)");

        bool runThreadLoop = true;
        byte[] dummyBuffer;
        int missingBytes = 0;

        while (runThreadLoop)
        {
            // Check if the socket isAlive
            if (!clientSocket.isAlive)
            {
                // Then remove the socket
                runThreadLoop = false;
                break;
            }

            byte[32] finalBuffer;
            byte[32] receivedBuffer;

            int actualReceivedBytes;
            int expectedBytesToReceive = 32;

            actualReceivedBytes = cast(int) clientSocket.receive(receivedBuffer);

            // Check if all the bytes are received from server
            // if not, save bytes to a dummy buffer until 
            // all the bytes are received. 
            // When all the bytes are received, then broadcast to all the clients
            if (actualReceivedBytes > 0)
            {

                if (missingBytes == 0 && actualReceivedBytes < expectedBytesToReceive)
                {
                    dummyBuffer = receivedBuffer[0 .. actualReceivedBytes].dup;
                    missingBytes = expectedBytesToReceive - actualReceivedBytes;
                    continue;
                }

                if (missingBytes != 0)
                {
                    if (missingBytes < actualReceivedBytes)
                    {
                        dummyBuffer ~= receivedBuffer[0 .. missingBytes].dup;
                        finalBuffer = dummyBuffer[0 .. expectedBytesToReceive].dup;
                        dummyBuffer = [];
                        dummyBuffer = receivedBuffer[missingBytes .. actualReceivedBytes].dup;
                        missingBytes = expectedBytesToReceive - cast(int) dummyBuffer.length;
                    }
                    else if (missingBytes == actualReceivedBytes)
                    {
                        dummyBuffer ~= receivedBuffer[0 .. missingBytes].dup;
                        finalBuffer = dummyBuffer[0 .. expectedBytesToReceive].dup;
                        dummyBuffer = [];
                        missingBytes = 0;
                    }
                    else if (missingBytes > actualReceivedBytes)
                    {
                        dummyBuffer ~= receivedBuffer[0 .. actualReceivedBytes].dup;
                        missingBytes = expectedBytesToReceive = cast(int) dummyBuffer.length;
                    }
                }
                else if (missingBytes == 0 && actualReceivedBytes == expectedBytesToReceive)
                {
                    finalBuffer = receivedBuffer[0 .. expectedBytesToReceive].dup;
                }
            }

            // If all the packets are received, broadcast to all the client
            if (actualReceivedBytes > 0 && dummyBuffer.length == 0)
            {

                mServerData ~= finalBuffer;

                // Check the final buffer sending to clients
                writeln(finalBuffer);

                /// After we receive a single packet, we'll just 
                /// immedietely broadcast out to all clients some data.
                broadcastToAllClients();

            }

        }
    }

    /** 
	 Method that broadcasts packets to all the clients that are currently connected.
	 */
    void broadcastToAllClients()
    {
        foreach (idx, serverToClient; mClientsConnectedToServer)
        {
            // Send whatever the latest data was to all the 
            // clients.
            while (mCurrentMessageToSend[idx] <= mServerData.length - 1)
            {
                byte[] packet = mServerData[mCurrentMessageToSend[idx]];

                auto sent = serverToClient.send(packet[0 .. 32]);
                writeln("bytes sent: ", sent);

                // Important to increment the message only after sending
                // the previous message to as many clients as exist.
                mCurrentMessageToSend[idx]++;
            }
        }
    }

    Socket mListeningSocket; /// The listening socket is responsible for handling new client connections.
    Socket[] mClientsConnectedToServer; /// Stores the clients that are currently connected to the server.
    byte[32][] mServerData; /// Stores all of the data on the server. 
    uint[] mCurrentMessageToSend; /// Keeps track of the last message that was broadcast out to each client.
}

// Entry point to Server
void main()
{
    TCPServer server = new TCPServer;
    server.run();
}
