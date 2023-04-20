module test.testWindow;

import bindbc.sdl;
import loader = bindbc.loader.sharedlib;

import Window : Window;

@("Test Window dimensions")
unittest
{
    loadSDL();
    SDL_Init(SDL_INIT_EVERYTHING);

    const int width = 640;
    const int height = 480;

    Window testWindow = Window("test window", width, height);
    assert(testWindow.width == width && testWindow.height == 480);
    destroy(testWindow);
}

@("Test Window.getWindowSurface")
unittest
{
    loadSDL();
    SDL_Init(SDL_INIT_EVERYTHING);

    const int width = 640;
    const int height = 480;

    Window testWindow = Window("test window", width, height);
    assert(typeid(testWindow.getWindowSurface) == typeid(SDL_Surface*));
    destroy(testWindow);
}
