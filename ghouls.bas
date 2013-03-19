#include once "includes/list.bas"
#include once "includes/bool.bas"
#include once "tilemap.bas"

Randomize Timer

Enum Mirror
    None = 0
    NE_SW = 1
    NW_SE = 2
End Enum

Dim Shared mirrorText(3) as String
mirrorText(0) = "None"
mirrorText(1) = "NE-SW ( / )"
mirrorText(2) = "NW_SE ( \ )"

' Forward decl. for Area pointers.
'Type AreaPtr as Area Ptr

Type TileData
    private:
        _tile as Tile Ptr = 0
        directionMap(4) as Direction
        mirrorType as Mirror = Mirror.None
        areaID as Integer = 0
        Declare Sub restoreDirectionMap()
    public:
        Declare Constructor( __tile as Tile Ptr )
        Declare Sub setArea( _areaID as integer )
        Declare Function getArea() as integer
        Declare Function getMirror() as Mirror
        Declare Function travelThrough( from as Direction ) as Direction
        Declare Sub setMirror( _mirrorType as Mirror )
        Declare Sub removeMirror()
        Declare Sub debug()
End Type

Constructor TileData( __tile as Tile Ptr )
    if __tile <> 0 then
        _tile = __tile
    else
        print "Error: Can't construct TileData without Tile object."
    end if
    restoreDirectionMap()
End Constructor

Sub TileData.restoreDirectionMap()
    directionMap(Direction.North) = Direction.North
    directionMap(Direction.East) = Direction.East
    directionMap(Direction.South) = Direction.South
    directionMap(Direction.West) = Direction.West
End Sub

Sub TileData.setArea( _areaID as integer )
    areaID = _areaID
End Sub

Function TileData.getArea() as integer
    return areaID
End Function 

Sub TileData.setMirror( _mirrorType as Mirror )
    mirrorType = _mirrorType
    if mirrorType = Mirror.NE_SW then
        directionMap(Direction.North) = Direction.East
        directionMap(Direction.East) = Direction.North
        directionMap(Direction.South) = Direction.West
        directionMap(Direction.West) = Direction.South
    elseif mirrorType = Mirror.NW_SE then
        directionMap(Direction.North) = Direction.West
        directionMap(Direction.East) = Direction.South
        directionMap(Direction.South) = Direction.East
        directionMap(Direction.West) = Direction.North
    else
        print "error: no valid mirrortype to set!: "; _mirrorType
    end if
End Sub

Sub TileData.removeMirror()
    restoreDirectionMap()
End Sub    

Function TileData.getMirror() as Mirror
    return mirrorType
End Function

Function TileData.travelThrough ( from as Direction ) as Direction
    return directionMap(from)
End Function

Sub TileData.debug()
    print "-- TileData --"
    print "Part of Area(id): "; areaID
    print "Mirror: "; mirrorText(mirrorType)    
End Sub    

'----------
' An area
'----------
Type Area
    private:
        id as integer = 0
        tileList as MyList.list
        maxSize as integer = 0
        hasMirror as Bool = Bool.False
        Declare Function getRandomDirection() as Direction
        Declare Sub addTiles( _tile as Tile Ptr, fromTile as Tile Ptr, s as Integer )
    public:
        Declare Constructor ( _id as integer, startTile as Tile Ptr, maxSize as integer )
        Declare Sub placeRandomMirror()
        Declare Sub debug()
        Declare Sub debugList()
End Type

Constructor Area ( _id as integer, startTile as Tile Ptr, _maxSize as integer )
    id = _id
    maxSize = _maxSize
    addTiles(startTile,0,1)
    'print "Area "; id; " :"
    'print "Added "; tileList.getSize(); " tiles."
End Constructor

Sub Area.addTiles( _tile as Tile Ptr, fromTile as Tile Ptr, s as Integer )
    'print "Area now has size: "; s
    if _tile <> 0 and tileList.getSize() < maxSize then
        Dim _data as TileData Ptr = _tile->getData()
        if _data <> null then
            if _data->getArea() = 0 then
                tileList.addObject(_tile)
                _data->setArea(id)          
                Dim nextTile as Tile Ptr
                for d as integer = 0 to 3
                    nextTile = _tile->getNeighbor(d)
                    if nextTile <> fromTile and nextTile <> 0 then
                        addTiles( nextTile, _tile, s + 1 )
                    end if    
                next d
            end if    
        else
            print "error: Tile without TileData object."
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

Sub Area.placeRandomMirror()
    Dim randomIndex as Integer = int(rnd * tileList.getSize())
    Dim index as integer = 0
    Dim tempNode as MyList.ListNode ptr = tileList.firstNode
    While tempNode <> 0    
        Dim tp as Tile ptr = tempNode->objectPtr
        if index = randomIndex then
            If tp <> 0 then                
                Dim td as TileData ptr = tp->getData()
                If td <> 0 then
                    print
                    print "** Area: placing mirror at tile "; randomIndex; " **"
                    tp->debug()
                    td->debug()
                    Dim r as Integer = int(rnd * 2)
                    if r = 0 then
                        td->setMirror(Mirror.NE_SW)
                    else
                        td->setMirror(Mirror.NW_SE)
                    end if
                Else
                    print "Error: no TileData!"
                End if    
            Else
                print "Error: no Tile object!"
            End if
            exit while
        End if    
        index += 1
        tempNode = tempNode->nextNode
    Wend
End Sub    

Sub Area.debug()
    print "-- Area --"
    print "id "; id
    print "# of tiles "; tileList.getSize()
    Dim tileIterator as MyList.Iterator = MyList.Iterator(tileList)
    tileIterator.resetList()
    while tileIterator.hasNextObject() = Bool.True
        Dim tp as Tile ptr = tileIterator.getNextObject()
        if tp <> 0 then
            tp->debug()
            Dim td as TileData ptr = tp->getData()
            if td <> 0 then
                td->debug()
            end if    
        end if    
    wend    
