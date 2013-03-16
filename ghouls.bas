#include once "includes/list.bas"

Const Null = 0

Enum Direction
    North = 0
    East = 1
    South = 2
    West = 3
End Enum

Enum Mirror
    None = 0
    NE_SW = 1
    NW_SE = 2
End Enum    

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
    x as integer = 0
    y as integer = 0
    mirrorType as Mirror = Mirror.None
    directionMap(4) as Direction
    neighbor(4) as TilePtr
    Declare Sub setDirectionMap( _directionMap() as Direction )
    Declare Constructor()
    Declare Sub setMirror( mirrorType as Mirror, _directionMap() as Direction )
    Declare Function travelThrough( from as Direction ) as TilePtr
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

Sub Tile.setMirror( _mirrorType as Mirror, _directionMap() as Direction )
    mirrorTYpe = _mirrorType
    setDirectionMap( _directionMap() )
End Sub

Function Tile.travelThrough ( from as Direction ) as Tile ptr
    return neighbor(directionMap(from))
End Function

'----------
' An area
'----------
Type Area
    private:
        tileList as MyList.list
        maxSize as integer = 0
        hasMirror as Bool = Bool.False
    public:
        Declare Constructor ( startTile as Tile, maxSize_ as integer )
        Declare Sub createArea( )
End Type

Constructor Area ( startTile as Tile, _maxSize as integer )
    maxSize = _maxSize
    ' add Tiles to the list.
End Constructor

Sub Area.createArea( startTile as Tile
End Sub

'------------
' Main Stuff
'------------
Dim mapHeight as integer = 4
Dim mapWidth as integer = 4

Dim map(mapWidth,mapHeight) as Tile

For row as integer = 0 to mapHeight - 1
    For col as integer = 0 to mapWidth - 1
        map(col,row).x = col
        map(col,row).y = row
        Dim north as TilePtr
        if row = 0 then 
            map(col,row).neighbor(Direction.North) = Null
        else    
            map(col,row).neighbor(Direction.North) = @map(col, row - 1)
        end if
        
        if col = 0 then
            map(col,row).neighbor(Direction.West) = Null
        else        
            map(col,row).neighbor(Direction.West) = @map(col - 1, row)
        end if
        
        if row = (mapHeight - 1) then
            map(col,row).neighbor(Direction.South) = Null
        else
            map(col,row).neighbor(Direction.South) = @map(col, row + 1)
        end if
        
        if col = (mapWidth - 1) then
            map(col,row).neighbor(Direction.East) = Null
        else
            map(col,row).neighbor(Direction.East) = @map(col + 1, row)
        end if        
    Next col
Next row

Dim mirrors as integer = 6

System