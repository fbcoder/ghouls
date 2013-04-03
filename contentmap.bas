#include once "tilemap.bas"

Type ContentMap    
    private:
        map(6,6) as String
        _height as integer
        _width as integer
    public:
        Declare Constructor( w as integer, h as integer )
        Declare Sub setCell( _coord as TileMap_.Coord Ptr, _string as String ) 
        Declare Function getCell( _coord as TileMap_.Coord Ptr ) as String
End Type

Constructor ContentMap( w as integer, h as integer )
    _height = w
    _width = h
    for i as integer = 0 to _height - 1
        for j as integer = 0 to _width - 1
            map(j,i) = "   "
        next j
    next i    
End Constructor

Sub ContentMap.setCell(_coord as TileMap_.Coord Ptr, _string as String) 
    'print "aaaa"
    'sleep
    if len(_string) <> 3 then
        print "Error: cell of ContentMap must be exactly 3 chars long."
        sleep
        end
    else
        'print "Got string: ";_string
        'sleep
    end if
    map(_coord->x,_coord->y) = _string
End Sub

Function ContentMap.getCell(_coord as TileMap_.Coord Ptr) as String
    return map(_coord->x,_coord->y)
End Function    
