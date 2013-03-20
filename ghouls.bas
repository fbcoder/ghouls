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
    Beam_NE
    Beam_NS
    Beam_NW
    Beam_ES
    Beam_EW
    Beam_SW
    Tank_N
    Tank_E
    Tank_S
    Tank_W
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
        _isStartTile as Bool = Bool.False
        _isEndTile as Bool = Bool.False
        Declare Sub restoreDirectionMap()
    public:
        Declare Constructor( __tile as Tile Ptr )
        Declare Sub setArea( _areaID as integer )
        Declare Function getArea() as integer
        Declare Function getMirror() as Mirror
        Declare Function travelThrough( from as Direction ) as Direction
        Declare Function getBorderType() as TileSprite
        Declare Function isStartTile() as Bool
        Declare Function isEndTile() as Bool
        Declare Sub markAsStartPoint()
        Declare Sub markAsEndPoint()
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
                Dim randomDir as integer = int(rnd * 4)
                for i as integer = 0 to 3
                    Dim thisDir as integer = (randomDir + i) mod 4
                    nextTile = _tile->getNeighbor(thisDir)
                    if nextTile <> fromTile and nextTile <> 0 then
                        addTiles( nextTile, _tile, s + 1 )
                    end if    
                next i
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
    Dim tempNode as MyList.ListNode ptr = tileList.getFirst()
    While tempNode <> 0    
        Dim tp as Tile ptr = tempNode->getObject()
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
        tempNode = tempNode->getNext()
    Wend
End Sub    

Sub Area.debug()
    print "-- Area --"
    print "id "; id
    print "# of tiles "; tileList.getSize()
    Dim thisNode as MyList.ListNode Ptr = tileList.getFirst()
    while thisNode <> 0
        Dim tp as Tile ptr = thisNode->getObject()
        if tp <> 0 then
            tp->debug()
            Dim td as TileData ptr = tp->getData()
            if td <> 0 then
                td->debug()
            end if    
        end if
        thisNode = thisNode->getNext()
    wend    
End Sub

Sub Area.debugList()
    print "** TILE LIST **"
    tileList.debug()
End Sub    

'-------------
' Main
'-------------
Type Move
    _tile as Tile Ptr
    _tileSprite as TileSprite
    Declare Constructor( __tile as Tile Ptr, __tileSprite as TileSprite )
End Type    

Constructor Move( __tile as Tile Ptr, __tileSprite as TileSprite )
    _tile = __tile
    _tileSprite = __tileSprite
End Constructor

Type Robot
    private:
        beamStartDirection as Direction
        beamEndDirection as Direction
        startTile as Tile Ptr = 0
        endTile as Tile Ptr = 0
        reflections as Integer = 0
        path as MyList.List ptr = 0
        beamSpriteGenerator(4,4) as TileSprite
        Declare Sub addToPath( _tile as Tile Ptr, currentDir as Direction, prevDir as Direction )
    public:
        Declare Constructor( _startTIle as Tile Ptr, startDir as Direction )
        Declare Sub shootBeam()
        Declare Function getPath() as MyList.List ptr
        Declare Function getReflections() as Integer
        Declare Function getEndTile() as Tile Ptr
        Declare Function getEndDirection() as Direction
        Declare Function getStartTile() as Tile Ptr
        Declare Function getStartDirection() as Direction
End Type

