module client;

import std.stdio;
import std.string;
import std.socket;
import std.concurrency;
import std.conv;
import std.math;
import std.algorithm.searching;
import core.thread;
import core.thread.threadbase;
import core.thread.osthread;
import core.stdc.string;

// Load the SDL2 library
import bindbc.sdl;
import loader = bindbc.loader.sharedlib;

import Surface : Surface;
import Window : Window;
import Packet: Packet;
import DrawStrategy : DrawStrategy, DrawSquareStrategy, DrawCircleStrategy, DrawHeartStrategy, DrawSpiralStrategy, EraseStrategy;

class Client {
    SDLSupport ret;        
    int width = 640;
    int height = 480;
    Socket mSocket;
    Window window; 
    Surface winSurface;

    SDL_Rect imgDestRect;
    SDL_Rect buttonDestRect;

    int btn_height = 50;
    int btn_count = 12;

    const ubyte MAX_BRUSH_SIZE = 10;
    const ubyte MIN_BRUSH_SIZE = 4;
    ubyte brushSize = 4;
    ubyte brushStrokeType = 0;
    ubyte prevBrushStroketype = 0;
    ubyte _r = 255;
    ubyte _g = 0;
    ubyte _b = 0;

    Thread receiveThread; 
    bool isConnectedToServer = false; 
    bool runApplication;
    string clientName;

 	 this(){
        // Handle initialization...
        // SDL_Init
        // Load the SDL libraries from bindbc-sdl
        // on the appropriate operating system

        version(Windows){
            writeln("Searching for SDL on Windows");
            this.ret = loadSDL("SDL2.dll");
        }
        version(OSX){
            writeln("Searching for SDL on Mac");
            this.ret = loadSDL();
        }
        version(linux){ 
            writeln("Searching for SDL on Linux");
            this.ret = loadSDL();
        }

        // Error if SDL cannot be loaded
        if(this.ret != sdlSupport){
            writeln("Error loading SDL library");
            
            foreach( info; loader.errors){
                writeln(info.error,':', info.message);
            }
        }
        if(this.ret == SDLSupport.noLibrary){
            writeln("Error no library found");    
        }
        if(this.ret == SDLSupport.badLibrary){
            writeln("Error badLibrary, missing symbols, perhaps an older or very new version of SDL is causing the problem?");
        }

        // Initialize SDL
        if(SDL_Init(SDL_INIT_EVERYTHING) !=0){
            writeln("SDL_Init: ", fromStringz(SDL_GetError()));
        }        

        mSocket = new Socket(AddressFamily.INET, SocketType.STREAM);

        window = Window("D SDL Painting", width, height);
        winSurface = Surface(width, height, btn_height);

 	}
 	
    
    ~this(){
        // Quit the SDL Application 
        destroy(winSurface);
        destroy(window);
        SDL_Quit();
        writeln("Ending application--good bye!");
    }


