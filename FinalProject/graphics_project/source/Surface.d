/***
 * Struct that defines surface for drawing application (gui)
 */
module Surface;

import std.stdio;
import std.typecons : tuple, Tuple;

// Load the SDL2 library
import bindbc.sdl;
import loader = bindbc.loader.sharedlib;

/**
Struct that defines surfaces for gui
*/
struct Surface
{
    SDL_Surface* mSurface; /// surface for drawing
    SDL_Surface* btnSurface; /// surface for buttons

    int width; /// width of drawing surface
    int height; /// height of drawing surface
    int btn_height; /// height of buttons

    /** 
    Constructs Surface Class
    Params:
      _width = width of surface
      _height = height of surface
      _btn_height = height of button
    */
    this(int _width, int _height, int _btn_height)
    {
        width = _width;
        height = _height;
        btn_height = _btn_height;
        this.mSurface = SDL_CreateRGBSurface(0, width, height, 32, 0, 0, 0, 0);
        this.btnSurface = SDL_CreateRGBSurface(0, width, btn_height, 32, 0, 0, 0, 0);
    }

    /**
    Destructs Surface class
    */
    ~this()
    {
        SDL_FreeSurface(mSurface);
        SDL_FreeSurface(btnSurface);
    }

    /**
    Method that updates color of pixel at a given x, y coordinate on the drawing surface.
    Params:
        xPos = position of x coordinate to update the pixel
        yPos = position of y coordinate to update the pixel
        r = r value of rgb to update the pixel
        g = g value of rgb to update the pixel
        b = b value of rgb to update the pixel
    */
    void UpdateSurfacePixel(int xPos, int yPos, ubyte r, ubyte g, ubyte b)
    {
        // When we modify pixels, we need to lock the surface first
        SDL_LockSurface(mSurface);
        // Make sure to unlock the surface when we are done
        scope (exit)
            SDL_UnlockSurface(mSurface);

        // Retrieve the pixel arraay that we want to modify
        ubyte* pixelArray = cast(ubyte*) mSurface.pixels;
        // Change the 'blue' component of the pixels
        pixelArray[yPos * mSurface.pitch + xPos * mSurface.format.BytesPerPixel + 0] = b;
        // Change the 'green' component of the pixels
        pixelArray[yPos * mSurface.pitch + xPos * mSurface.format.BytesPerPixel + 1] = g;
        // Change the 'red' component of the pixels
        pixelArray[yPos * mSurface.pitch + xPos * mSurface.format.BytesPerPixel + 2] = r;

    }

    /**
    Method that checks rgb value of a pixel at a given x,y coordinate
    Params:
        xPos = position of x coordinate of pixel to check the color 
        yPos = position of y coordinate of pixel to check the color 
    Returns: Tuple that contains r, g, b values
    */
    Tuple!(ubyte, ubyte, ubyte) getPixel(int xPos, int yPos)
    {
        ubyte* pixelArray = cast(ubyte*) mSurface.pixels;
        ubyte b = pixelArray[yPos * mSurface.pitch + xPos * mSurface.format.BytesPerPixel + 0];
        ubyte g = pixelArray[yPos * mSurface.pitch + xPos * mSurface.format.BytesPerPixel + 1];
        ubyte r = pixelArray[yPos * mSurface.pitch + xPos * mSurface.format.BytesPerPixel + 2];

        auto t = tuple(r, g, b);
        return t;
    }

    /**
    Method that checks rgb value of a pixel at a given x,y coordinate for the btn surface
    Params:
        xPos = position of x coordinate of pixel to check the color 
        yPos = position of y coordinate of pixel to check the color 
    Returns: Tuple that contains r, g, b values
    */
    Tuple!(int, int, int) getbtnPixel(int xPos, int yPos)
    {
        ubyte* pixelArray = cast(ubyte*) btnSurface.pixels;
        int r = pixelArray[yPos * mSurface.pitch + xPos * mSurface.format.BytesPerPixel + 0];
        int g = pixelArray[yPos * mSurface.pitch + xPos * mSurface.format.BytesPerPixel + 1];
        int b = pixelArray[yPos * mSurface.pitch + xPos * mSurface.format.BytesPerPixel + 2];

        auto t = tuple(r, g, b);
        return t;
    }
}
