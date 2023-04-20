/***
 * Class that runs the drawing application on the client side.
 * It connects to server and runs the gui for the application.
 * Authors: Agastya Das, Heekyung Kim, Roydon Pereira, Jake Stringfellow, Jiayue Zhao
 */

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
import Packet : Packet;
import DrawStrategy : DrawStrategy, DrawSquareStrategy, DrawCircleStrategy,
    DrawHeartStrategy, DrawSpiralStrategy, EraseStrategy;

// Load commands
import Command : Command;
import Command : SurfaceOperation;

// Import tuple
import std.typecons : tuple, Tuple;

/***
 Class that runs the drawing application on the client side.
 It connects to server upon user's request and runs the gui for the application.
 */
class Client
{
    SDLSupport ret; /// SDL initializer that loads libraries based on user's OS
    int width = 640; /// Width of window to run the gui
    int height = 480; /// Height of window to run the gui
    Socket mSocket; /// Socket to receive and send packets to server
    Window window; /// Window to display gui
    Surface winSurface; /// Surface to draw pixels (gui)

    SDL_Rect imgDestRect; /// Image to overaly onto the buttons
    SDL_Rect buttonDestRect; /// A Button on the tool bar

    int btn_height = 50; /// Height of buttons
    int btn_count = 12; /// Number of buttons on the toolbar

    const ubyte MAX_BRUSH_SIZE = 10; /// Maximum size of brush that users can increase
    const ubyte MIN_BRUSH_SIZE = 2; /// Minimum size of brush that users can decrease
    ubyte brushSize = 4; /// size of brush (default is 4) 
    ubyte brushType = 0; /// Type of paint brush (e.g. circle, heart) - default is square
    ubyte prevBrushType = 0; /// Variable to save previous paint brush type
    ubyte _r = 255; /// r value of current brush
    ubyte _g = 0; /// g value of current brush
    ubyte _b = 0; /// b value of current brush

    Thread receiveThread; /// Thread for receiving packets from server
    bool isConnectedToServer = false; /// Flag to check if server is connected
    bool runApplication; /// Flag to check if application is running

    // Instantiate the undo and redo command queues
    SurfaceOperation[] undoQueue; /// Array storing brush mark info of all brush marks, drawn or "redone"
    SurfaceOperation[] redoQueue; /// Array storing brush mark info of "undone" marks

    /** 
     Constructs Client class
     */
    this()
    {
        // Handle initialization...
        // SDL_Init
        // Load the SDL libraries from bindbc-sdl
        // on the appropriate operating system

        version (Windows)
        {
            writeln("Searching for SDL on Windows");
            this.ret = loadSDL("SDL2.dll");
        }
        version (OSX)
        {
            writeln("Searching for SDL on Mac");
            this.ret = loadSDL();
        }
        version (linux)
        {
            writeln("Searching for SDL on Linux");
            this.ret = loadSDL();
        }

        // Error if SDL cannot be loaded
        if (this.ret != sdlSupport)
        {
            writeln("Error loading SDL library");

            foreach (info; loader.errors)
            {
                writeln(info.error, ':', info.message);
            }
        }
        if (this.ret == SDLSupport.noLibrary)
        {
            writeln("Error no library found");
        }
        if (this.ret == SDLSupport.badLibrary)
        {
            writeln(
                    "Error badLibrary, missing symbols, perhaps an older or very new version of SDL is causing the problem?");
        }

        // Initialize SDL
        if (SDL_Init(SDL_INIT_EVERYTHING) != 0)
        {
            writeln("SDL_Init: ", fromStringz(SDL_GetError()));
        }

        mSocket = new Socket(AddressFamily.INET, SocketType.STREAM);
        window = Window("D SDL Painting", width, height);
        winSurface = Surface(width, height, btn_height);

    }

    /** 
     Destructs Client class
     */
    ~this()
    {
        // Quit the SDL Application 
        destroy(winSurface);
        destroy(window);
        SDL_Quit();
        writeln("Ending application--good bye!");
    }