    /// Method that is spawned to receive data from server
    void receiveDataFromServer(shared Socket socket) {

        byte[] dummyBuffer = [];
        int missingBytes = 0;

        while(true) {

            if (!mSocket.isAlive()) { 
                // isConnectedToServer = false;
                writeln("break thread!");
                break;
            }

            byte[Packet.sizeof] finalBuffer;
            byte[Packet.sizeof] receivedBuffer;
            int actualReceivedBytes;
            int expectedBytesToReceive = Packet.sizeof;
            
            auto received = mSocket.receive(receivedBuffer);

            actualReceivedBytes = cast(int)received;

            // if the server is closed, 
            // close the socket and make it into an offline app
            if (actualReceivedBytes == 0) {
                isConnectedToServer = false;
                mSocket.close();
            }

            writeln("acutal bytes: ", actualReceivedBytes);
    
            // check if all the bytes are received
            // If not save bytes to a dummy buffer until 
            // all the bytes are received
            if (actualReceivedBytes > 0) {

                if (missingBytes == 0 && actualReceivedBytes < expectedBytesToReceive) {
                    dummyBuffer = receivedBuffer[0 .. actualReceivedBytes].dup;
                    missingBytes = expectedBytesToReceive - actualReceivedBytes;
                    continue;
                }

                if (missingBytes != 0) {
                    if (missingBytes < actualReceivedBytes) {
                        dummyBuffer ~= receivedBuffer[0 .. missingBytes].dup;
                        finalBuffer = dummyBuffer[0 .. expectedBytesToReceive].dup;
                        dummyBuffer = [];
                        dummyBuffer = receivedBuffer[missingBytes .. actualReceivedBytes].dup;
                        missingBytes = expectedBytesToReceive - cast(int)dummyBuffer.length;
                    }
                    else if (missingBytes == actualReceivedBytes) {
                        dummyBuffer ~= receivedBuffer[0 .. missingBytes].dup;
                        finalBuffer = dummyBuffer[0 .. expectedBytesToReceive].dup;
                        dummyBuffer = [];
                        missingBytes = 0;
                    }
                    else if (missingBytes > actualReceivedBytes) {
                        dummyBuffer ~= receivedBuffer[0 .. actualReceivedBytes].dup;
                        missingBytes = expectedBytesToReceive = cast(int)dummyBuffer.length;
                    }
                }
                else if (missingBytes == 0 && actualReceivedBytes == expectedBytesToReceive) {
                    finalBuffer = receivedBuffer[0 .. expectedBytesToReceive].dup;
                }

            }

            // If all the packets are received, draw on surface
            if (actualReceivedBytes > 0 && dummyBuffer.length == 0) {

                // Unpack packet
                byte[4] field1 =  finalBuffer[16 .. 20].dup;
                byte[4] field2 =  finalBuffer[20 .. 24].dup;

                int rX = *cast(int*)&field1;
                int rY = *cast(int*)&field2;

                ubyte rRed = cast(ubyte)finalBuffer[24];
                ubyte rGreen = cast(ubyte)finalBuffer[25];
                ubyte rBlue = cast(ubyte)finalBuffer[26];   
                ubyte rBrushType = cast(ubyte)finalBuffer[27];
                ubyte rBrushSize =  cast(ubyte)finalBuffer[28];

                // TODO: delete this for clean up
                writeln("rx: ", rX);
                writeln("rY: ", rY);
                writeln("r: ", rRed);
                writeln("g: ", rGreen);
                writeln("b: ", rBlue);
                writeln("brushType: ", rBrushType);
                writeln("brushSize: ", rBrushSize);

                draw(rX, rY, rRed, rGreen, rBlue, rBrushType, rBrushSize);            
        }

        }

    }

    /// This is a helper method that changes size of brush
    void changeBrushSize(int amount) {
        brushSize += amount;

        if (brushSize > MAX_BRUSH_SIZE) 
        {
            brushSize = MAX_BRUSH_SIZE;
        }
        
        if (brushSize < MIN_BRUSH_SIZE) 
        {
            brushSize = MIN_BRUSH_SIZE;
        }
    }

    void erase() {
        if (brushStrokeType != 4) {
            prevBrushStroketype = brushStrokeType;
            writeln(prevBrushStroketype);
        }
        // Set the brush stroke to erase
        brushStrokeType = 4;
    }

    /// This is a helper method that changes color of brush
    void changeBrushColor(int color) {

        final switch (color) 
        {
            case 1:
                _r = 255;
                _g = 0;
                _b = 0;
                break;
            case 2:
                _r = 0;
                _g = 255;
                _b = 0;
                break;
            case 3:
                _r = 0;
                _g = 0;
                _b = 255;
        }
    }

   DrawStrategy createDrawingStrategy(ubyte strokeType) {
        final switch (strokeType) {
            case 0:
                return new DrawSquareStrategy;
            case 1:
                return new DrawCircleStrategy;
            case 2:
                return new DrawHeartStrategy;
            case 3:
                return new DrawSpiralStrategy;
            case 4:
                return new EraseStrategy;
        }
    }

    void draw(int xPos, int yPos, ubyte r, ubyte g, ubyte b, ubyte brushType, ubyte brushSize) {
        DrawStrategy paintBrush = createDrawingStrategy(brushType);
        paintBrush.draw(&this.winSurface, xPos, yPos, r, g, b, brushSize);
    }

