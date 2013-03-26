#include once "includes/bool.bas"
#include once "includes/direction.bas"

NameSpace TileMap_

Const DEFAULT_MAPWIDTH = 6
Const DEFAULT_MAPHEIGHT = 6

Type Coord
    x as integer
    y as integer
End Type

'--------
' a Tile
'--------
Type Tile
    private:
        _coord as Coord ptr
        neighbor(4) as Tile Ptr
    public:
        Declare Constructor()
        Declare Destructor()
        'Declare Sub setData( _dataPtr as Any Ptr )
        Declare Sub setCoord( _x as integer, _y as integer )
        Declare Sub setNeighbor( _direction as Direction, _tilePtr as Tile Ptr )        
        Declare Function getNeighbor( _direction as Direction ) as Tile Ptr
        'Declare Function getData() as Any Ptr
        Declare Function getCoord() as Coord Ptr
        Declare Function getCoordString() as String
        Declare Sub debug()
End Type

Constructor Tile()
End Constructor

Destructor Tile()
    if _coord <> 0 then
        delete _coord
    end if    
End Destructor

Sub Tile.setCoord( _x as Integer, _y as Integer )
    if _coord = 0 then
        _coord = new Coord(_x,_y)
    else
        _coord->x = _x
        _coord->y = _y
    end if    
End Sub

Sub Tile.setNeighbor( _direction as Direction, _tilePtr as Tile Ptr )
    ' prinline for debugging, check the value sent by map constructor
    'print directionNames(_direction) & " -> " & _tilePtr
    neighbor(_direction) = _tilePtr
End Sub

'Sub Tile.setData( _dataPtr as Any Ptr )
'    dataPtr = _dataPtr
'End Sub
'
'Function Tile.getData() as Any Ptr
'    return dataPtr
'End Function

Function Tile.getNeighbor ( _direction as Direction ) as Tile Ptr
    if _direction >= Direction.North and _direction <= Direction.West then        
        return neighbor(_direction)
    else
        print "Error: wrong direction! "; _direction
        sleep
        end
    end if
End Function

Function Tile.getCoord() as Coord Ptr
    if _coord <> 0 then
        return _coord
    end if
    print "Error: Tile has no coordinates set!"
    sleep
    end
    ' should not get here
    return 0
End Function

Function Tile.getCoordString() as String
    if _coord <> 0 then
        return "(" & _coord->x & "," & _coord->y & ")"
    end if
    return "NO COORDS!"        
End Function

Sub Tile.debug()
    print "-- Tile --"
    if _coord <> 0 then
        print using "Tile at ##_,##"; _coord->x; _coord->y
        for i as integer = 0 to 3
            print "Neighbor " & directionNames(i) & " is @" & neighbor(i)
        next i
    else
        print "Tile has no assigned coordinate."
    end if
End Sub

'------------
' Tile Map
'------------
Type TileMap
    private:
        mapHeight as Integer
        mapWidth as Integer
        map(DEFAULT_MAPWIDTH,DEFAULT_MAPHEIGHT) as Tile Ptr
    public:
        Declare Constructor( _width as Integer, _height as Integer )
        Declare Destructor()
        Declare Function getTile( col as Integer, row as Integer ) as Tile Ptr
        Declare Sub debug()
End Type

Constructor TileMap( _width as Integer, _height as Integer )
    mapWidth = _width
    mapHeight = _height
    
    'Create new Tile objects
    for row as integer = 0 to (mapHeight - 1)
        for col as integer = 0 to (mapWidth - 1)            
            map(col,row) = new Tile
        next col    
    next row
    
    for row as integer = 0 to (mapHeight - 1)
        for col as integer = 0 to (mapWidth - 1)
            map(col,row)->setCoord(col,row)

            if row = 0 then 
                map(col,row)->setNeighbor(Direction.North,0)
            else
                map(col,row)->setNeighbor(Direction.North,map(col, row - 1))
            end if
            
            if col = 0 then
                map(col,row)->setNeighbor(Direction.West,0)
            else        
                map(col,row)->setNeighbor(Direction.West,map(col - 1, row))
            end if
            
            if row = (mapHeight - 1) then
                map(col,row)->setNeighbor(Direction.South,0)
            else
                map(col,row)->setNeighbor(Direction.South,map(col, row + 1))
            end if
            
            if col = (mapWidth - 1) then
                map(col,row)->setNeighbor(Direction.East,0)
            else
                map(col,row)->setNeighbor(Direction.East,map(col + 1, row))
            end if 
        next col
    next row
End Constructor

Destructor TileMap()
    for row as integer = 0 to (mapHeight - 1)
        for col as integer = 0 to (mapWidth - 1)
            delete map(col,row)
        next col    
    next row
End Destructor

Function TileMap.getTile( col as Integer, row as Integer ) as Tile Ptr
    if col >= 0 and col <= (mapWidth - 1) and row >= 0 and row <= (mapHeight - 1) then
        return map(col,row)
    end if
    return 0
End Function

Sub TileMap.debug()                
    print "This map contains the following tiles: "
    For row as integer = 0 to (mapHeight - 1)
        For col as integer = 0 to (mapWidth - 1)
            print using "Debug for tile &_,& :";row;col
            print "Address: " & map(col,row) ' Zero for all tiles!                        
            if map(col,row) <> 0 then
                ' Never gets here
                map(col,row)->debug()       
            end if
        Next col
    Next row    
End Sub

End NameSpace
