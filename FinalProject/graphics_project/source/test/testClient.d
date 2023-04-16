module test.testClient;

// Load the SDL2 library
import bindbc.sdl;
import loader = bindbc.loader.sharedlib;

import client : Client;

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