    void createButtons(){
        // Create the destination rectangles:
        // ImgDestRect is the destination rect for image surface aka the canvas
        // buttonDestRect is the destination rect for button surface for control            
        imgDestRect.x = 0; // Position the first surface on the bottom
        imgDestRect.y = 100;
        imgDestRect.w = width;    // Use the surface1 width
        imgDestRect.h = height;    // Use the surface1 height

        buttonDestRect.x = 0; // Position the second surface on the top
        buttonDestRect.y = 0;
        buttonDestRect.w = width;    // Use the surface2 width
        buttonDestRect.h = btn_height;    // Use the surface2 height
        
        // button for changing color to Red
        SDL_Color HoverColor = { to!ubyte(255), to!ubyte(0), to!ubyte(0), 255 };
        SDL_Rect rect = SDL_Rect(0*width/btn_count, 5, width/btn_count, btn_height);
        uint mappedColor = SDL_MapRGB(winSurface.btnSurface.format, HoverColor.r, HoverColor.g, HoverColor.b);
        SDL_FillRect(winSurface.btnSurface, &rect, mappedColor);

        // button for changing color to Green
        SDL_Color HoverColor2 = { to!ubyte(0), to!ubyte(255), to!ubyte(0), 255 };
        rect = SDL_Rect(1*width/btn_count, 5, width/btn_count, btn_height);
        mappedColor = SDL_MapRGB(winSurface.btnSurface.format, HoverColor2.r, HoverColor2.g, HoverColor2.b);
        SDL_FillRect(winSurface.btnSurface, &rect, mappedColor);

        // button for changing color to Blue
        SDL_Color HoverColor3 = { to!ubyte(0), to!ubyte(0), to!ubyte(255), 255 };
        rect = SDL_Rect(2*width/btn_count, 5, width/btn_count, btn_height);
        mappedColor = SDL_MapRGB(winSurface.btnSurface.format, HoverColor3.r, HoverColor3.g, HoverColor3.b);
        SDL_FillRect(winSurface.btnSurface, &rect, mappedColor);

        // button for changing brush type to Square
        SDL_Rect imgRect;
        imgRect.x = 3*width/btn_count; 
        imgRect.y = 5;
        imgRect.w = width;
        imgRect.h = btn_height; 
        SDL_Surface* imgBtnSurface = SDL_LoadBMP("source/images/square_brush.bmp");
        rect = SDL_Rect(3*width/btn_count, 5, width/btn_count, btn_height);
        SDL_BlitSurface(imgBtnSurface, null, winSurface.btnSurface, &imgRect);

        // button for changing brush type to circle
        imgRect.x = 4*width/btn_count; 
        imgRect.y = 5; 
        imgBtnSurface = SDL_LoadBMP("source/images/round_brush.bmp");
        rect = SDL_Rect(4*width/btn_count, 5, width/btn_count, btn_height);
        SDL_BlitSurface(imgBtnSurface, null, winSurface.btnSurface, &imgRect);

        // button for changing brush type to hearts
        imgRect.x = 5*width/btn_count; 
        imgRect.y = 5; 
        imgBtnSurface = SDL_LoadBMP("source/images/heart_brush.bmp");
        rect = SDL_Rect(5*width/btn_count, 5, width/btn_count, btn_height);
        SDL_BlitSurface(imgBtnSurface, null, winSurface.btnSurface, &imgRect);

        // button for changing brush type to spiral
        imgRect.x = 6*width/btn_count; 
        imgRect.y = 5; 
        imgBtnSurface = SDL_LoadBMP("source/images/spiral_brush.bmp");
        rect = SDL_Rect(6*width/btn_count, 5, width/btn_count, btn_height);
        SDL_BlitSurface(imgBtnSurface, null, winSurface.btnSurface, &imgRect);

        // button for increasing brush size
        imgRect.x = 7*width/btn_count; 
        imgRect.y = 5; 
        imgBtnSurface = SDL_LoadBMP("source/images/brush_up.bmp");
        rect = SDL_Rect(7*width/btn_count, 5, width/btn_count, btn_height);
        SDL_BlitSurface(imgBtnSurface, null, winSurface.btnSurface, &imgRect);

        // button for decreasing brush size
        imgRect.x = 8*width/btn_count; 
        imgRect.y = 5; 
        imgBtnSurface = SDL_LoadBMP("source/images/brush_down.bmp");
        rect = SDL_Rect(8*width/btn_count, 5, width/btn_count, btn_height);
        SDL_BlitSurface(imgBtnSurface, null, winSurface.btnSurface, &imgRect);

        // button for undo
        imgRect.x = 9*width/btn_count; 
        imgRect.y = 5; 
        imgBtnSurface = SDL_LoadBMP("source/images/undo_button.bmp");
        rect = SDL_Rect(9*width/btn_count, 5, width/btn_count, btn_height);
        SDL_BlitSurface(imgBtnSurface, null, winSurface.btnSurface, &imgRect);

        // button for redo
        imgRect.x = 10*width/btn_count; 
        imgRect.y = 5; 
        imgBtnSurface = SDL_LoadBMP("source/images/redo_button.bmp");
        rect = SDL_Rect(10*width/btn_count, 5, width/btn_count, btn_height);
        SDL_BlitSurface(imgBtnSurface, null, winSurface.btnSurface, &imgRect);

        // button for eraser
        imgRect.x = 11*width/btn_count;
        imgRect.y = 5; 
        imgBtnSurface = SDL_LoadBMP("source/images/eraser.bmp");
        rect = SDL_Rect(11*width/btn_count, 5, width/btn_count, btn_height);
        SDL_BlitSurface(imgBtnSurface, null, winSurface.btnSurface, &imgRect);
    }