    /**
    Method that is spawned to receive packets from server
    */
    void receiveDataFromServer()
    {

        byte[] dummyBuffer = [];
        int missingBytes = 0;

        while (true)
        {

            byte[Packet.sizeof] finalBuffer;
            byte[Packet.sizeof] receivedBuffer;
            int actualReceivedBytes;
            int expectedBytesToReceive = Packet.sizeof;

            auto received = mSocket.receive(receivedBuffer);

            actualReceivedBytes = cast(int) received;

            // If the server is closed, 
            // close the socket and make it into an offline app
            if (actualReceivedBytes == 0)
            {
                isConnectedToServer = false;
                mSocket.close();
            }

            writeln("acutal bytes: ", actualReceivedBytes);

            // Check if all the bytes are received from server
            // If not save bytes to a dummy buffer until 
            // all the bytes are received.
            // When all the bytes are received, then draw the pixels onto the surface
            if (actualReceivedBytes > 0)
            {

                if (missingBytes == 0 && actualReceivedBytes < expectedBytesToReceive)
                {
                    dummyBuffer = receivedBuffer[0 .. actualReceivedBytes].dup;
                    missingBytes = expectedBytesToReceive - actualReceivedBytes;
                    continue;
                }

                if (missingBytes != 0)
                {
                    if (missingBytes < actualReceivedBytes)
                    {
                        dummyBuffer ~= receivedBuffer[0 .. missingBytes].dup;
                        finalBuffer = dummyBuffer[0 .. expectedBytesToReceive].dup;
                        dummyBuffer = [];
                        dummyBuffer = receivedBuffer[missingBytes .. actualReceivedBytes].dup;
                        missingBytes = expectedBytesToReceive - cast(int) dummyBuffer.length;
                    }
                    else if (missingBytes == actualReceivedBytes)
                    {
                        dummyBuffer ~= receivedBuffer[0 .. missingBytes].dup;
                        finalBuffer = dummyBuffer[0 .. expectedBytesToReceive].dup;
                        dummyBuffer = [];
                        missingBytes = 0;
                    }
                    else if (missingBytes > actualReceivedBytes)
                    {
                        dummyBuffer ~= receivedBuffer[0 .. actualReceivedBytes].dup;
                        missingBytes = expectedBytesToReceive = cast(int) dummyBuffer.length;
                    }
                }
                else if (missingBytes == 0 && actualReceivedBytes == expectedBytesToReceive)
                {
                    finalBuffer = receivedBuffer[0 .. expectedBytesToReceive].dup;
                }

            }

            if (!mSocket.isAlive())
            {
                isConnectedToServer = false;
                writeln("break thread!");
                break;
            }

            // If all the packets are received, draw on surface
            if (actualReceivedBytes > 0 && dummyBuffer.length == 0)
            {

                // Unpack packet
                byte[4] field1 = finalBuffer[16 .. 20].dup;
                byte[4] field2 = finalBuffer[20 .. 24].dup;

                int rX = *cast(int*)&field1;
                int rY = *cast(int*)&field2;

                ubyte rRed = cast(ubyte) finalBuffer[24];
                ubyte rGreen = cast(ubyte) finalBuffer[25];
                ubyte rBlue = cast(ubyte) finalBuffer[26];
                ubyte rBrushType = cast(ubyte) finalBuffer[27];
                ubyte rBrushSize = cast(ubyte) finalBuffer[28];

                // For Debugging: Check what we unpacked
                writeln("rx: ", rX);
                writeln("rY: ", rY);
                writeln("r: ", rRed);
                writeln("g: ", rGreen);
                writeln("b: ", rBlue);
                writeln("brushType: ", rBrushType);
                writeln("brushSize: ", rBrushSize);

                // Draw pixels onto the surface of gui based on information unpacked from packet
                draw(rX, rY, rRed, rGreen, rBlue, rBrushType, rBrushSize);
            }

        }

    }

