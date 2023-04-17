/***
 * Struct that defines window for drawing application (gui)
 */
module Window;

import bindbc.sdl;
import loader = bindbc.loader.sharedlib;

/***
 * Struct that defines surface for gui
 */
struct Window{
  	SDL_Window* mWindow; /// window to display the surfaces
    int width;  /// width of window
    int height; /// height of window
    
    this(const(char)* name, int _width, int _height,) {
        width = _width;
        height = _height;
  		this.mWindow = SDL_CreateWindow(name,
                                            SDL_WINDOWPOS_UNDEFINED,
                                            SDL_WINDOWPOS_UNDEFINED,
                                            _width,
                                            _height, 
                                            SDL_WINDOW_SHOWN);
  	}

    ~this(){
        SDL_DestroyWindow(mWindow);
    }


	/**
    Gets window of the struct
    Returns: window
    */
    SDL_Surface* getWindowSurface(){
        return SDL_GetWindowSurface(mWindow);
    }


	/**
    Updates window of the struct
    Returns: window
    */
    void updateWindowSurface(){
        SDL_UpdateWindowSurface(mWindow);
    }

}