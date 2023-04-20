module test.testPacket;

import Packet : Packet;

@("Test Packet Size")
unittest
{
    Packet* p = new Packet;
    assert(p.GetPacketAsBytes().sizeof == 32);
}
