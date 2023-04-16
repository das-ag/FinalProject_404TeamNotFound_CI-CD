module DrawStrategy;
import Surface : Surface;
import std.math;

interface DrawStrategy
{
    void draw(Surface* winSurface, int xPos, int yPos, ubyte r, ubyte g, ubyte b, ubyte brushSize);
}

class DrawSquareStrategy : DrawStrategy {

    void draw(Surface* winSurface, int xPos, int yPos, ubyte r, ubyte g, ubyte b, ubyte brushSize) {
        for(int w = -brushSize; w < brushSize; w++)
        {
            for(int h = -brushSize; h < brushSize; h++)
            {
                winSurface.UpdateSurfacePixel(cast(int)w + xPos, cast(int)h + yPos, r, g, b);   
            }
        }
    }
}



class DrawCircleStrategy : DrawStrategy {

    void draw(Surface* winSurface, int xPos, int yPos, ubyte r, ubyte g, ubyte b, ubyte brushSize) 
    {
        for(int y1 =- brushSize; y1 <= brushSize; y1++) 
        {
            for(int x1=-brushSize; x1 <=brushSize; x1++) 
            {
                if(x1 * x1 + y1 * y1 <= brushSize * brushSize) 
                {
                    winSurface.UpdateSurfacePixel(cast(int)y1 + xPos, cast(int)x1 + yPos, r, g, b);  
                }
            }
        }
    }
}

class DrawHeartStrategy : DrawStrategy {
    void draw(Surface* winSurface, int xPos, int yPos, ubyte r, ubyte g, ubyte b, ubyte brushSize) 
    {
        for(int x1= -3 * brushSize / 2; x1 <= brushSize; x1++) 
        {  
            for(int y1=-3 * brushSize / 2; y1 <= 3 * brushSize / 2; y1++) 
            {
                if((abs(x1) + abs(y1) < brushSize)
                    ||((-brushSize / 2 - x1) * (-brushSize / 2 - x1) + (brushSize / 2 - y1) * (brushSize / 2 - y1) <= brushSize * brushSize / 2)
                    ||((-brushSize / 2 - x1) * (-brushSize / 2 - x1) + (-brushSize / 2 - y1) * (-brushSize / 2 - y1) <= brushSize * brushSize / 2))
                        {
                            winSurface.UpdateSurfacePixel(cast(int)y1 + xPos, cast(int)x1 + yPos, r, g, b); 
                        }
            }
        }
    }
}

class DrawSpiralStrategy: DrawStrategy {
    void draw(Surface* winSurface, int xPos, int yPos, ubyte r, ubyte g, ubyte b, ubyte brushSize) {
        for (int y = 0; y < brushSize * 2; ++y)
        {
            for (int x = 0; x < brushSize * 2; ++x)
            {
                // reflect (x, y) to the top left quadrant as (i, j)
                int i = x;
                int j = y;
                if (i >= brushSize * 2 / 2) i = brushSize * 2 - i - 1;
                if (j >= brushSize *2 / 2) j = brushSize * 2 - j - 1;

                // calculate distance from center ring
                int u = abs(i - brushSize * 2 / 2);
                int v = abs(j - brushSize * 2/ 2);
                int d = u > v ? u : v;
                int L = brushSize * 2 / 2;
                if (brushSize * 2 % 4 == 0) L--;

                // fix the top-left-to-bottom-right diagonal
                if (y == x + 1 && y <= L) d++;

                if ((d + brushSize * 2 / 2) % 2 == 0 ) 
                {
                    winSurface.UpdateSurfacePixel(xPos + x, yPos + y, r, g, b); 
                }
            }

        }
    }
}

class EraseStrategy : DrawStrategy {

    void draw(Surface* winSurface, int xPos, int yPos, ubyte r, ubyte g, ubyte b, ubyte brushSize) {
        brushSize = 6;
        r = 0;
        g = 0;
        b = 0;
        
        for(int w = -brushSize; w < brushSize; w++)
        {
            for(int h = -brushSize; h < brushSize; h++)
            {
                winSurface.UpdateSurfacePixel(cast(int)w + xPos, cast(int)h + yPos, r, g, b);   
            }
        }
    }
}