Constructor Robot( _startTile as Tile Ptr, startDir as Direction )
    if _startTile <> 0 then
        path = new MyList.List()
        startTile = _startTile
        beamStartDirection = startDir    
    else
        print "Error: Can't init robot with no TileObject."
        end
    end if
    
    ' Give sprites for changing directions of the beam.
    beamSpriteGenerator(Direction.North,Direction.North) = TileSprite.Beam_NS
    beamSpriteGenerator(Direction.North,Direction.East) = TileSprite.Beam_ES
    beamSpriteGenerator(Direction.North,Direction.South) = TileSprite.Beam_NS
    beamSpriteGenerator(Direction.North,Direction.West) = TileSprite.Beam_SW
    
    beamSpriteGenerator(Direction.East,Direction.North) = TileSprite.Beam_NW
    beamSpriteGenerator(Direction.East,Direction.East) = TileSprite.Beam_EW
    beamSpriteGenerator(Direction.East,Direction.South) = TileSprite.Beam_SW
    beamSpriteGenerator(Direction.East,Direction.West) = TileSprite.Beam_EW
    
    beamSpriteGenerator(Direction.South,Direction.North) = TileSprite.Beam_NS
    beamSpriteGenerator(Direction.South,Direction.East) = TileSprite.Beam_NE
    beamSpriteGenerator(Direction.South,Direction.South) = TileSprite.Beam_NS
    beamSpriteGenerator(Direction.South,Direction.West) = TileSprite.Beam_NW
    
    beamSpriteGenerator(Direction.West,Direction.North) = TileSprite.Beam_NE
    beamSpriteGenerator(Direction.West,Direction.East) = TileSprite.Beam_EW
    beamSpriteGenerator(Direction.West,Direction.South) = TileSprite.Beam_ES
    beamSpriteGenerator(Direction.West,Direction.West) = TileSprite.Beam_EW
End Constructor

Sub Robot.addToPath( _tile as Tile Ptr, newDir as Direction, currentDir as Direction )
    '_tile->debug()
    if _tile <> 0 then
        Dim td as TileData Ptr = _tile->getData()
        if td <> 0 then
            if td->getMirror() <> Mirror.None then
                reflections += 1
            end if    
        end if    
        Dim newMove as Move Ptr = new Move( _tile, beamSpriteGenerator( currentDir, newDir ) )
        'print "Adding new move Object: "; newMove
        path->addObject( newMove )        
    else        
    end if    
End Sub

Sub Robot.shootBeam()
    reflections = 0
    Dim currentTile as Tile Ptr = startTile
    Dim currentDirection as Direction = beamStartDirection
    print
    print "** Constructing Path:"
    While currentTile <> 0
        currentTile->debug()
        Dim td as TileData Ptr = currentTile->getData()
        if td <> 0 then
            ' Temporary dir and tile
            Dim newDirection as Direction
            Dim newTile as Tile Ptr
            newDirection = td->travelThrough(currentDirection)
            newTile = currentTile->getNeighbor(newDirection)
            addToPath( currentTile, newDirection, currentDirection)
            ' Move to next
            if newTile = 0 then
                beamEndDirection = currentDirection
                endTile = currentTile
            end if    
            currentTile = newTile
            currentDirection = newDirection
        end if
    Wend
    'print "** Debug Path after construction: "
    'path->debug()
    'sleep
End Sub

Function Robot.getPath() as MyList.List ptr
    return path
End Function

Function Robot.getReflections() as integer
    return reflections
End Function

Function Robot.getEndTile() as Tile Ptr
    return endTile
End Function

Function Robot.getEndDirection() as Direction
    return beamEndDirection
End Function

Function Robot.getStartTile() as Tile Ptr
    return startTile
End Function

Function Robot.getStartDirection() as Direction
    return beamStartDirection
End Function    

ScreenRes 640,480,32

Type Board
    private:
        areaList as MyList.List
        _tileMap as TileMap ptr
        boardWidth as integer
        boardHeight as integer
        ' SET THE RIGHT NUMBER HERE!!
        tileSprites(30) as any Ptr
        spriteMap(6,6) as integer
        mirrorMap(6,6) as Mirror
        
        ' Sprites
        spriteSize as integer = 32
        
        ' Edges -- maybe not needed.
        'edges(4) as Tile Ptr Ptr
        
        ' Robots
        robots(24) as Robot ptr
        
        ' Internal helpers
        Declare Sub createTileMap()
        Declare Sub createAreas()
        Declare Sub drawBorder( img as any Ptr, length as integer, n as integer, e as integer, s as integer, w as integer )
        Declare Function loadSpriteFromFile( fileName as String ) as any ptr
        Declare Sub loadSprites()
        Declare Sub drawTile()
        Declare Sub drawBeam( __robot as Robot ptr, xOffset as integer, yOffset as integer )
        Declare Sub placeRandomMirrors()
        Declare Sub createSpriteMap()
    public:
        Declare Constructor( _boardWidth as integer, _boardHeight as integer )
        Declare Sub _draw( xOffset as integer, yOffset as integer )
