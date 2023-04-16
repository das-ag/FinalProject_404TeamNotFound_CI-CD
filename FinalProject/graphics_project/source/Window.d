import bindbc.sdl;
import loader = bindbc.loader.sharedlib;

struct Window{
  	SDL_Window* mWindow;
    int width;
    int height;
    
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

    SDL_Surface* getWindowSurface(){
        return SDL_GetWindowSurface(mWindow);
    }

    void updateWindowSurface(){
        SDL_UpdateWindowSurface(mWindow);
    }

}