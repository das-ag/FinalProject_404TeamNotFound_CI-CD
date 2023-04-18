module test.testClient;

// Load the SDL2 library
import bindbc.sdl;
import loader = bindbc.loader.sharedlib;

import client : Client;
import std.stdio;

@("Test SDL init")
unittest{
    Client c = new Client;
    assert(c.ret == sdlSupport);
    destroy(c);
}

@("Test SDL check variable")
unittest{
    Client c = new Client;
    assert(c.isConnectedToServer == false);
    destroy(c);
}

@("Test SDL check dimension")
unittest{
    Client c = new Client;
    assert(c.width != 600);
    destroy(c);
}

@("Test find point")
unittest {
    Client c = new Client;
    // Rectangle coordinates
    auto x1 = 0;
    auto y1 = 0;
    auto x2 = 10;
    auto y2 = 10;

    // Point inside the rectangle
    auto x = 5;
    auto y = 5;

    assert(c.findPoint(x1, y1, x2, y2, x, y));

    // Point outside the rectangle
    x = 15;
    y = 15;

    assert(!c.findPoint(x1, y1, x2, y2, x, y));

    // Point on the edge of the rectangle
    x = 5;
    y = 10;

    // Assert
    assert(!c.findPoint(x1, y1, x2, y2, x, y));
}

@("test draw button")
unittest {
    loadSDL();
    SDL_Init(SDL_INIT_EVERYTHING);

    Client c = new Client;

    c.createButtons();

    // Check that the button rects were created correctly
    assert(c.buttonDestRect.x == 0);
    assert(c.buttonDestRect.h == 50);
    assert(c.imgDestRect.x == 0);
    assert(c.imgDestRect.w == 640);

    // Check if the buttons are drawn correctly by checking colors
    auto p = c.winSurface.getbtnPixel(10,10);
    writeln(p);
    assert(p[2]==255);
    assert(p[1]==0);
    assert(p[0]==0);

    p = c.winSurface.getbtnPixel(100,10);
    writeln(p);
    assert(p[2]==0);
    assert(p[1]==255);
    assert(p[0]==0);
}