End Sub

Sub Area.debugList()
    print "** TILE LIST **"
    tileList.debug()
End Sub    

'-------------
' Main
'-------------
Dim w as integer = 6
Dim h as integer = 6
Dim map as TileMap = TileMap(h,w)
Dim areaList as MyList.list

' create TileData for each Tile
For i as integer = 0 to h - 1
    For j as integer = 0 to w - 1
        Dim t as Tile Ptr = map.getTile(j,i)
        if t <> Null then
            t->setData(new TileData(t))
        end if
    Next j
Next i

' create Areas
Dim nextArea as integer = 1
For i as integer = 0 to h - 1
    For j as integer = 0 to w - 1
        Dim tp as Tile Ptr = map.getTile(j,i)
        Dim dp as TileData Ptr = tp->getData()
        if dp <> Null then
            if dp->getArea() = 0 then
                Dim size as integer = int(rnd * 6) + 1
                areaList.addObject(new Area(nextArea,tp,size))
                nextArea += 1
            end if    
        end if    
    Next j
Next i

'Print "iterating over areas"
'Print areaList.getSize()
Print "** AREA LIST **"
'areaList.debug()
Dim areaIterator as MyList.Iterator = MyList.Iterator(areaList)
Dim areaPtr as Area ptr = areaIterator.getNextObject()
While areaPtr <> 0    
    areaPtr->placeRandomMirror()
    'areaPtr->debug()
    areaPtr = areaIterator.getNextObject()    
Wend
'Print "done"

'------------------
' Walk through map
'------------------
Screen 18

Dim cDir as Direction = Direction.North
Dim cTile as Tile Ptr = map.getTile(3,3)

Dim shared xOffset as integer = 10
Dim shared yOffset as integer = 10
Dim shared squareSize as integer = 32

Sub drawBox( x as integer, y as integer, c as integer )
    x = (x * squareSize) + xOffset
    y = (y * squareSize) + YOffset
    line(x,y)-(x+squareSize,y+squareSize),c,BF
End Sub

Sub drawMirror1( x as integer, y as integer )
    x = (x * squareSize) + xOffset
    y = (y * squareSize) + YOffset
    line(x,y)-(x+squareSize,y+squareSize),0,BF
    line(x,y)-(x+squareSize,y+squareSize),7,B
    line(x+squareSize,y)-(x,y+squareSize),7
End Sub

Sub drawMirror2( x as integer, y as integer )    
    x = (x * squareSize) + xOffset
    y = (y * squareSize) + YOffset
    line(x,y)-(x+squareSize,y+squareSize),0,BF
    line(x,y)-(x+squareSize,y+squareSize),7,B
    line(x,y)-(x+squareSize,y+squareSize),7
End Sub

Dim k as String
Do
    ' draw the map
    For i as integer = 0 to h - 1
        For j as integer = 0 to w - 1
            Dim t as Tile Ptr = map.getTile(j,i)
            
            if t = cTile then                
                drawBox(j,i,4)
            else
                dim _data as TileData ptr = t->getData()
                if _data <> null then
                    Dim m as Mirror = _data->getMirror()
                    if m <> Mirror.None then
                        if m = Mirror.NE_SW then
                            drawMirror1(j,i)
                        else
                            drawmirror2(j,i)
                        end if
                    else    
                        drawBox(j,i,_data->getArea())
                    end if
                end if    
            end if    
        Next j
    Next i
    k = inkey
    Dim newTile as Tile Ptr = Null
    Select Case k
        case "w":            
            cDir = Direction.North
            'newTile = cTile->getNeighbor(Direction.North)            
        case "d":
            cDir = Direction.East
            'newTile = cTile->getNeighbor(Direction.East)            
        case "s":
            cDir = Direction.South
            'newTile = cTile->getNeighbor(Direction.south)
        case "a":            
            cDir = Direction.West
            'newTile = cTile->getNeighbor(Direction.West)
        case chr(13):
            dim _data as TileData ptr = cTile->getData()
            if _data <> 0 then                
                cDir = _data->travelThrough(cDir)
                newTile = cTile->getNeighbor(cDir)
                if newTile <> Null then cTile = newTile
            end if    
    End Select    

    sleep 10,1
Loop while k <> chr(27)

Enum TileSprite
    Border_None = 0
    Border_North
    Border_North_East
    Border_North_South
    Border_North_West
    Border_East
    Border_East_South
    Border_East_West
    Border_South
    Border_South_West
    Border_West
    Mirror_NE_SW
    Mirror_NW_SE
    NumberOfSprites
End Enum    

Type Robot
    private:
        beamStartDirection as Direction
        beamEndDirection as Direction
        startTile as Tile Ptr = 0
        endTile as Tile Ptr = 0
        reflections as Integer = 0
    public:
        Declare Constructor( _startTIle as Tile Ptr )
        Declare Sub shootBeam()
End Type

Constructor Robot( _startTile as Tile Ptr )
End Constructor

Sub Robot.shootBeam()
End Sub

Type Board
    private:
        _tileMap as TileMap ptr
        boardWidth as integer
        boardHeight as integer
        tileSprites(TileSprite.NumerOfSprites) as any ptr
        edges(4) as Tile Ptr Ptr
        Declare Sub loadSprites()
        Declare Sub drawTile()
    public:
        Declare Constructor (_boardWidth,_boardHeight)
End Type

Constructor Board
End Constructor

Sub Board.loadSprites
    tileSprites(TileSprite.Border_None) = ImageCreate()
    
End Sub

System
