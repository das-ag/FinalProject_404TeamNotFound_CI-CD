import Window : Window;

@("Test getWindowSurface")
unittest{
    
    Window testWindow = Window("test window", 640, 480);
    assert(testWindow.width == 640 && testWindow.height == 480);
    destroy(testWindow);
}