    /**
    Helper function that changes the size of the brush    
    Params:
        amount = amount to change the brush size
    */
    void changeBrushSize(int amount)
    {
        brushSize += amount;

        // Constrain the max size of brush to 10
        if (brushSize > MAX_BRUSH_SIZE)
        {
            brushSize = MAX_BRUSH_SIZE;
        }

        // Constrain the min size of brush to 2
        if (brushSize < MIN_BRUSH_SIZE)
        {
            brushSize = MIN_BRUSH_SIZE;
        }
    }

    /**
    Method that erases pixels on the gui.
    */
    void erase()
    {
        // Save previous paint brush type
        // So that users can revert back when done using the eraser
        if (brushType != 4)
        {
            prevBrushType = brushType;
        }

        // Set the paint brush type to eraser
        brushType = 4;
    }

    /**
    Method that undoes the most recent command by erasing the most recent brush mark
    */
    void undo()
    {
        if (undoQueue.length == 0)
        {
            // Let the user know there are no commands left
            writeln("There is nothing to undo.");
        }
        else
        {

            // Each pixel is considered a command
            // Undo the last 10 marks made 
            for (int i = 1; i < 11; i++)
            {
                if (undoQueue.length != 0)
                {

                    // Store the current brushStrokeType to return to it after undoing
                    auto storedBrushStrokeType = this.brushType;

                    Packet p;

                    // The command being done is the most recent addition to the queue
                    // This is the previous state of that area of pixels before the last mark was made
                    SurfaceOperation c = undoQueue[$ - 1];

                    // Set the shape of our paintbrush equal to the target mark's brush shape
                    this.brushType = c.mBrushType;

                    // Store the state of pixels before undoing is performed
                    // These colors are stored for the redo command
                    Tuple!(ubyte, ubyte, ubyte) prev_pixel = winSurface.getPixel(c.getXPosition(),
                            c.getYPosition());

                    // Online undoing
                    if (isConnectedToServer)
                    {

                        // Send a packet containing all of the information from the last mark
                        // The server will draw over the pixels affected by the last mark
                        with (p)
                        {
                            x = c.getXPosition(); //xPos + w;
                            y = c.getYPosition(); //yPos + h;
                            r = c.mR;
                            g = c.mG;
                            b = c.mB;
                            brushStrokeSize = c.mBrushSize;
                            brushStrokeType = c.mBrushType;
                        }

                        // writeln("sending packing",p);
                        mSocket.send(p.GetPacketAsBytes());

                    }
                    // Offline undoing
                else
                    {

                        // Draw over the pixels affected by the last mark
                        draw(c.getXPosition(), c.getYPosition(), c.mR, c.mG,
                                c.mB, c.mBrushType, c.mBrushSize);

                    }

                    // Create a new command
                    // The r, g, b values are the color of the pixels before the undo was called
                    // The brush type and brush size is the same as the initial mark made
                    auto prev_state = new SurfaceOperation(winSurface.mSurface, c.mXPosition, c.mYPosition,
                            prev_pixel[0], prev_pixel[1], prev_pixel[2],
                            c.mBrushType, c.mBrushSize);
                    // Append the command onto the redoQueue
                    redoQueue ~= prev_state;

                    // Remove the last command from the queue
                    undoQueue = undoQueue[0 .. $ - 1];

                    // Then set the brushStrokeType back to what it was before the undo event
                    this.brushType = storedBrushStrokeType;

                }

            }

        }
    }

