import Surface : Surface;

@("Test change pixel")
unittest{
    
    Surface imgSurface = Surface(640, 480);
    imgSurface.UpdateSurfacePixel(10, 10);
    auto p = imgSurface.getPixel(10,10);
    assert(p[0]== 255 && p[1]== 128 && p[2]==32);
    destroy(imgSurface);
}