End Type

Constructor Board( _boardWidth as integer, _boardHeight as integer )
	if _boardWidth <= 6 and _boardHeight <= 6 then
		boardWidth = _boardWidth
		boardHeight = _boardHeight
		createTileMap()
		createAreas()
		placeRandomMirrors()
		loadSprites()
        createSpriteMap()
        ' north edge
        for i as integer = 0 to (boardWidth - 1)
            robots(i) = new Robot( _tileMap->getTile(i,0), Direction.South)
            robots(i)->shootBeam()
            if robots(i)->getReflections() = 0 then
                delete robots(i)
                robots(i) = 0
            end if    
        next i
        ' east edge
        for i as integer = 0 to (boardHeight - 1)
            Dim index as integer = boardWidth + i
            robots(index) = new Robot( _tileMap->getTile((boardWidth - 1),i), Direction.West )
            robots(index)->shootBeam()
            if robots(index)->getReflections() = 0 then
                delete robots(index)
                robots(index) = 0
            end if 
        next i      
        ' south edge
        for i as integer = 0 to (boardWidth - 1)
            Dim index as integer = boardWidth + boardHeight + i
            robots(index) = new Robot( _tileMap->getTile(i,(boardHeight - 1)), Direction.North )
            robots(index)->shootBeam()            
            if robots(index)->getReflections() = 0 then
                delete robots(index)
                robots(index) = 0
            end if 
        next i   
        ' west edge
        for i as integer = 0 to (boardHeight - 1)
            Dim index as integer = (boardWidth * 2) + boardHeight + i
            robots(index) = new Robot( _tileMap->getTile(0,i), Direction.East )
            robots(index)->shootBeam()            
            if robots(index)->getReflections() = 0 then
                delete robots(index)
                robots(index) = 0
            end if 
        next i   
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

Function Board.loadSpriteFromFile( fileName as String ) as any ptr
    Dim _img as any ptr = imageCreate(32,32)
    Dim returnValue as integer = bload(fileName,_img)
    if returnValue <> 0 then
        print "Failed to load ";fileName; ", error nr.";returnValue
        end
    else
        return _img
    end if
    return 0
End Function

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
    tileSprites(TileSprite.Mirror_NE_SW) = loadSpriteFromFile("pictures/mirror_orig.bmp")
    tileSprites(TileSprite.Mirror_NW_SE) = loadSpriteFromFile("pictures/mirror_flipped.bmp")
    tileSprites(TileSprite.Beam_NE) = loadSpriteFromFile("pictures/beam_ne.bmp")
    tileSprites(TileSprite.Beam_NS) = loadSpriteFromFile("pictures/beam_ns.bmp")
    tileSprites(TileSprite.Beam_NW) = loadSpriteFromFile("pictures/beam_nw.bmp")
    tileSprites(TileSprite.Beam_ES) = loadSpriteFromFile("pictures/beam_es.bmp")
    tileSprites(TileSprite.Beam_EW) = loadSpriteFromFile("pictures/beam_ew.bmp")
    tileSprites(TileSprite.Beam_SW) = loadSpriteFromFile("pictures/beam_sw.bmp")
    tileSprites(TileSprite.Tank_N) = loadSpriteFromFile("pictures/tank_n.bmp")
    tileSprites(TileSprite.Tank_E) = loadSpriteFromFile("pictures/tank_e.bmp")
    tileSprites(TileSprite.Tank_S) = loadSpriteFromFile("pictures/tank_s.bmp")
    tileSprites(TileSprite.Tank_W) = loadSpriteFromFile("pictures/tank_w.bmp")
    'Line mirror1,(spriteSize-4,4)-(4,spriteSize-4),7
    'Line mirror2,(4,4)-(spriteSize-4,spriteSize-4),7
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
						Dim size as integer = int(rnd * boardWidth) + 1
						areaList.addObject(new Area(nextArea,tp,size))
						nextArea += 1
					end if    
				end if    
			Next j
		Next i
	end if
