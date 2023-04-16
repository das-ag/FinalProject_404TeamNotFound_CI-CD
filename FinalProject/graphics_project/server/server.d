// @file multithreaded_chat/server.d
//
// Start server first: rdmd server.d
import std.socket;
import std.stdio;
import core.thread.osthread;
import std.conv;
import core.stdc.string;
// import Packet : Packet;

/// The purpose of the TCPServer is to accept
/// multiple client connections. 
/// Every client that connects will have its own thread
/// for the server to broadcast information to each client.

char[] GetIP(){
    auto r = getAddress("8.8.8.8",53); 
    auto sockfd = new Socket(AddressFamily.INET,  SocketType.STREAM);
   
    import std.conv;
    const char[] address = r[0].toAddrString().dup;
    ushort port = to!ushort(r[0].toPortString());
    sockfd.connect(new InternetAddress(address,port));

    auto localIP = sockfd.localAddress.toAddrString().dup;

    // auto localPort = to!ushort(sockfd.localAddress.toPortString.dup);
    
    sockfd.shutdown(SocketShutdown.BOTH);
	sockfd.close();
    return localIP;
    
}

class TCPServer{
	/// Constructor
	/// By default I have choosen localhost and a port that is likely to
	/// be free.
	this(string host = "localhost", ushort port=50002, ushort maxConnectionsBacklog=4){
		
		host = to!string(GetIP());
		// host = "155.33.133.27";
		writeln("Starting server at: ", host, ":", port);
		writeln("Server must be started before clients may join");
		// Note: AddressFamily.INET tells us we are using IPv4 Internet protocol
		// Note: SOCK_STREAM (SocketType.STREAM) creates a TCP Socket
		//       If you want UDPClient and UDPServer use 'SOCK_DGRAM' (SocketType.DGRAM)
		mListeningSocket = new Socket(AddressFamily.INET, SocketType.STREAM);
		// Set the hostname and port for the socket
		// NOTE: It's possible the port number is in use if you are not able
		//  	 to connect. Try another one.
		// When we 'bind' we are assigning an address with a port to a socket.
		mListeningSocket.bind(new InternetAddress(host,port));
		// 'listen' means that a socket can 'accept' connections from another socket.
		// Allow 4 connections to be queued up in the 'backlog'
		mListeningSocket.listen(maxConnectionsBacklog);
	}

	/// Destructor
	~this(){
		// Close our server listening socket
		// TODO: If it was never opened, no need to call close
		mListeningSocket.close();
	}

	/// Call this after the server has been created
	/// to start running the server
	void run(){
		bool serverIsRunning=true;
		while(serverIsRunning){
			// Packet pp;
			// writeln("Packet size ", Packet.sizeof);
			// The servers job now is to just accept connections
			writeln("Waiting to accept more connections");
			/// accept is a blocking call.
			auto newClientSocket = mListeningSocket.accept();
			// After a new connection is accepted, let's confirm.
			writeln("Hey, a new client joined!");
			writeln("(me)",newClientSocket.localAddress(),"<---->",newClientSocket.remoteAddress(),"(client)");
			// Now pragmatically what we'll do, is spawn a new
			// thread to handle the work we want to do.
			// Per one client connection, we will create a new thread
			// in which the server will relay messages to clients.
			mClientsConnectedToServer ~= newClientSocket;
			// Set the current client to have '0' total messages received.
			// NOTE: You may not want to start from '0' here if you do not
			//       want to send a client the whole history.
			mCurrentMessageToSend ~= 0;

			writeln("Friends on server = ",mClientsConnectedToServer.length);
			// Let's send our new client friend a welcome message
			//newClientSocket.send("Hello friend\0");

			// Now we'll spawn a new thread for the client that
			// has recently joined.
			// The server will now be running multiple threads and
			// handling a chat here with clients.
			//
			// NOTE: The index sent indicates the connection in our data structures,
			//       this can be useful to identify different clients.
			new Thread({
					clientLoop(newClientSocket);
				}).start();

			// After our new thread has spawned, our server will now resume 
			// listening for more client connections to accept.
		}
	}
	

