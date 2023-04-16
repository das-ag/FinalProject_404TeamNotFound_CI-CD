import sourceSDLApp : SDLApp;
import bindbc.sdl;
import loader = bindbc.loader.sharedlib;

@("Test load SDL")
unittest{
    
    SDLApp s = new SDLApp;
    assert(s.ret == sdlSupport);
    destroy(s);
}