End Sub

Sub Board.placeRandomMirrors()
    Dim thisNode as MyList.ListNode ptr = areaList.getFirst()
	While thisNode <> 0    
        Dim areaPtr as Area Ptr = thisNode->getObject()
		areaPtr->placeRandomMirror() 
        thisNode = thisNode->getNext()
	Wend
End Sub

Sub Board.drawTile()
End Sub

Sub Board.drawBeam( __robot as Robot ptr, xOffset as integer, yOffset as integer )
    if __robot <> 0 then
        ' draw the tanks
        Dim firstTile as Tile Ptr = __robot->getStartTile()
        Dim firstDirection as Direction = __robot->getStartDirection()        
        Dim robotX as integer = firstTile->getX() * 32 + xOffset
        Dim robotY as integer = firstTile->getY() * 32 + yOffset
        Dim sprite as TileSprite = TileSprite.Tank_N
        If firstDirection = Direction.North then             
            robotY += 32
        ElseIf firstDirection = Direction.East then
            sprite = TileSprite.Tank_E
            robotX -= 32
        ElseIf firstDirection = Direction.South then         
            sprite = TileSprite.Tank_S
            robotY -= 32
        ElseIf firstDirection = Direction.West then 
            sprite = TileSprite.Tank_W
            robotX += 32
        End if
        Put (robotX,robotY), tileSprites(sprite),trans
        
        Dim _path as MyList.List ptr = __robot->getPath()
        'print "** start drawing beams **"
        'print "size of this path: "; _path->getSize()
        'sleep
        '_path->debug()        
        Dim thisNode as MyList.ListNode Ptr = _path->getFirst()
        while thisNode <> 0
            Dim thisMove as Move ptr = thisNode->getObject()
            if thisMove <> 0 then
                if thisMove->_tile <> 0 then                                        
                    'Dim tileX = 
                    Dim spriteX as integer = (thisMove->_tile->getX() * 32) + xOffset
                    Dim spriteY as integer = (thisMove->_tile->getY() * 32) + yOffset                    
                    'print "Draw path for robot, tileSprite: "; thisMove->_tileSprite
                    'thisMove->_tile->debug()
                    'sleep
                    Put (spriteX, spriteY), tileSprites(thisMove->_tileSprite), trans                    
                    'locate 23,1
                    'print spriteX; ", "; spriteY
                    'sleep
                else
                    print "No tile in Move object."
                    end
                end if
            end if    
            thisNode = thisNode->getNext()
            'sleep
        wend
    end if    
End Sub    

Sub Board._draw( xOffset as integer, yOffset as integer )
    for i as integer = 0 to (boardHeight - 1)
		for j as integer = 0 to (boardWidth - 1)
			Dim spriteX as integer = (j * 32) + xOffset
			Dim spriteY as integer = (i * 32) + yOffset
			Put (spriteX, SpriteY), tileSprites(spriteMap(j,i)), pset
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
	
    for i as integer = 0 to ( boardWidth * 2 + boardHeight * 2 - 1)
        drawBeam(robots(i),xOffset,yOffset)    
    next i    
    
End Sub

'--------------
' Init board.
'--------------
Dim w as integer = 4
Dim h as integer = 4
Dim b as Board = Board(w,h)
Cls
Dim xoffset as integer = (640 - (32*w)) \ 2
Dim yoffset as integer = (480 - (32*h)) \ 2
b._draw(xoffset,yoffset)
Sleep

System
