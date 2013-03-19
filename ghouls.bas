#include once "includes/list.bas"
#include once "includes/bool.bas"
#include once "tilemap.bas"

Randomize Timer

Enum Mirror
    None = 0
    NE_SW = 1
    NW_SE = 2
End Enum

Enum TileSprite
    Border_None = 0
    Border_N
    Border_NE
    Border_NES
    Border_NESW
    Border_NEW
    Border_NS
    Border_NSW
    Border_NW
    Border_E
    Border_ES
    Border_ESW
    Border_EW
    Border_S
    Border_SW
    Border_W
    Mirror_NE_SW
    Mirror_NW_SE
End Enum

Dim Shared mirrorText(3) as String
mirrorText(0) = "None"
mirrorText(1) = "NE-SW ( / )"
mirrorText(2) = "NW_SE ( \ )"

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
        Declare Function getBorderType() as TileSprite
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

Function TileData.travelThrough( from as Direction ) as Direction
    return directionMap(from)
End Function

Function TileData.getBorderType() as TileSprite        
    Dim border as String = "----"
    for i as Direction = Direction.North to Direction.West
        if _tile->getNeighbor(i) <> null then
            Dim neighborData as TileData ptr
            neighborData = _tile->getNeighbor(i)->getData()
            if neighborData->getArea() <> areaID then
                mid(border,i+1,1)="x"
            end if
        else
            mid(border,i+1,1)="x"
        end if
    next i
    Select Case border
        Case "----":
            Return TileSprite.Border_None
        Case "x---":    
            Return TileSprite.Border_N
        Case "xx--":    
            Return TileSprite.Border_NE
        Case "xxx-":    
            Return TileSprite.Border_NES
        Case "xxxx":    
            Return TileSprite.Border_NESW
        Case "xx-x":    
            Return TileSprite.Border_NEW
        Case "x-x-":    
            Return TileSprite.Border_NS
        Case "x-xx":    
            Return TileSprite.Border_NSW
        Case "x--x":    
            Return TileSprite.Border_NW
        Case "-x--":    
            Return TileSprite.Border_E
        Case "-xx-":    
            Return TileSprite.Border_ES
        Case "-xxx":    
            Return TileSprite.Border_ESW
        Case "-x-x":    
            Return TileSprite.Border_EW
        Case "--x-":    
            Return TileSprite.Border_S
        Case "--xx":    
            Return TileSprite.Border_SW        
        Case "---x":    
            Return TileSprite.Border_W
    End Select
    Return TileSprite.Border_None
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

ScreenRes 640,480,32

Type Board
    private:
        areaList as MyList.List
        _tileMap as TileMap ptr
        boardWidth as integer
        boardHeight as integer
        tileSprites(20) as any Ptr
        spriteMap(6,6) as integer
        mirrorMap(6,6) as Mirror
        
        ' Sprites
        spriteSize as integer = 32
        
        ' Edges
        edges(4) as Tile Ptr Ptr
        
        ' Internal helpers
        Declare Sub createTileMap()
        Declare Sub createAreas()
        Declare Sub drawBorder( img as any Ptr, length as integer, n as integer, e as integer, s as integer, w as integer )
        Declare Sub loadSprites()
        Declare Sub drawTile()
        Declare Sub placeRandomMirrors()
        Declare Sub createSpriteMap()
    public:
        Declare Constructor( _boardWidth as integer, _boardHeight as integer )
        Declare Sub _draw( xOffset as integer, yOffset as integer )
End Type

Constructor Board( _boardWidth as integer, _boardHeight as integer )
	if _boardWidth <= 6 and _boardHeight <= 6 then
		boardWidth = _boardWidth
		boarDHeight = _boardHeight
		createTileMap()
		createAreas()
		placeRandomMirrors()
		loadSprites()
        createSpriteMap()
	else
		print "Error: board can be 6 x 6 at most."
	end if
End Constructor

Sub Board.drawBorder( img as any Ptr, length as integer, n as integer, e as integer, s as integer, w as integer )
    Dim borderColor as uinteger = rgb(128,128,128)
    Dim ul_x as integer = 0 
    Dim ul_y as integer = 0
    Dim ur_x as integer = length - 1
    Dim ur_y as integer = 0
    Dim bl_x as integer = 0
    Dim bl_y as integer = length - 1
    Dim br_x as integer = length - 1
    Dim br_y as integer = length - 1
    if n = 1 then Line img,(ul_x,ul_y)-(ur_x,ur_y),borderColor
    if e = 1 then Line img,(ur_x,ur_y)-(br_x,br_y),borderColor
    if s = 1 then Line img,(bl_x,bl_y)-(br_x,br_y),borderColor
    if w = 1 then Line img,(ul_x,ul_y)-(bl_x,bl_y),borderColor        
End Sub

