module Packet;

// @file Packet.d
import std.stdio;
import core.stdc.string;

// NOTE: Consider the endianness of the target machine when you 
//       send packets. If you are sending packets to different
//       operating systems with different hardware, the
//       bytes may be flipped!
//       A test you can do is to when you send a packet to a
//       operating system is send a 'known' value to the operating system
//       i.e. some number. If that number is expected (e.g. 12345678), then
//       the byte order need not be flipped.
struct Packet{
	// NOTE: Packets usually consist of a 'header'
	//   	 that otherwise tells us some information
	//  	 about the packet. Maybe the first byte
	// 	 	 indicates the format of the information.
	// 		 Maybe the next byte(s) indicate the length
	// 		 of the message. This way the server and
	// 		 client know how much information to work
	// 		 with.
	// For this example, I have a 'fixed-size' Packet
	// for simplicity -- effectively cramming every
	// piece of information I can think of.

	char[16] user;  // Perhaps a unique identifier
    int x;
    int y;
    ubyte r;
    ubyte g;
    ubyte b;
	ubyte brushType;
	ubyte brushStrokeSize;

	/// Purpose of this function is to pack a bunch of
    /// bytes into an array for 'serialization' or otherwise
	/// ability to send back and forth across a server, or for
	/// otherwise saving to disk.	
    byte[Packet.sizeof] GetPacketAsBytes(){
	
        byte[Packet.sizeof] payload;

		user = "client1\0";
 
		memmove(&payload, &user, user.sizeof);
		
		// Populate the color with some bytes
		import std.stdio;
		memmove(&payload[16], &x, x.sizeof);
		memmove(&payload[20], &y, y.sizeof);
		memmove(&payload[24], &r, r.sizeof);
		memmove(&payload[25], &g, g.sizeof);
		memmove(&payload[26], &b, b.sizeof);
		memmove(&payload[27], &brushType, brushType.sizeof);
		memmove(&payload[28], &brushStrokeSize, brushStrokeSize.sizeof);


        return payload;
    }
	
}

