module test.testSurface;

import std.stdio;

import bindbc.sdl;
import loader = bindbc.loader.sharedlib;

import Surface : Surface;


@("Test Update pixel")
unittest{
    const int width = 640;
    const int height = 480;
    const int btnHt = 50;
    loadSDL();
    SDL_Init(SDL_INIT_EVERYTHING);
    
    Surface imgSurface = Surface(width, height, btnHt);
    imgSurface.UpdateSurfacePixel(10, 10, 30, 40, 50);
    auto p = imgSurface.getPixel(10,10);
    writeln(p);
    assert(p[0]== 30 && p[1]== 40 && p[2]==50);
    destroy(imgSurface);
}