module Command;
// Load the SDL2 library
import bindbc.sdl;
import loader = bindbc.loader.sharedlib;

import std.stdio;

// Command interface implemented by surface operations
interface Command {
    //int Execute();
    int Undo();
}

// Surface operations implement command interface
class SurfaceOperation : Command {
    SDL_Surface* mSurface;
    int mXPosition;
    int mYPosition;
    ubyte mR;
    ubyte mG;
    ubyte mB;
    ubyte mBrushType;
    ubyte mBrushSize;

    this(SDL_Surface* surface, int xPos, int yPos, ubyte r, ubyte g, ubyte b, ubyte brushType, ubyte brushSize) {
        mSurface = surface;
        mXPosition = xPos;
        mYPosition = yPos;
        mR = r;
        mG = g;
        mB = b;
        mBrushType = brushType;
        mBrushSize = brushSize;

        
    }

    ~this() {

    }

    int getYPosition() {
        return mYPosition;
    }

    int getXPosition() {
        return mXPosition;
    }
}