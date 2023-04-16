import std.stdio;
import std.typecons: tuple, Tuple;

// Load the SDL2 library
import bindbc.sdl;
import loader = bindbc.loader.sharedlib;

struct Surface{
  	SDL_Surface* mSurface;
    SDL_Surface* btnSurface;
    
    int width;
    int height;
    int btn_height;
    
    this(int _width, int _height, int _btn_height, ) {
      width = _width;
      height = _height;
      btn_height = _btn_height;
  		this.mSurface = SDL_CreateRGBSurface(0,width,height,32,0,0,0,0);
      this.btnSurface = SDL_CreateRGBSurface(0,width,btn_height,32,0,0,0,0);
  	}

  	~this(){
  		SDL_FreeSurface(mSurface);
      SDL_FreeSurface(btnSurface);
  	}

    void UpdateSurfacePixel(int xPos, int yPos, ubyte r, ubyte g, ubyte b){
        // When we modify pixels, we need to lock the surface first
        SDL_LockSurface(mSurface);
        // Make sure to unlock the surface when we are done
        scope(exit) SDL_UnlockSurface(mSurface);

        // Retrieve the pixel arraay that we want to modify
        ubyte* pixelArray = cast(ubyte*)mSurface.pixels;
        // Change the 'blue' component of the pixels
        pixelArray[yPos * mSurface.pitch + xPos * mSurface.format.BytesPerPixel + 0] = b;
        // Change the 'green' component of the pixels
        pixelArray[yPos * mSurface.pitch + xPos * mSurface.format.BytesPerPixel + 1] = g;
        // Change the 'red' component of the pixels
        pixelArray[yPos * mSurface.pitch + xPos * mSurface.format.BytesPerPixel + 2] = r;

    }
  	
  	// Check a pixel color
  	Tuple!(int, int, int) getPixel(int xPos, int yPos){
        ubyte* pixelArray = cast(ubyte*)mSurface.pixels;
        int r = pixelArray[yPos*mSurface.pitch + xPos*mSurface.format.BytesPerPixel+0];
        int g = pixelArray[yPos*mSurface.pitch + xPos*mSurface.format.BytesPerPixel+1];
        int b = pixelArray[yPos*mSurface.pitch + xPos*mSurface.format.BytesPerPixel+2];

        auto t = tuple(r, g, b);
        return t;
    }
  }