    void ifButtonsClicked(int xPos, int yPos){
        if (findPoint(0, 0, width, btn_height, xPos, yPos)){
            switch(xPos / (width/btn_count) ){
                case 0:
                    writeln("Brush Color changed to: RED!!!!");
                    if (this.brushStrokeType == 4) {
                        createDrawingStrategy(prevBrushStroketype);
                        brushStrokeType = prevBrushStroketype;
                    }
                    changeBrushColor(1);
                    break;

                case 1:
                    writeln("Brush Color changed to: GREEN!!!!");
                    if (this.brushStrokeType == 4) {
                        createDrawingStrategy(prevBrushStroketype);
                        brushStrokeType = prevBrushStroketype;
                    }
                    changeBrushColor(2);
                    break;

                case 2:
                    writeln("Brush Color changed to: BLUE!!!!");
                    if (this.brushStrokeType == 4) {
                        createDrawingStrategy(prevBrushStroketype);
                        brushStrokeType = prevBrushStroketype;
                    }
                    changeBrushColor(3);
                    break;

                case 3:
                    writeln("Brush Type changed to: SQUARE!!!!");
                    this.brushStrokeType = 0;
                    break;

                case 4:
                     writeln("Brush Type changed to: CIRCLE!!!!");
                    this.brushStrokeType = 1;
                    break;

                case 5:
                     writeln("Brush Type changed to: HEART!!!!");
                    this.brushStrokeType = 2;
                    break;

                case 6:
                     writeln("Brush Type changed to: SPIRAL!!!!");
                    this.brushStrokeType = 3;
                    break;

                case 7:
                    writeln("Brush Size Increased!!!!");
                    changeBrushSize(1);
                    break;

                case 8:
                    writeln("Brush Size Decreased!!!!");
                    changeBrushSize(-1);
                    break;
                case 9:
                    writeln("Undo!!!!");
                    break;
                case 10:
                    writeln("Redo!!!!");
                    break;
                case 11:
                    writeln("Erase!!!!");
                    erase();
                    break;
                default:
                    // operations to execute if the expression is not equal to any case
                    // ...
                    break;
                
            }
        }
    }
    bool findPoint(int x1, int y1, int x2, int y2, int x, int y)
    {
        if (x > x1 && x < x2 && y > y1 && y < y2){
            writeln("button clicked!!!!");
            return true;
        }
        return false;
    }

    /// This is a helper function that asks user for Ip address and port
    void connectToServer() {

        int i = 0;
        int trials = 5;
        while (i < trials) {
            
            try 
            {
                writeln("Enter the IP address to connect to.");
                write("> "); 
                string ip = readln;

                writeln("Enter the port to connect to.");
                write("> ");
                string port = readln;
                mSocket.connect(new InternetAddress(ip, to!ushort(strip(port))));

                // Spwan a thread for receving data from server
                receiveThread = new Thread({receiveDataFromServer(cast(shared)mSocket);}).start();
                isConnectedToServer = true;
                writeln("Connected!");

                // Send a dummy packet to update the screen
                Packet p;
                mSocket.send(p.GetPacketAsBytes());

                break;
            }
            catch(SocketOSException e) 
            {
                string errorMessage = to!string(e.message);
                if (errorMessage.canFind("Connection refused")) 
                {
                    writeln("Server is closed or the port number is wrong -- ", e.message);
                    writeln("Do you want to start the app offline?(y/n)");
                    write("> ");
                    string answer = strip(readln);

                    if (answer == "y") {
                        runApplication = true;
                        break;
                    }
                    else {
                        runApplication = false;
                        break;
                    }
                }
            
            }
            catch (Exception e) 
            {
                writeln("Wrong Input. Try again!");
                i++;
            }
        }

        // If user gives five wrong inputs, quit the app
        if (i > trials) {
            runApplication = false; 
        }
    }


