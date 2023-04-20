/***
 * Interface and classes for creating various paint brush styles. 
 * It implements factory design pattern.
 */

module DrawStrategy;
import Surface : Surface;
import std.math;

/**
Interface for classes that implement paint brush types.
*/
interface DrawStrategy
{
    /**
    Draws pixels based on paint brush type

    Params:
        winSurface = pointer to the SDL app surface to draw the pixels
        xPos = position of x coordinate to draw the pixel
        yPos = position of y coordinate to draw the pixel
        r = r value of rgb to draw the pixel
        g = g value of rgb to draw the pixel
        b = b value of rgb to draw the pixel
        brushSize = size of brush to draw the pixel
    */
    void draw(Surface* winSurface, int xPos, int yPos, ubyte r, ubyte g, ubyte b, ubyte brushSize);
}

/**
Class that draws square shaped paint brush
*/
class DrawSquareStrategy : DrawStrategy
{

    /**
    Draws square around a given x, y coordinate.

    Params:
        winSurface = pointer to the SDL app surface to draw the pixels
        xPos = position of x coordinate to draw the pixel
        yPos = position of y coordinate to draw the pixel
        r = r value of rgb to draw the pixel
        g = g value of rgb to draw the pixel
        b = b value of rgb to draw the pixel
        brushSize = size of square to draw around the given pixel
    */
    void draw(Surface* winSurface, int xPos, int yPos, ubyte r, ubyte g, ubyte b, ubyte brushSize)
    {
        for (int w = -brushSize; w < brushSize; w++)
        {
            for (int h = -brushSize; h < brushSize; h++)
            {
                winSurface.UpdateSurfacePixel(cast(int) w + xPos, cast(int) h + yPos, r, g, b);
            }
        }
    }
}

/**
Class that draws circle shaped paint brush
*/
class DrawCircleStrategy : DrawStrategy
{

    /**
    Draws circle around a given x, y coordinate.

    Params:
        winSurface = pointer to the SDL app surface to draw the pixels
        xPos = position of x coordinate to draw the pixel
        yPos = position of y coordinate to draw the pixel
        r = r value of rgb to draw the pixel
        g = g value of rgb to draw the pixel
        b = b value of rgb to draw the pixel
        brushSize = size of circle to draw around the given pixel
    */
    void draw(Surface* winSurface, int xPos, int yPos, ubyte r, ubyte g, ubyte b, ubyte brushSize)
    {
        for (int y1 = -brushSize; y1 <= brushSize; y1++)
        {
            for (int x1 = -brushSize; x1 <= brushSize; x1++)
            {
                if (x1 * x1 + y1 * y1 <= brushSize * brushSize)
                {
                    winSurface.UpdateSurfacePixel(cast(int) y1 + xPos, cast(int) x1 + yPos, r, g, b);
                }
            }
        }
    }
}

/**
Class that draws heart shaped paint brush
*/
class DrawHeartStrategy : DrawStrategy
{
    /**
    Draws heart around a given x, y coordinate.

    Params:
        winSurface = pointer to the SDL app surface to draw the pixels
        xPos = position of x coordinate to draw the pixel
        yPos = position of y coordinate to draw the pixel
        r = r value of rgb to draw the pixel
        g = g value of rgb to draw the pixel
        b = b value of rgb to draw the pixel
        brushSize = size of heart to draw around the given pixel
    */
    void draw(Surface* winSurface, int xPos, int yPos, ubyte r, ubyte g, ubyte b, ubyte brushSize)
    {
        for (int x1 = -3 * brushSize / 2; x1 <= brushSize; x1++)
        {
            for (int y1 = -3 * brushSize / 2; y1 <= 3 * brushSize / 2; y1++)
            {
                if ((abs(x1) + abs(y1) < brushSize)
                        || ((-brushSize / 2 - x1) * (-brushSize / 2 - x1) + (
                            brushSize / 2 - y1) * (brushSize / 2 - y1) <= brushSize * brushSize / 2)
                        || ((-brushSize / 2 - x1) * (-brushSize / 2 - x1) + (
                            -brushSize / 2 - y1) * (-brushSize / 2 - y1) <= brushSize * brushSize / 2))
                {
                    winSurface.UpdateSurfacePixel(cast(int) y1 + xPos, cast(int) x1 + yPos, r, g, b);
                }
            }
        }
    }
}

/**
Class that draws spiral shaped paint brush
*/
class DrawSpiralStrategy : DrawStrategy
{

    /**
    Draws spiral pattern around a given x, y coordinate.

    Params:
        winSurface = pointer to the SDL app surface to draw the pixels
        xPos = position of x coordinate to draw the pixel
        yPos = position of y coordinate to draw the pixel
        r = r value of rgb to draw the pixel
        g = g value of rgb to draw the pixel
        b = b value of rgb to draw the pixel
        brushSize = size of spiral to draw around the given pixel
    */
    void draw(Surface* winSurface, int xPos, int yPos, ubyte r, ubyte g, ubyte b, ubyte brushSize)
    {
        for (int y = 0; y < brushSize * 2; ++y)
        {
            for (int x = 0; x < brushSize * 2; ++x)
            {
                // reflect (x, y) to the top left quadrant as (i, j)
                int i = x;
                int j = y;
                if (i >= brushSize * 2 / 2)
                    i = brushSize * 2 - i - 1;
                if (j >= brushSize * 2 / 2)
                    j = brushSize * 2 - j - 1;

                // calculate distance from center ring
                int u = abs(i - brushSize * 2 / 2);
                int v = abs(j - brushSize * 2 / 2);
                int d = u > v ? u : v;
                int L = brushSize * 2 / 2;
                if (brushSize * 2 % 4 == 0)
                    L--;

                // fix the top-left-to-bottom-right diagonal
                if (y == x + 1 && y <= L)
                    d++;

                if ((d + brushSize * 2 / 2) % 2 == 0)
                {
                    winSurface.UpdateSurfacePixel(xPos + x, yPos + y, r, g, b);
                }
            }

        }
    }
}

/**
Class that erases pixels
*/
class EraseStrategy : DrawStrategy
{

    /**
    Erases pixels around a given x, y coordinate.
    Eraser is in the shape of a square.

    Params:
        winSurface = pointer to the SDL app surface to erase the pixels
        xPos = position of x coordinate to erase the pixel
        yPos = position of y coordinate to erase the pixel
        r = r value of rgb to erase the pixel - fixed to 0
        g = g value of rgb to erase the pixel - fixed to 0
        b = b value of rgb to erase the pixel - fixed to 0
        brushSize = size of square to erase around the given pixel
    */
    void draw(Surface* winSurface, int xPos, int yPos, ubyte r, ubyte g, ubyte b, ubyte brushSize)
    {

        r = 0;
        g = 0;
        b = 0;

        brushSize = 6;

        for (int w = -brushSize; w < brushSize; w++)
        {
            for (int h = -brushSize; h < brushSize; h++)
            {
                winSurface.UpdateSurfacePixel(cast(int) w + xPos, cast(int) h + yPos, r, g, b);
            }
        }
    }
}
