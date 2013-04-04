' Graphical board.
#include once ""
#include once ""
#inlcude once ""

Dim tankColor() as uinteger
tankColor(0) = rgb(&hff,&hff,&hff)
tankColor(1) = rgb(&h,&h,&h)
tankColor(2) = rgb(&h,&h,&h)
tankColor(3) = rgb(&h,&h,&h)
tankColor(4) = rgb(&h,&h,&h)

type grahicalBoard
    private:
        'required data maps
        _areaMap
        _mirrorMap
        
        'more data from the board
        tankList as MyList.List Ptr
        
        'grapics related
        xOffset as integer
        yOffset as integer
        
        declare function getTileFromMouseCoords ()
        declare sub manipulateMirror (_tile)
        declare sub drawTankBeam ()
        declare sub initgraphics ()
    public:
        declare constructor ( _xOffset as integer, _yOffset as integer, _board as Board ptr )
        declare sub _draw ()
end type    

'--------------------------
' Init the graphical board
'--------------------------






