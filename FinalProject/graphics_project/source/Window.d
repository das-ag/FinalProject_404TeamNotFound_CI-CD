/***
 * Struct that defines window for drawing application (gui)
 */
module Window;

import bindbc.sdl;
import loader = bindbc.loader.sharedlib;

/***
 * Struct that defines surface for gui
 */
struct Window
{
    SDL_Window* mWindow; /// window to display the surfaces
    int width; /// width of window
    int height; /// height of window

    /** 
    Constructs Window struct
    Params:
        name = name of window
        _width = width of window
        _height = height of window
     */
    this(const(char)* name, int _width, int _height,)
    {
        width = _width;
        height = _height;
        this.mWindow = SDL_CreateWindow(name, SDL_WINDOWPOS_UNDEFINED,
                SDL_WINDOWPOS_UNDEFINED, _width, _height, SDL_WINDOW_SHOWN);
    }

    /** 
    Destructs Window class.
    */
    ~this()
    {
        SDL_DestroyWindow(mWindow);
    }

    /**
    Method that gets window of the struct
    Returns: window
    */
    SDL_Surface* getWindowSurface()
    {
        return SDL_GetWindowSurface(mWindow);
    }

    /**
    Method that updates window of the struct
    Returns: window
    */
    void updateWindowSurface()
    {
        SDL_UpdateWindowSurface(mWindow);
    }

}