    /**
    Method that redoes the most recent undone command by repainting the pixels that were erased
    */
    void redo()
    {
        if (redoQueue.length == 0)
        {
            // Let the user know there are no commands left
            writeln("There is nothing to redo.");
        }
        else
        {
            // Treat "Redoing" like drawing pixels, add it to the undo queue
            // Each mark is considered a command         
            // 10 marks are redone for each call of redo()
            for (int i = 1; i < 11; i++)
            {
                if (redoQueue.length != 0)
                {

                    // Store the current brushStrokeType to return to it after redoing
                    auto storedBrushStrokeType = this.brushType;

                    Packet p;

                    // The command being done is the most recent addition to the queue
                    // This is the previous state of that area of pixels before the last undo was called
                    SurfaceOperation c = redoQueue[$ - 1];

                    // Set the shape equal to the undone mark's brush shape
                    this.brushType = c.mBrushType;

                    // Store the state of pixels before redoing is performed
                    // These colors are stored for the undo command
                    Tuple!(ubyte, ubyte, ubyte) prev_pixel = winSurface.getPixel(c.getXPosition(),
                            c.getYPosition());

                    // Online redoing
                    if (isConnectedToServer)
                    {

                        // Send a packet containing all of the information from the undone mark
                        // The server will draw over the pixels affected by the last undo
                        with (p)
                        {
                            x = c.getXPosition(); //xPos + w;
                            y = c.getYPosition(); //yPos + h;
                            r = c.mR;
                            g = c.mG;
                            b = c.mB;
                            brushStrokeSize = c.mBrushSize;
                            brushStrokeType = c.mBrushType;
                        }

                        //writeln("sending packing",p);
                        mSocket.send(p.GetPacketAsBytes());

                    }
                    // Offline redoing
                else
                    {

                        // Draw over the pixels affected by the last undo
                        draw(c.getXPosition(), c.getYPosition(), c.mR, c.mG,
                                c.mB, c.mBrushType, c.mBrushSize);

                    }

                    // Create a new command
                    // The r, g, b values of commands are the color of the PREVIOUS pixel
                    auto prev_state = new SurfaceOperation(winSurface.mSurface,
                            c.mXPosition, c.mYPosition, 0, 0, 0, //prev_pixel[0], prev_pixel[1], prev_pixel[2], 
                            this.brushType, this.brushSize); //brushStrokeType, brushSize);
                    undoQueue ~= prev_state;

                    // Remove the last command from the queue
                    redoQueue = redoQueue[0 .. $ - 1];

                    // Then set the brushStrokeType back to what it was before the redo event
                    this.brushType = storedBrushStrokeType;

                }

            }
        }

    }

