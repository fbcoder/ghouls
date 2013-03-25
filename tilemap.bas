#include once "includes/bool.bas"

Const DEFAULT_MAPWIDTH = 6
Const DEFAULT_MAPHEIGHT = 6

Enum Direction
    North = 0
    East = 1
    South = 2
    West = 3
End Enum

Type Coord
    x as integer
    y as integer
End Type

Type Tile
    private:
        _coord as Coord ptr = 0
        neighbor(3) as Tile Ptr
    public:
        Declare Constructor()
        Declare Destructor()
        Declare Sub setCoords( _x as integer, _y as integer )
        Declare Sub setNeighbor( _direction as Direction, _tilePtr as Tile Ptr )        
        Declare Function getNeighbor( _direction as Direction ) as Coord Ptr        
        Declare Function getCoord() as Coord Ptr        
        Declare Function getCoordString() as String
        Declare Sub debug()
        directionNames(3) as String
End Type

Constructor Tile()
    directionNames(Direction.North) = "North"
    directionNames(Direction.East) = "East"
    directionNames(Direction.South) = "South"
    directionNames(Direction.West) = "West"
    for i as integer = 0 to 3
        neighbor(i) = 0
    next i    
End Constructor

Destructor Tile()
    if _coord <> 0 then
        delete _coord
    end if    
End Destructor

Sub Tile.setCoords( _x as Integer, _y as Integer )
    _coord = new Coord(_x,_y)
End Sub

Sub Tile.setNeighbor( _direction as Direction, _tilePtr as Tile Ptr )
    ' prinline for debugging, check the value sent by map constructor
    'print directionNames(_direction) & " -> " & _tilePtr
    neighbor(_direction) = _tilePtr
End Sub

'Sub Tile.setData( _dataPtr as Any Ptr )
    'dataPtr = _dataPtr
'End Sub

'Function Tile.getData() as Any Ptr
    'return dataPtr
'End Function

Function Tile.getCoord() as Coord Ptr
    return _coord
End Function    

Function Tile.getNeighbor ( _direction as Direction ) as Coord ptr
    if _direction >= Direction.North and _direction <= Direction.West then        
        return neighbor(_direction)->getCoord()
    else
        print "Error: wrong direction! "; _direction
        sleep
        end
    end if
End Function

Function Tile.getCoordString() as String
    if _coord <> 0 then
        return "(" & _coord->x & "," & _coord->y & ")"
    end if
End Function

Sub Tile.debug()
    print "-- Tile --"
    print using "Tile at "; getCoordString()
    print " [";str(@this);"]"
    for i as integer = 0 to 3
        print "Neighbor " & directionNames(i) & " is @" & neighbor(i)
    next i
    print "----------"
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
            map(col,row)->setCoords(col,row)
            ' for debugging
            'print "Handling tile: " & col & "," & row
            'print "Address: " & map(col,row)
            
            if row = 0 then 
                map(col,row)->setNeighbor(Direction.North,0)
            else
                map(col,row)->setNeighbor(Direction.North,map(col, row - 1))
            end if
            
            ' for debugging
            'print map(col,row)->getNeighbor(Direction.North)
            
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
    else
        print "Wrong coordinates to fetch tile from: ("; col; ","; row ;")"
        sleep
        end
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
