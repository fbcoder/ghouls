#include once "includes/list.bas"
#include once "tilemap.bas"

Enum Mirror
    None = 0
    NE_SW = 1
    NW_SE = 2
End Enum

' Forward decl. for Area pointers.
Type AreaPtr as Area Ptr

Type TileData
    private:
        mirrorType as Mirror = Mirror.None
        _areaPtr as AreaPtr = Null
    public:
        Declare Constructor()
        Declare Sub setArea( __areaPtr as AreaPtr )
        Declare Function getArea() as AreaPtr
End Type

Constructor TileData()
End Constructor

Sub TileData.setArea( __areaPtr as AreaPtr )
    _areaPtr = __areaPtr
End Sub

Function TileData.getArea() as AreaPtr
    return _areaPtr
End Function 

'----------
' An area
'----------
Type Area
    private:
        tileList as MyList.list
        maxSize as integer = 0
        size as integer = 0
        hasMirror as Bool = Bool.False
        Declare Function getRandomDirection() as Direction
    public:
        Declare Constructor ( startTile as TilePtr, maxSize as integer )
        Declare Sub createArea( startTile as TilePtr )
        Declare Sub addTiles( _tile as TilePtr, byref s as Integer )
End Type

Constructor Area ( startTile as TilePtr, _maxSize as integer )
    maxSize = _maxSize
    addTiles(startTile,1)
End Constructor

Sub Area.addTiles( _tile as TilePtr, byref s as Integer )
    if _tile <> Null and s <= maxSize then
        Dim _data as TileData Ptr = _tile->getData()
        if _data->getArea() = Null then
            tileList.addObject(_tile)
            _data->setArea(@this)
        end if            
        Dim d as Direction = getRandomDirection()
        if d <> -1 then
            Dim i as integer = 0
            While i < 3
                dim nextTile as TilePtr = _tile->getNeighbor(d)
                if nextTile <> Null then 
                        Dim thisData as TileData Ptr = nextTile->getData()
                        if  thisData->getArea() = Null then
                            addTiles(nextTile,s+1)
                        end if    
                end if    
                d += 1
                if d > 3 then 
                    d = Direction.North
                end if    
                i += 1                                   
            Wend
        end if
    end if    
End Sub    

Function Area.getRandomDirection() as Direction
    Dim r as integer = int(rnd * 4)
    Select Case r
        case 0:
            return Direction.North
        case 1:
            return Direction.East
        case 2:
            return Direction.South
        case 3:
            return Direction.West
    End Select
    return -1
End Function    

'-------------
' Main
'-------------
Dim w as integer = 6
Dim h as integer = 6
Dim map as TileMap = TileMap(h,w)

For i as integer = 0 to h - 1
    For j as integer = 0 to w - 1
        Dim t as TilePtr = map.getTile(j,i)
        if t <> Null then
            t->setData(new TileData)
        end if
        locate 1 + i,1 + j
        print "*"
        't->debug()
    Next j
Next i

'------------------
' Walk through map
'------------------
Dim cRow as integer = 3
Dim cCol as integer = 3
Dim cTile as TilePtr = map.getTile(cRow,cCol)

'map.debug()
'Sleep

Dim k as String
Do
    For i as integer = 0 to h - 1
        For j as integer = 0 to w - 1
            Dim t as TilePtr = map.getTile(j,i)
            locate 1 + i,1 + j
            if t = cTile then                
                print "@"
            else
                print "*"
            end if    
        Next j
    Next i
    k = inkey
    Select Case k
        case "w":
            'locate 10,1
            'print cTile->getNeighbor(Direction.North)
            if cTile->travelThrough(Direction.North) <> null then
                cTile = cTile->travelThrough(Direction.North)
            end if    
        case "d":
            if cTile->travelThrough(Direction.East) <> null then
                cTile = cTile->travelThrough(Direction.East)
            end if    
        case "s":
            if cTile->travelThrough(Direction.South) <> null then
                cTile = cTile->travelThrough(Direction.south)
            end if            
        case "a":
            if cTile->travelThrough(Direction.West) <> null then
                cTile = cTile->travelThrough(Direction.West)
            end if            
    End Select
    sleep 10,1
Loop while k <> chr(27)