	// Function to spawn from a new thread for the client.
	// The purpose is to listen for data sent from the client 
	// and then rebroadcast that information to all other clients.
	// NOTE: passing 'clientSocket' by value so it should be a copy of 
	//       the connection.
	void clientLoop(Socket clientSocket){
			writeln("\t Starting clientLoop:(me)",clientSocket.localAddress(),"<---->",clientSocket.remoteAddress(),"(client)");
		
		bool runThreadLoop = true;
		// byte[104] receivedBuffer;
		byte[] dummyBuffer;
		int nextBytes = 0;
		int missingBytes = 0;

		while(runThreadLoop){
			// Check if the socket isAlive
			if(!clientSocket.isAlive){
				// Then remove the socket
				runThreadLoop=false;
				break;
			}

			// Message buffer will be 80 bytes 
			
			byte[32] finalBuffer;
			byte[32] receivedBuffer;
			// byte[] dummyBuffer;

			// int nextBytes;
			int actualReceivedBytes;
			int expectedBytesToReceive = 32;

			actualReceivedBytes = cast(int) clientSocket.receive(receivedBuffer);

			// writeln("ReceivedBytes:", actualReceivedBytes);

			if (actualReceivedBytes > 0) {

				writeln("first loop nextbytes: ", nextBytes);
				writeln("first loop actualReceivedBytes: ", actualReceivedBytes);
				writeln("receivedBytes: ", receivedBuffer);

				// if (nextBytes != 0) {
				// 	writeln("nextBytes: ", nextBytes);
				// 	dummyBuffer ~= receivedBuffer[0 .. nextBytes];
				// 	nextBytes = expectedBytesToReceive - actualReceivedBytes;
				// 	finalBuffer = dummyBuffer[0 .. expectedBytesToReceive].dup;
				// 	dummyBuffer = []; // flush out
				// 	dummyBuffer ~= receivedBuffer[actualReceivedBytes .. expectedBytesToReceive]; // save the remaining 
				// }

				if (missingBytes == 0 && actualReceivedBytes < expectedBytesToReceive) {
					writeln("conditio 1-1");
					dummyBuffer = receivedBuffer[0 .. actualReceivedBytes].dup;
					missingBytes = expectedBytesToReceive - actualReceivedBytes;
					writeln("dummy buffer:", dummyBuffer);
					writeln("missing bytes: ", missingBytes);
					continue;
				}


				if (missingBytes != 0) {
					if (missingBytes < actualReceivedBytes) {
						writeln("condition 2-1");
						dummyBuffer ~= receivedBuffer[0 .. missingBytes].dup;
						finalBuffer = dummyBuffer[0 .. expectedBytesToReceive].dup;
						dummyBuffer = [];
						dummyBuffer = receivedBuffer[missingBytes .. actualReceivedBytes].dup;
						missingBytes = expectedBytesToReceive - cast(int)dummyBuffer.length;
						writeln("dummy buffer:", dummyBuffer);
						writeln("final: ", missingBytes);
						writeln("missing: ", missingBytes);

					}
					else if (missingBytes == actualReceivedBytes) {
						writeln("condition 2-2");
						dummyBuffer ~= receivedBuffer[0 .. missingBytes].dup;
						finalBuffer = dummyBuffer[0 .. expectedBytesToReceive].dup;
						dummyBuffer = [];
						missingBytes = 0;
						writeln("dummy buffer:", dummyBuffer);
						writeln("final: ", missingBytes);
						writeln("missing: ", missingBytes);
					}
					else if (missingBytes > actualReceivedBytes) {
						writeln("condition 2-3");
						dummyBuffer ~= receivedBuffer[0 .. actualReceivedBytes].dup;
						missingBytes = expectedBytesToReceive = cast(int)dummyBuffer.length;
						writeln("dummy buffer:", dummyBuffer);
						writeln("final: ", missingBytes);
						writeln("missing: ", missingBytes);
					}
				}
				else if (missingBytes == 0 && actualReceivedBytes == expectedBytesToReceive) {
					finalBuffer = receivedBuffer[0 .. expectedBytesToReceive].dup;
					writeln("condition 3!");
					writeln("dummy buffer:", dummyBuffer);
					writeln("final: ", missingBytes);
					writeln("missing: ", missingBytes);
				}
			}


				
			// 	if (nextBytes == 0 && actualReceivedBytes < expectedBytesToReceive) {
			// 		// writeln("actualReceivedBytes: ", actualReceivedBytes);
			// 		nextBytes = expectedBytesToReceive - actualReceivedBytes;
			// 		dummyBuffer = receivedBuffer[0 .. actualReceivedBytes].dup;
			// 		continue;
			// 	}

			// 	if (nextBytes != 0) {
			// 		writeln("nextBytes: ", nextBytes);
			// 		dummyBuffer ~= receivedBuffer[0 .. nextBytes].dup;
			// 		// nextBytes = expectedBytesToReceive - nextBytes;
			// 		finalBuffer = dummyBuffer[0 .. expectedBytesToReceive].dup;
			// 		dummyBuffer = []; // flush out

			// 		if (actualReceivedBytes == expectedBytesToReceive) {
			// 			dummyBuffer = receivedBuffer[nextBytes .. expectedBytesToReceive].dup;
			// 		}
			// 		else{
			// 			int len = actualReceivedBytes + nextBytes;
			// 			dummyBuffer = receivedBuffer[nextBytes .. len].dup;
			// 		}
					
			// 		nextBytes = expectedBytesToReceive - cast(int)dummyBuffer.length == 104 ? 0 : expectedBytesToReceive - cast(int)dummyBuffer.length;
			// 		// writeln("final:", finalBuffer);
			// 		// writeln("dummy: ", dummyBuffer);
			// 		// writeln("nextByte for second condition: ", nextBytes);
			// 	} 
			// 	else {
					
			// 		// writeln(receivedBuffer);
			// 		writeln("received correct amount");
			// 		// writeln("nextbytes: ", nextBytes);
			// 		// writeln("actualReceivedBytes", actualReceivedBytes);
			// 		writeln(receivedBuffer);
			// 		finalBuffer = receivedBuffer[0..$].dup;
			// 	}
			// }



			// Server is now waiting to handle data from specific client
			// We'll block the server awaiting to receive a message. 	
			// auto got = clientSocket.receive(buffer);	
						
			// writeln("Received some data (bytes): ",got);
			// TODO: Note, you might want to verify 'got'
			//       is infact 80 bytes
			// byte[104] receivedBuffer;
			// byte[] totalBytes;
			// int length 
			//  = 104; // number of bytes expected;
			// int total = 0;
			// int nextBytes = 0;

			// while (total < length && (count = cast(int)clientSocket.receive(receivedBuffer)) > 0)
			// {
			// 	writeln("count of received bytes:", count);
			// 	writeln("receivedBuffer: ", receivedBuffer);
				
			// 	if (nextByte != 0) {
			// 		totalBytes ~= receivedBuffer[0 .. nextBytes].dup; 	
			// 		nextBytes = length - 
			// 	}
			// 	int left = total - count;
			// 	totalBytes ~= receivedBuffer[0 .. count].dup; // or do something else with buffer[0..count-1]
			// 	total += count;
			// }

			// buffer = totalBytes[0 .. 104];


			// if (got > 0 && got < 104) {
			// 	writeln("received bytes:", got);
			// 	writeln("partical buffer: ", buffer);
			// }

			if (actualReceivedBytes > 0 && dummyBuffer.length == 0 ) {

				// writeln("correct buffer: ", finalBuffer);

				// if (got < 104) {		
				// // 	writeln("len: ", got);
				// 	writeln("received buffer:", buffer);
				// }


				// Store data that we receive in our server.
				// We append the buffer to the end of our server
				// data structure.
				// NOTE: Probably want to make this a ring buffer,
				//       so that it does not grow infinitely.

				
				mServerData ~= finalBuffer;

				writeln(finalBuffer);

				/// After we receive a single message, we'll just 
				/// immedietely broadcast out to all clients some data.
				broadcastToAllClients();
			
			
			}
		
						
		}
	}

