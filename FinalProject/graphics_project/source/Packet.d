/***
 * Struct that defines packet for network
 */
module Packet;

import std.stdio;
import core.stdc.string;

/**
Struct that defines Packet for network
*/
struct Packet
{

    char[16] user; /// name of client
    int x; /// x coordinate of the pixel
    int y; /// y coordinate of the pixel
    ubyte r; /// r value of the pixel
    ubyte g; /// g value of the pixel
    ubyte b; /// b value of the pixel
    ubyte brushStrokeType; /// type of paint brush (e.g square, circle, heart)
    ubyte brushStrokeSize; /// size of brush

    /**
    Method that converts Packet into an array of bytes for serialization
    Returns: an array of bytes that are serialized
    */
    byte[Packet.sizeof] GetPacketAsBytes()
    {

        byte[Packet.sizeof] payload;

        // TODO: change client name
        user = "client1\0";

        memmove(&payload, &user, user.sizeof);

        import std.stdio;

        memmove(&payload[16], &x, x.sizeof);
        memmove(&payload[20], &y, y.sizeof);
        memmove(&payload[24], &r, r.sizeof);
        memmove(&payload[25], &g, g.sizeof);
        memmove(&payload[26], &b, b.sizeof);
        memmove(&payload[27], &brushStrokeType, brushStrokeType.sizeof);
        memmove(&payload[28], &brushStrokeSize, brushStrokeSize.sizeof);

        return payload;
    }

}