Sub Board.loadSprites()
    ' create sprites for borders.
    For i as integer = TileSprite.Border_None to TileSprite.Border_W
        Dim floorColor as uinteger = rgb(0,128,128)            
        Dim thisImg as any ptr = imagecreate(spriteSize,spriteSize)            
        Line thisImg,(0,0)-(spriteSize-1,spriteSize-1),floorColor,BF
        
        Select Case i
            Case TileSprite.Border_None:
            Case TileSprite.Border_N:
                drawBorder(thisImg,spriteSize,1,0,0,0)
            Case TileSprite.Border_NE:
                drawBorder(thisImg,spriteSize,1,1,0,0)
            Case TileSprite.Border_NES:
                drawBorder(thisImg,spriteSize,1,1,1,0)
            Case TileSprite.Border_NESW:
                drawBorder(thisImg,spriteSize,1,1,1,1)
            Case TileSprite.Border_NEW:
                drawBorder(thisImg,spriteSize,1,1,0,1)
            Case TileSprite.Border_NS:
                drawBorder(thisImg,spriteSize,1,0,1,0)
            Case TileSprite.Border_NSW:
                drawBorder(thisImg,spriteSize,1,0,1,1)
            Case TileSprite.Border_NW:
                drawBorder(thisImg,spriteSize,1,0,0,1)
            Case TileSprite.Border_E:
                drawBorder(thisImg,spriteSize,0,1,0,0)
            Case TileSprite.Border_ES:
                drawBorder(thisImg,spriteSize,0,1,1,0)
            Case TileSprite.Border_ESW:
                drawBorder(thisImg,spriteSize,0,1,1,1)
            Case TileSprite.Border_EW:
                drawBorder(thisImg,spriteSize,0,1,0,1)
            Case TileSprite.Border_S:
                drawBorder(thisImg,spriteSize,0,0,1,0)
            Case TileSprite.Border_SW:
                drawBorder(thisImg,spriteSize,0,0,1,1)
            Case TileSprite.Border_W:
                drawBorder(thisImg,spriteSize,0,0,0,1)
        End Select
        
        tileSprites(i) = thisImg
    Next i
    
    'create sprites for mirrors
    Dim mirror1 as any ptr = imageCreate(spriteSize,spriteSize)                
    Dim as String picture1 = "pictures/mirror_orig.bmp"
    Dim as String picture2 = "pictures/mirror_flipped.bmp"
    Dim r as integer = bload(picture1,mirror1)
    If r <> 0 then
        print "error loading "; picture1;" : ";r
        sleep
        end
        'Line mirror1,(spriteSize-4,4)-(4,spriteSize-4),7
    end if    
    tileSprites(TileSprite.Mirror_NE_SW) = mirror1    
    Dim mirror2 as any ptr = imageCreate(spriteSize,spriteSize)    
    r = bload(picture2,mirror2)
    If r <> 0 then
        print "error loading "; picture2;" : ";r
        sleep
        end
        'Line mirror1,(spriteSize-4,4)-(4,spriteSize-4),7
    end if    
    'Line mirror2,(4,4)-(spriteSize-4,spriteSize-4),7
    tileSprites(TileSprite.Mirror_NW_SE) = mirror2
End Sub

Sub Board.createTileMap()
	_tilemap = new TileMap(boardWidth,boardHeight)
	' create TileData for each Tile
	For i as integer = 0 to (boardHeight - 1)
		For j as integer = 0 to (boardWidth - 1)
			Dim t as Tile Ptr = _tilemap->getTile(j,i)
			if t <> Null then
				t->setData(new TileData(t))
			end if
		Next j
	Next i
End Sub
    
Sub Board.createSpriteMap()
    For i as integer = 0 to (boardHeight - 1)
		For j as integer = 0 to (boardWidth - 1)
            Dim t as Tile Ptr = _tilemap->getTile(j,i)
            if t <> 0 then
                Dim td as TileData Ptr = t->getData()
                if td <> 0 then                    
                    spriteMap(j,i) = td->getBorderType()
                    mirrorMap(j,i) = td->getMirror()
                else
                    print "error! tile without tiledata!"
                end if    
            else
                print "error! no tile object!"
            end if    
		Next j
	Next i
End Sub    

Sub Board.createAreas()
	if _tileMap <> 0 then
		Dim nextArea as integer = 1
		For i as integer = 0 to (boardHeight - 1)
			For j as integer = 0 to (boardWidth - 1)
				Dim tp as Tile Ptr = _tileMap->getTile(j,i)
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
	end if
End Sub

Sub Board.placeRandomMirrors()
	Dim areaIterator as MyList.Iterator = MyList.Iterator(areaList)
	Dim areaPtr as Area ptr = areaIterator.getNextObject()
	While areaPtr <> 0    
		areaPtr->placeRandomMirror()
		areaPtr = areaIterator.getNextObject()    
	Wend
End Sub

Sub Board.drawTile()
End Sub

Sub Board._draw( xOffset as integer, yOffset as integer )
	for i as integer = 0 to (boardHeight - 1)
		for j as integer = 0 to (boardWidth - 1)
			Dim spriteX as integer = (j * 32) + xOffset
			Dim spriteY as integer = (i * 32) + yOffset
			Put (spriteX, SpriteY), tileSprites(spriteMap(j,i))
            if mirrorMap(j,i) <> Mirror.None then
                if mirrorMap(j,i) = Mirror.NE_SW then
                    Put (spriteX, SpriteY), tileSprites(TileSprite.Mirror_NE_SW), trans
                end if
                if mirrorMap(j,i) = Mirror.NW_SE then
                    Put (spriteX, SpriteY), tileSprites(TileSprite.Mirror_NW_SE), trans
                end if
            end if    
		next j
	next i	
End Sub

'--------------
' Init board.
'--------------
Dim b as Board = Board(6,6)
Cls
Dim xoffset as integer = (640 - (32*6)) \ 2
Dim yoffset as integer = (480 - (32*6)) \ 2
b._draw(xoffset,yoffset)
Sleep

System
