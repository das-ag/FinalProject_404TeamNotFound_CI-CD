/**
Command interface implemented by surface operations
*/
module Command;
// Load the SDL2 library
import bindbc.sdl;
import loader = bindbc.loader.sharedlib;

import std.stdio;

/**
Command Interface
*/
interface Command
{
    int getXPosition();
    int getYPosition();
}

/**
Surface operations implement command interface.
*/
class SurfaceOperation : Command
{
    SDL_Surface* mSurface; /// Pointer to the surface being operated on
    int mXPosition; /// Position on the x-axis for target pixel
    int mYPosition; /// Position on the y-axis for target pixel
    ubyte mR; /// R value of the stored brushmark
    ubyte mG; /// G value of the stored brushmark
    ubyte mB; /// B value of the stored brushmark
    ubyte mBrushType; /// Type of paint brush the brushmark was made with (Square, circle, etc.)
    ubyte mBrushSize; /// Size of paint brush the brushmark was made with

    /** 
    Constructs SurfaceOperations
    Params: 
        surface = pointer to SDL surface
        xPos = position on the x-axis of surface 
        yPos = position on the y-axis of surface
        r = R value of brushmark
        g = G value of brushmark    
        b = B value of brushmark
        brushType = Type of paint brush the brushmark was made with (Square, circle, etc.)
        brushSize = Size of paint brush the brushmark was made with
    */
    this(SDL_Surface* surface, int xPos, int yPos, ubyte r, ubyte g, ubyte b,
            ubyte brushType, ubyte brushSize)
    {
        mSurface = surface;
        mXPosition = xPos;
        mYPosition = yPos;
        mR = r;
        mG = g;
        mB = b;
        mBrushType = brushType;
        mBrushSize = brushSize;

    }

    /**
    SurfaceOperation destructor
    */
    ~this()
    {

    }

    /**
    Getter function for returning x-position of the command
    */
    int getXPosition()
    {
        return mXPosition;
    }

    /**
    Getter function for returning y-position of the command
    */
    int getYPosition()
    {
        return mYPosition;
    }
}