    /// This is helper function that asks user if they want to connect online or just execute a offline app
    void setUpServer() {

        while (true) {
        // Ask if user wants to connect to server
            writeln("Do you want to start/join a collaboration session with your friends? (y/n):");
            write("> ");
            string answer = strip(readln);

            if (answer == "y") 
            {
                // TODO: Asking for user name causes error from memory..?
                // writeln("Great!");
                // writeln("Enter a username: ");
                // write("> ");
                // clientName = strip(readln); 

                connectToServer();
                break;
            }
            else if (answer == "n") {
                break;
            }
            else {
                writeln("Wrong input! Try Again.");
            }
        }
    }


    /// This method runs the application
    void run(){
        // Flag for determing if we are running the main application loop
        runApplication = true;
        // Flag for determining if we are 'drawing' (i.e. mouse has been pressed
        //                                                but not yet released)
        bool drawing = false;

        // Ask if user wants to connect to server
        setUpServer();
    
        // Main application loop that will run until a quit event has occurred.
        // This is the 'main graphics loop'
        while(runApplication){
            // create the buttons for the different features of the painting app
            createButtons();

            SDL_Event e;
            // Handle events
            // Events are pushed into an 'event queue' internally in SDL, and then
            // handled one at a time within this loop for as many events have
            // been pushed into the internal SDL queue. Thus, we poll until there
            // are '0' events or a NULL event is returned.
            while(SDL_PollEvent(&e) !=0){
                // retrieve the position
                int xPos = e.button.x;
                int yPos = e.button.y;

                if(e.type == SDL_QUIT)
                {
                    mSocket.close();
                    isConnectedToServer = false;
                    runApplication= false;
                }
                else if(xPos <= width && yPos >= btn_height)
                {
                    if(e.type == SDL_MOUSEBUTTONDOWN)
                    {
                        drawing=true;
                    }
                    else if(e.type == SDL_MOUSEBUTTONUP)
                    {
                        drawing=false;
                    }
                    else if(e.type == SDL_MOUSEMOTION && drawing)
                    {
                        // // retrieve the position
                        // int xPos = e.button.x;
                        // int yPos = e.button.y;

                        // TODO: Design pattern to do this better?
                        if (isConnectedToServer) 
                        {
                            Packet p;

                            with (p) {
                                // user = clientName;
                                x = xPos;
                                y = yPos;
                                r = _r;
                                g = _g;
                                b = _b;
                                brushStrokeSize = brushSize;
                                brushType = brushStrokeType;
                            }

                            // TODO: Need to clean this after checking packet size for undo
                            writeln(p.sizeof);

                            // Send pixel to server
                            mSocket.send(p.GetPacketAsBytes());
                        }
                        else 
                        {
                            draw(xPos, yPos, _r, _g, _b, brushStrokeType, brushSize);
                        }
        
                    }
                }
                else if(xPos < width && yPos <= btn_height){
                    // button functions
                    if(e.type == SDL_MOUSEBUTTONUP){
                        ifButtonsClicked(xPos, yPos);
                    }
                }
            }

            // Blit the surace (i.e. update the window with another surfaces pixels
            //                       by copying those pixels onto the window).
            // TODO: make method in Surface
            SDL_BlitSurface(winSurface.mSurface, null, window.getWindowSurface(), null);
            SDL_BlitSurface(winSurface.btnSurface, null, window.getWindowSurface(), &buttonDestRect);
            
            // Update the window surface
            window.updateWindowSurface();
            // Delay for 16 milliseconds
            // Otherwise the program refreshes too quickly
            SDL_Delay(16);
        }

    }

}

void main(){	
	Client client = new Client;
	client.run();
}