Const Null = 0
Const DEFAULT_MAPWIDTH = 6
Const DEFAULT_MAPHEIGHT = 6

Enum Direction
    North = 0
    East = 1
    South = 2
    West = 3
End Enum

Dim Shared directionNames(4) as String
directionNames(Direction.North) = "North"
directionNames(Direction.East) = "East"
directionNames(Direction.South) = "South"
directionNames(Direction.West) = "West"

Enum Bool
    True = 0
    False = not True
End Enum

'--------
' a Tile
'--------

' Forwarded type decl.
Type TilePtr as Tile ptr

Type Tile
    private:
        dataPtr as Any Ptr = null
        x as integer = 0
        y as integer = 0
        directionMap(4) as Direction
        neighbor(4) as TilePtr
    public:
        Declare Constructor()
        Declare Sub setDirectionMap( _directionMap() as Direction )
        Declare Sub setData( _dataPtr as Any Ptr )
        Declare Sub setCoords( _x as integer, _y as integer )
        Declare Sub setNeighbor( _direction as Direction, _tilePtr as TilePtr )
        Declare Function travelThrough( from as Direction ) as TilePtr
        Declare Function getNeighbor( _direction as Direction ) as TilePtr
        Declare Function getData() as Any Ptr
        Declare Sub debug()
End Type

Constructor Tile()
    Dim defaultDirectionMap(4) as Direction = {Direction.South,Direction.West,Direction.North,Direction.East}
    setDirectionMap( defaultDirectionMap() )
End Constructor

Sub Tile.setDirectionMap( _directionMap() as Direction )
    for i as integer = 0 to 3
        directionMap(i) = _directionMap(i)
    next i    
End Sub

Sub Tile.setCoords( _x as Integer, _y as Integer )
    x = _x
    y = _y
End Sub

Sub Tile.setNeighbor( _direction as Direction, _tilePtr as TilePtr )
    ' prinline for debugging, check the value sent by map constructor
    'print directionNames(_direction) & " -> " & _tilePtr
    neighbor(_direction) = _tilePtr
End Sub

Sub Tile.setData( _dataPtr as Any Ptr )
    dataPtr = _dataPtr
End Sub

Function Tile.getData() as Any Ptr
    return dataPtr
End Function

Function Tile.travelThrough ( from as Direction ) as TilePtr
    return neighbor(directionMap(from))
End Function

Function Tile.getNeighbor ( _direction as Direction ) as TilePtr
    return neighbor(_direction)
End Function

Sub Tile.debug()
    print using "Tile at ##_,##"; x; y
    for i as integer = 0 to 3
        print "Neighbor " & directionNames(i) & " is @" & neighbor(i)
    next i
End Sub

'------------
' Tile Map
'------------
Type TileMap
    private:
        mapHeight as Integer
        mapWidth as Integer
        map(DEFAULT_MAPWIDTH,DEFAULT_MAPHEIGHT) as TilePtr
    public:
        Declare Constructor( _height as Integer, _width as Integer )
        Declare Destructor()
        Declare Function getTile( col as Integer, row as Integer ) as TilePtr
        Declare Sub debug()
End Type

Constructor TileMap( _height as Integer, _width as Integer )
    mapWidth = _width
    mapHeight = _height
    'redim map(mapWidth,mapHeight) as TilePtr
    
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
                map(col,row)->setNeighbor(Direction.North,Null)
            else
                map(col,row)->setNeighbor(Direction.North,map(col, row - 1))
            end if
            
            ' for debugging
            'print map(col,row)->getNeighbor(Direction.North)
            
            if col = 0 then
                map(col,row)->setNeighbor(Direction.West,Null)
            else        
                map(col,row)->setNeighbor(Direction.West,map(col - 1, row))
            end if
            
            if row = (mapHeight - 1) then
                map(col,row)->setNeighbor(Direction.South,Null)
            else
                map(col,row)->setNeighbor(Direction.South,map(col, row + 1))
            end if
            
            if col = (mapWidth - 1) then
                map(col,row)->setNeighbor(Direction.East,Null)
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

Function TileMap.getTile( col as Integer, row as Integer ) as TilePtr
    if col >= 0 and col <= (mapWidth - 1) and row >= 0 and row <= (mapHeight - 1) then
        return map(col,row)
    end if
    return Null
End Function

Sub TileMap.debug()
    print "This map contains the following tiles: "
    For row as integer = 0 to (mapHeight - 1)
        For col as integer = 0 to (mapWidth - 1)
            print using "Debug for tile &_,& :";row;col
            print "Address: " & map(col,row) ' Zero for all tiles!                        
            if map(col,row) <> Null then
                ' Never gets here
                map(col,row)->debug()       
            end if
        Next col
    Next row    
End Sub

'------
' Test
'------
'Dim _map as TileMap = TileMap(6,6)
'_map.debug()
'sleep