    /**
    Helper method that changes color of paint brush
    Params:
        color = identifier for color (red = 1, green = 2, blue = 3)
    */
    void changeBrushColor(int color)
    {

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
            break;
        }
    }

    /**
    Method that creates instances of paint brush classes.
    Based on factory design pattern.
    Params:
        strokeType = identifier for paint brush (square = 0, 1 = circle, 2 = heart, 3 = spiral, 4 = eraser)
    Returns: DrawStrategy class based on parameter
    */
    DrawStrategy createDrawingStrategy(ubyte strokeType)
    {
        final switch (strokeType)
        {
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

    /**
    Method that draws pixel on x, y coordinate based on given color, paint brush type, and brush size
    This method uses factory design pattern.
    Params:
        xPos = position of x coordinate to draw the pixel
        yPos = position of y coordinate to draw the pixel
        r = r value of rgb to draw the pixel
        g = g value of rgb to draw the pixel
        b = b value of rgb to draw the pixel
        brushType = type of paint brush 
        brushSize = size of paint brush
    */
    void draw(int xPos, int yPos, ubyte r, ubyte g, ubyte b, ubyte brushType, ubyte brushSize)
    {
        // Create a paint brush type based on user's input 
        DrawStrategy paintBrush = createDrawingStrategy(brushType);

        // Draw using the selected paint brush type
        paintBrush.draw(&this.winSurface, xPos, yPos, r, g, b, brushSize);
    }

    /**
    Method that creates the buttons on the upper margin of the window surface.
    */
    void createButtons()
    {
        // Create the destination rectangles:
        // ImgDestRect is the destination rect for image surface aka the canvas
        // buttonDestRect is the destination rect for button surface for control            
        imgDestRect.x = 0; // Position the first surface on the bottom
        imgDestRect.y = 100;
        imgDestRect.w = width; // Use the surface1 width
        imgDestRect.h = height; // Use the surface1 height

        buttonDestRect.x = 0; // Position the second surface on the top
        buttonDestRect.y = 0;
        buttonDestRect.w = width; // Use the surface2 width
        buttonDestRect.h = btn_height; // Use the surface2 height

        // Create a button for changing color to Red
        SDL_Color HoverColor = {to!ubyte(255), to!ubyte(0), to!ubyte(0), 255};
        SDL_Rect rect = SDL_Rect(0 * width / btn_count, 5, width / btn_count, btn_height);
        uint mappedColor = SDL_MapRGB(winSurface.btnSurface.format,
                HoverColor.r, HoverColor.g, HoverColor.b);
        SDL_FillRect(winSurface.btnSurface, &rect, mappedColor);

        // Create a button for changing color to Green
        SDL_Color HoverColor2 = {to!ubyte(0), to!ubyte(255), to!ubyte(0), 255};
        rect = SDL_Rect(1 * width / btn_count, 5, width / btn_count, btn_height);
        mappedColor = SDL_MapRGB(winSurface.btnSurface.format, HoverColor2.r,
                HoverColor2.g, HoverColor2.b);
        SDL_FillRect(winSurface.btnSurface, &rect, mappedColor);

        // Create a button for changing color to Blue
        SDL_Color HoverColor3 = {to!ubyte(0), to!ubyte(0), to!ubyte(255), 255};
        rect = SDL_Rect(2 * width / btn_count, 5, width / btn_count, btn_height);
        mappedColor = SDL_MapRGB(winSurface.btnSurface.format, HoverColor3.r,
                HoverColor3.g, HoverColor3.b);
        SDL_FillRect(winSurface.btnSurface, &rect, mappedColor);

        // Create a button for changing brush type to Square
        SDL_Rect imgRect;
        imgRect.x = 3 * width / btn_count; // defines the starting x coordiate position of the button
        imgRect.y = 5; // defines the starting y coordiate position of the button
        imgRect.w = width; // defines the width of the button
        imgRect.h = btn_height; // defines the height of the button
        SDL_Surface* imgBtnSurface = SDL_LoadBMP("source/images/square_brush.bmp");
        rect = SDL_Rect(3 * width / btn_count, 5, width / btn_count, btn_height);
        SDL_BlitSurface(imgBtnSurface, null, winSurface.btnSurface, &imgRect);

        // Create a button for changing brush type to circle
        imgRect.x = 4 * width / btn_count;
        imgRect.y = 5;
        imgBtnSurface = SDL_LoadBMP("source/images/round_brush.bmp");
        rect = SDL_Rect(4 * width / btn_count, 5, width / btn_count, btn_height);
        SDL_BlitSurface(imgBtnSurface, null, winSurface.btnSurface, &imgRect);

        // Create a button for changing brush type to hearts
        imgRect.x = 5 * width / btn_count;
        imgRect.y = 5;
        imgBtnSurface = SDL_LoadBMP("source/images/heart_brush.bmp");
        rect = SDL_Rect(5 * width / btn_count, 5, width / btn_count, btn_height);
        SDL_BlitSurface(imgBtnSurface, null, winSurface.btnSurface, &imgRect);

        // Create a button for changing brush type to spiral
        imgRect.x = 6 * width / btn_count;
        imgRect.y = 5;
        imgBtnSurface = SDL_LoadBMP("source/images/spiral_brush.bmp");
        rect = SDL_Rect(6 * width / btn_count, 5, width / btn_count, btn_height);
        SDL_BlitSurface(imgBtnSurface, null, winSurface.btnSurface, &imgRect);

        // Create a button for increasing brush size
        imgRect.x = 7 * width / btn_count;
        imgRect.y = 5;
        imgBtnSurface = SDL_LoadBMP("source/images/brush_up.bmp");
        rect = SDL_Rect(7 * width / btn_count, 5, width / btn_count, btn_height);
        SDL_BlitSurface(imgBtnSurface, null, winSurface.btnSurface, &imgRect);

        // Create a button for decreasing brush size
        imgRect.x = 8 * width / btn_count;
        imgRect.y = 5;
        imgBtnSurface = SDL_LoadBMP("source/images/brush_down.bmp");
        rect = SDL_Rect(8 * width / btn_count, 5, width / btn_count, btn_height);
        SDL_BlitSurface(imgBtnSurface, null, winSurface.btnSurface, &imgRect);

        // Create a button for undo
        imgRect.x = 9 * width / btn_count;
        imgRect.y = 5;
        imgBtnSurface = SDL_LoadBMP("source/images/undo_button.bmp");
        rect = SDL_Rect(9 * width / btn_count, 5, width / btn_count, btn_height);
        SDL_BlitSurface(imgBtnSurface, null, winSurface.btnSurface, &imgRect);

        // Create a button for redo
        imgRect.x = 10 * width / btn_count;
        imgRect.y = 5;
        imgBtnSurface = SDL_LoadBMP("source/images/redo_button.bmp");
        rect = SDL_Rect(10 * width / btn_count, 5, width / btn_count, btn_height);
        SDL_BlitSurface(imgBtnSurface, null, winSurface.btnSurface, &imgRect);

        // Create a button for eraser
        imgRect.x = 11 * width / btn_count;
        imgRect.y = 5;
        imgBtnSurface = SDL_LoadBMP("source/images/eraser.bmp");
        rect = SDL_Rect(11 * width / btn_count, 5, width / btn_count, btn_height);
        SDL_BlitSurface(imgBtnSurface, null, winSurface.btnSurface, &imgRect);
    }

    /**
    Method that selects an operation to be performed based on the button that is clicked.
    Params:
        xPos = position of x coordinate of the mouse click
        yPos = position of y coordinate of the mouse click
    */
    void ifButtonsClicked(int xPos, int yPos)
    {
        // Check if the mouse click is within the boundaries of the button surface
        if (findPoint(0, 0, width, btn_height, xPos, yPos))
        {
            // Select the operation to be performed based on the position of the mouse click
            switch (xPos / (width / btn_count))
            {
                // Change color to Red
            case 0:
                // writeln("Brush Color changed to: RED!!!!");
                if (this.brushType == 4)
                {
                    createDrawingStrategy(prevBrushType);
                    brushType = prevBrushType;
                }
                changeBrushColor(1);
                break;

                // Change color to Green
            case 1:
                // writeln("Brush Color changed to: GREEN!!!!");
                if (this.brushType == 4)
                {
                    createDrawingStrategy(prevBrushType);
                    brushType = prevBrushType;
                }
                changeBrushColor(2);
                break;

                // Change color to blue
            case 2:
                // writeln("Brush Color changed to: BLUE!!!!");
                if (this.brushType == 4)
                {
                    createDrawingStrategy(prevBrushType);
                    brushType = prevBrushType;
                }
                changeBrushColor(3);
                break;

                // Change paint brush to square
            case 3:
                // writeln("Brush Type changed to: SQUARE!!!!");
                this.brushType = 0;
                break;

                // Change paint brush to circle
            case 4:
                // writeln("Brush Type changed to: CIRCLE!!!!");
                this.brushType = 1;
                break;

                // Change paint brush to heart
            case 5:
                // writeln("Brush Type changed to: HEART!!!!");
                this.brushType = 2;
                break;

                // Change paint brush to spiral
            case 6:
                // writeln("Brush Type changed to: SPIRAL!!!!");
                this.brushType = 3;
                break;

                // Increase brush size
            case 7:
                // writeln("Brush Size Increased!!!!");
                changeBrushSize(1);
                break;

                // Decrease brush size
            case 8:
                // writeln("Brush Size Decreased!!!!");
                changeBrushSize(-1);
                break;

                // Undo
            case 9:
                // writeln("Undo!!!!");
                // Call the undo function to remove the last 10 marks
                undo();
                break;

                // Redo
            case 10:
                // writeln("Redo!!!!");
                // Call the redo function to add back the last 10 undone marks
                redo();
                break;

                // Erase
            case 11:
                // writeln("Erase!!!!");
                erase();
                break;

                // In case user presses on incorrect space
            default:
                break;
            }
        }
    }

    /**
    Helper method that checks if the mouse click is within the boundaries of the button surface
    Params:
        x1 = position of the starting x coordinate of button surface
        y1 = position of the starting y coordinate of button surface
        x2 = position of the ending x coordinate of button surface
        y2 = position of the ending y coordinate of button surface
        x = position of x coordinate of the mouse click
        y = position of y coordinate of the mouse click
    Returns: True if mouse click is on button surface, else false.
    */
    bool findPoint(int x1, int y1, int x2, int y2, int x, int y)
    {
        // If the mouse click is within the boundaries of button surface,
        // then return true, else return false.
        if (x > x1 && x < x2 && y > y1 && y < y2)
        {
            // writeln("button clicked!!!!");
            return true;
        }
        return false;
    }

    /**
    Helper method that asks user for IP address and port number of server they want to connect.
    If the user incorrectly inputs for more than 5 times, the application ends.
    If the server is closed, it asks the user if they want to start the application offline.
    Throws: 
        SocketOSException e if server is closed or port number is incorrect
        Exception e if user input is invalid
    */
    void connectToServer()
    {

        int i = 0;
        int trials = 5;
        while (i < trials)
        {

            try
            {
                writeln("Enter the IP address to connect to.");
                write("> ");
                string ip = readln;

                writeln("Enter the port to connect to.");
                write("> ");
                string port = readln;

                // Connect to port based on user input
                mSocket.connect(new InternetAddress(ip, to!ushort(strip(port))));

                // Spwan a thread for receving data from server
                receiveThread = new Thread({ receiveDataFromServer(); }).start();
                isConnectedToServer = true;
                writeln("Connected!");

                // Send a dummy packet to update the screen
                Packet p;
                mSocket.send(p.GetPacketAsBytes());

                break;
            }
            catch (SocketOSException e) /// throw error if server is closed or port number is incorrect
            {
                string errorMessage = to!string(e.message);

                if (errorMessage.canFind("Connection refused"))
                {
                    writeln("Server is closed or the port number is wrong -- ", e.message);
                    writeln("Do you want to start the app offline?(y/n)");
                    write("> ");
                    string answer = strip(readln);

                    if (answer == "y")
                    {
                        runApplication = true;
                        break;
                    }
                    else
                    {
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
        if (i > trials)
        {
            runApplication = false;
        }
    }

    /**
    Method that asks if the user wants to start the application online or offline
    */
    void setUpServer()
    {

        while (true)
        {
            // Ask if user wants to connect to server
            writeln("Do you want to start/join a collaboration session with your friends? (y/n):");
            write("> ");
            string answer = strip(readln);

            if (answer == "y")
            {
                connectToServer();
                break;
            }
            else if (answer == "n")
            {
                break;
            }
            else
            {
                writeln("Wrong input! Try Again.");
            }
        }
    }

    /**
    Method that runs the application.
    It runs the application both offline and online.
    If online, it connects to the server, spawns a thread that listens to the server, and sends packets on a mouse event (draw)
    If offline, it draws pixels onto the gui.
    It listens to button click events to manipulate color, brush size, brush types, undo, redo, and erase.
    */
    void run()
    {
        // Flag for determing if we are running the main application loop
        runApplication = true;
        // Flag for determining if we are 'drawing' (i.e. mouse has been pressed
        //                                                but not yet released)
        bool drawing = false;

        // Ask if user wants to connect to server
        setUpServer();

        // Main application loop that will run until a quit event has occurred.
        // This is the 'main graphics loop'
        while (runApplication)
        {
            // create the buttons for the different features of the painting app
            createButtons();

            SDL_Event e;
            // Handle events
            // Events are pushed into an 'event queue' internally in SDL, and then
            // handled one at a time within this loop for as many events have
            // been pushed into the internal SDL queue. Thus, we poll until there
            // are '0' events or a NULL event is returned.
            while (SDL_PollEvent(&e) != 0)
            {
                // retrieve the position
                int xPos = e.button.x;
                int yPos = e.button.y;

                if (e.type == SDL_QUIT)
                {
                    mSocket.close();
                    isConnectedToServer = false;
                    runApplication = false;
                }
                else if (xPos <= width && yPos >= btn_height)
                {
                    if (e.type == SDL_MOUSEBUTTONDOWN)
                    {
                        drawing = true;
                    }
                    else if (e.type == SDL_MOUSEBUTTONUP)
                    {
                        drawing = false;
                    }
                    else if (e.type == SDL_MOUSEMOTION && drawing)
                    {
                        // // retrieve the position
                        // int xPos = e.button.x;
                        // int yPos = e.button.y;

                        // TODO: Design pattern to do this better?
                        if (isConnectedToServer)
                        {
                            // Store the state of pixels before painting over them
                            Tuple!(ubyte, ubyte, ubyte) prev_pixel = winSurface.getPixel(xPos,
                                    yPos);

                            Packet p;

                            with (p)
                            {
                                // user = clientName;
                                x = xPos;
                                y = yPos;
                                r = _r;
                                g = _g;
                                b = _b;
                                brushStrokeSize = brushSize;
                                brushStrokeType = brushType;
                            }

                            SurfaceOperation prev_state;

                            // Create a new command
                            // The r, g, b values of commands are the color of the pixel BEFORE painting is done
                            prev_state = new SurfaceOperation(winSurface.mSurface,
                                    xPos, yPos, 0, 0, 0, this.brushType, this.brushSize);
                            // Append the "before" pixel to the undo queue

                            // Debuging purpose: Need to clean this after checking packet size for undo
                            // writeln(p.sizeof);

                            undoQueue ~= prev_state;

                            // Send pixel to server
                            mSocket.send(p.GetPacketAsBytes());
                        }
                        else
                        {

                            // Store the state of pixels before painting over them
                            Tuple!(ubyte, ubyte, ubyte) prev_pixel = winSurface.getPixel(xPos,
                                    yPos);

                            draw(xPos, yPos, _r, _g, _b, brushType, brushSize);

                            // Create a new command based on the action just performed
                            // The r, g, b values of commands are the color of the pixel before being painted over
                            auto prev_state = new SurfaceOperation(winSurface.mSurface,
                                    xPos, yPos, 0, 0, 0, this.brushType, this.brushSize);
                            undoQueue ~= prev_state;
                            // writeln("Undo length:");
                            // writeln(UndoQueue.length);
                        }

                    }
                }
                else if (xPos < width && yPos <= btn_height)
                {
                    // button functions
                    if (e.type == SDL_MOUSEBUTTONUP)
                    {
                        ifButtonsClicked(xPos, yPos);
                    }
                }
            }

            // Blit the surace (i.e. update the window with another surfaces pixels
            //                       by copying those pixels onto the window).
            SDL_BlitSurface(winSurface.mSurface, null, window.getWindowSurface(), null);
            SDL_BlitSurface(winSurface.btnSurface, null,
                    window.getWindowSurface(), &buttonDestRect);

            // Update the window surface
            window.updateWindowSurface();
            // Delay for 16 milliseconds
            // Otherwise the program refreshes too quickly
            SDL_Delay(16);
        }

    }

}

void main()
{
    Client client = new Client;
    client.run();
}
