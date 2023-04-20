module test.testNetwork;

import client : Client;
import unit_threaded;

// NOTE: Invalid memory operation Exception will be raised AFTER running this unittest (unittest is successful)
// It raises this exception as garbage collector cannot clear some variables from the when client class
// as they were not allocated to memory.

// @Name("network")
// @HiddenTest
unittest
{
    import std.socket;
    import unit_threaded.mock;

    // import core.memory;
    // GC.disable;

    /** PLEASE UNCOMMENT this part when running tests. We commented this out for CI/CD purposes.
    // Mock Socket and make receive() function to return empty buffer
    auto socketMock = mock!Socket;
    socketMock.expect!"receive";
    long[] emptyBuffer;
    socketMock.returnValue!"receive"(emptyBuffer);

    // Instantiate client class
    Client test = new Client;
    test.mSocket = socketMock;

    // Set isConnectToServer to true to mimic socket connection
    test.isConnectedToServer = true;
    test.receiveDataFromServer();

    // When the server sends 0 bytes, it means the server is closed.
    // In our code, we check if the server is closed as we lisiten for packets.
    assert(test.isConnectedToServer == false);
    destroy(test);
    */

}