	/// The purpose of this function is to broadcast
	/// messages to all of the clients that are currently
	/// connected.
	void broadcastToAllClients(){
		// writeln("Broadcasting to :", mClientsConnectedToServer.length);
		foreach(idx, serverToClient; mClientsConnectedToServer){
			// Send whatever the latest data was to all the 
			// clients.
			while(mCurrentMessageToSend[idx] <= mServerData.length - 1){
				byte[] packet = mServerData[mCurrentMessageToSend[idx]];

				// writeln("sending to server:", packet[0..104]);
				// writeln("size of msg: ", packet.length);

				// auto bytesSent = serverToClient.send(packet[0 .. 104]);	

				// writeln("actual bytes sent", bytesSent);

				

				// int total = cast(int)bytesSent; // how many bytes we've sent
				// int bytesleft = 104 - cast(int)bytesSent; // how many we have left to send
				// int n = 0;

				// while(bytesleft > 0) {

				// 	n = cast(int)serverToClient.send(packet[total .. 104]);
				// 	if (n == bytesleft) { 
				// 		/* print/log error details */
				// 		break;
				// 	}
				// 	total += n;
				// 	bytesleft -= n;
				// }
				

				auto sent = serverToClient.send(packet[0 .. 32]);	
				writeln("bytes sent: ", sent);
				
				// Important to increment the message only after sending
				// the previous message to as many clients as exist.
				//memset(&packet, 0, packet.sizeof);
				mCurrentMessageToSend[idx]++;
			}
		}
	}

	/// The listening socket is responsible for handling new client connections.
	Socket 		mListeningSocket;
	/// Stores the clients that are currently connected to the server.
	Socket[] 	mClientsConnectedToServer;

	/// Stores all of the data on the server. Ideally, we'll 
	/// use this to broadcast out to clients connected.
	byte[32][] mServerData;
	/// Keeps track of the last message that was broadcast out to each client.
	uint[] 			mCurrentMessageToSend;
}

// Entry point to Server
void main(){
	// Note: I'm just using the defaults here.
	
	TCPServer server = new TCPServer;
	server.run();
}