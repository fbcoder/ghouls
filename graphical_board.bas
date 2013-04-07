' Graphical board.
#include once "ghouls.bas"

declare function changeColorOfPixel ( byval src as uinteger, byval dest as uinteger, byval param as any ptr ) as uinteger

function changeColorOfPixel ( byval src as uinteger, byval dest as uinteger, byval param as any ptr ) as uinteger
    if param <> 0 then
        dim replaceColor as uinteger = *cptr(uinteger ptr, param)
        if src = rgb(&h00,&h00,&hff) then
            return replaceColor
        elseif src = rgb(&hff,&h00,&hff) then
            return dest
        else
            return src
        end if
    else
        print "Error: replacementColor can't be null"
        sleep
        end
    end if
end function

enum MirrorSprite
    Mirror_NE_SW = 0
    Mirror_NW_SE
end enum

enum TankSprite
    N = 0
    E
    S
    W
end enum

enum RaySprite
    NE = 0
    NS
    NW
    ES
    EW
    SW
end enum    

dim shared tankColor(24) as uinteger
tankColor(00) = rgb(&hff,&h00,&h00)
tankColor(01) = rgb(&h00,&hff,&h00)
tankColor(02) = rgb(&h00,&h00,&hff)
tankColor(03) = rgb(&hff,&hff,&h00)
tankColor(04) = rgb(&h00,&hff,&hff)
tankColor(05) = rgb(&hff,&hff,&hff)
tankColor(06) = rgb(&hcc,&hff,&h00)
tankColor(07) = rgb(&hff,&h33,&h00)
tankColor(08) = rgb(&hff,&h00,&hcc)
tankColor(09) = rgb(&h00,&hff,&h33)
tankColor(10) = rgb(&h00,&hcc,&hff)
tankColor(11) = rgb(&h99,&h00,&h99)
tankColor(12) = rgb(&h00,&h99,&h99)
tankColor(13) = rgb(&h00,&h99,&h00)
tankColor(14) = rgb(&h99,&h99,&h00)
tankColor(15) = rgb(&hff,&hcc,&hff)
tankColor(16) = rgb(&hcc,&hcc,&hff)
tankColor(17) = rgb(&hcc,&hff,&hff)
tankColor(18) = rgb(&hcc,&hff,&hcc)
tankColor(19) = rgb(&h00,&h99,&h66)
tankColor(20) = rgb(&h99,&h66,&h00)
tankColor(21) = rgb(&h66,&h66,&h66)
tankColor(22) = rgb(&hff,&hff,&hff)
tankColor(23) = rgb(&hff,&hff,&hff)
tankColor(24) = rgb(&hff,&hff,&hff)

type GraphicalBoard
    private:
        'the board
        _board as Board Ptr
        _width as integer
        _height as integer
        
        'required data maps
        _tileMap as TileMap_.TileMap ptr
        _areaMap as Area_.Map ptr
        
        'more data from the board
        tankList as MyList.List Ptr
        
        'grapics related
        xOffset as integer
        yOffset as integer
        spriteSize as integer = 32
        
        'sprites
        backgroundSprite as any ptr
        originalTankSprites(4) as any ptr
        tankSprites(4,24) as any ptr
        originalBeamSprites(6) as any ptr
        beamSprites(6,24) as any ptr        
        mirrorSprites(2) as any ptr
        beamSpriteGenerator(4,4) as RaySprite
        
        declare function getTileFromMouseCoords ( mouseX as integer, mouseY as integer ) as TileMap_.Tile ptr
        declare sub manipulateMirror ( _tile as TileMap_.Tile ptr )
        declare function drawTankBeam ( _robot as Robot ptr ) as Bool
        declare sub initgraphics ()
        declare sub colorTanksAndBeams ()
        declare sub drawBorder( img as any Ptr, length as integer, n as integer, e as integer, s as integer, w as integer )
        declare function loadSpriteFromFile( fileName as String ) as any ptr
        declare sub loadSprites ()
        declare sub createBackGroundSprite ()
        declare function getSpriteX ( _tile as TileMap_.Tile Ptr ) as integer
        declare function getSpriteX ( _tileX as integer ) as integer
        declare function getSpriteY ( _tile as TileMap_.Tile Ptr ) as integer
        declare function getSpriteY ( _tileX as integer ) as integer
        declare sub drawBoardBase ()
        declare sub drawAllMirrors ()
        declare sub drawTank( _robot as Robot ptr )
        declare sub drawBeams ()
    public:
        declare constructor ( _xOffset as integer, _yOffset as integer, __board as Board ptr )
        declare destructor ()
        declare sub _draw ()
        declare sub handleMouseClick ( mouseX as integer, mouseY as integer )        
end type

constructor GraphicalBoard ( _xOffset as integer, _yOffset as integer, __board as Board ptr )
    xOffset = _xOffset
    yOffset = _yOffset
    _board = __board
    
    ' get required data from the board:
    _width = _board->getWidth()
    _height = _board->getHeight()
    _areaMap = _board->getAreaMap()
    if _areaMap = 0 then
        print "Error: No AreaMap!"
        sleep
        end
    end if    
    _tileMap = _board->getTileMap()
    if _tileMap = 0 then
        print "Error: No TileMap!"
        sleep
        end
    end if    
    tankList = _board->getRequiredTankList()
    if tankList = 0 then
        print "Error: No tanks!"
        sleep
        end
    end if    
    
    ' initialize graphics
    initGraphics()
end constructor

destructor GraphicalBoard ()
    ' Delete the images created with imagecreate()
    for i as integer = 0 to 3
        for j as integer = 0 to 23
            imagedestroy(tankSprites(i,j))
        next j
        imagedestroy(originalTankSprites(i))
    next i
    for i as integer = 0 to 5
        for j as integer = 0 to 23
            imagedestroy(beamSprites(i,j))
        next j
        imagedestroy(originalBeamSprites(i))
    next i
    for i as integer = 0 to 1
        imagedestroy(mirrorSprites(i))
    next i    
    imagedestroy(backGroundSprite)    
end destructor

sub GraphicalBoard.initGraphics ()
    loadSprites()
    createBackGroundSprite()
    colorTanksAndBeams()
    beamSpriteGenerator(Direction.North,Direction.North) = RaySprite.NS
    beamSpriteGenerator(Direction.North,Direction.East) = RaySprite.ES
    beamSpriteGenerator(Direction.North,Direction.South) = RaySprite.NS
    beamSpriteGenerator(Direction.North,Direction.West) = RaySprite.SW

    beamSpriteGenerator(Direction.East,Direction.North) = RaySprite.NW
    beamSpriteGenerator(Direction.East,Direction.East) = RaySprite.EW
    beamSpriteGenerator(Direction.East,Direction.South) = RaySprite.SW
    beamSpriteGenerator(Direction.East,Direction.West) = RaySprite.EW

    beamSpriteGenerator(Direction.South,Direction.North) = RaySprite.NS
    beamSpriteGenerator(Direction.South,Direction.East) = RaySprite.NE
    beamSpriteGenerator(Direction.South,Direction.South) = RaySprite.NS
    beamSpriteGenerator(Direction.South,Direction.West) = RaySprite.NW

    beamSpriteGenerator(Direction.West,Direction.North) = RaySprite.NE
    beamSpriteGenerator(Direction.West,Direction.East) = RaySprite.EW
    beamSpriteGenerator(Direction.West,Direction.South) = RaySprite.ES
    beamSpriteGenerator(Direction.West,Direction.West) = RaySprite.EW
end sub    

function GraphicalBoard.drawTankBeam ( _robot as Robot ptr ) as Bool
    Dim returnValue as Bool = Bool.False
    if _robot <> 0 then
        Dim currentTile as TileMap_.Tile ptr = _robot->getStartTile()
        Dim currentDirection as Direction = _robot->getStartDirection()
        Dim reflections as integer = 0        
        while currentTile <> 0
            Dim newDirection as Direction
            Dim newTile as TileMap_.Tile Ptr
            Dim thisMirror as Mirror = _areaMap->getPlayerMirror(currentTile)
            newDirection = directionMutations(thisMirror,currentDirection)            
            put (getSpriteX(currentTile),getSpriteY(currentTile)),beamSprites(beamSpriteGenerator(currentDirection,newDirection), _robot->getId() - 1),trans
            newTile = currentTile->getNeighbor(newDirection)
            if newDirection <> currentDirection then
                reflections += 1
            end if    
            if newTile = 0 then
                if newDirection = _robot->getEndDirection() then
                    if reflections = _robot->getReflections() then                        
                        returnValue = Bool.True
                    end if    
                end if    
            end if        
            currentTile = newTile
            currentDirection = newDirection
        wend
    end if
    return returnValue
end function

sub GraphicalBoard._draw ()    
    cls
    'print "start drawing:"
    sleep
    drawBoardBase()
    drawAllMirrors()
    Dim tankIterator as MyList.Iterator ptr = new MyList.Iterator(tankList)
    while tankIterator->hasNextObject() = Bool.True
        Dim thisTank as Robot ptr = tankIterator->getNextObject()
        if thisTank <> 0 then
            drawTank(thisTank)
            Dim returnValue as Bool = drawTankBeam(thisTank)
        else
            print "Error: TankObject can't be null!"
            sleep
            end
        end if
    wend    
    delete tankIterator
    print "Click on tiles to place / change mirrors."
end sub

sub GraphicalBoard.drawBeams()
    drawBoardBase()
    drawAllMirrors()
    Dim completedRoutes as integer = 0
    Dim tankIterator as MyList.Iterator ptr = new MyList.Iterator(tankList)
    while tankIterator->hasNextObject() = Bool.True
        Dim thisTank as Robot ptr = tankIterator->getNextObject()
        if thisTank <> 0 then            
            Dim returnValue as Bool = drawTankBeam(thisTank)
            if returnValue = Bool.True then
                completedRoutes += 1
            end if    
        else
            print "Error: TankObject can't be null!"
            sleep
            end
        end if
    wend
    if completedRoutes = tankList->getSize() then
        print "completed!"
    end if    
    delete tankIterator
end sub    

Sub GraphicalBoard.drawBorder( img as any Ptr, length as integer, n as integer, e as integer, s as integer, w as integer )
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

Function GraphicalBoard.loadSpriteFromFile( fileName as String ) as any ptr
    Dim _img as any ptr = imageCreate(32,32)
    Dim returnValue as integer = bload(fileName,_img)
    if returnValue <> 0 then
        print "Failed to load ";fileName; ", error nr. ";returnValue
        sleep
        end
    else
        return _img
    end if
    return 0
End Function

Sub GraphicalBoard.loadSprites()
    ' Load sprites for mirrors
    mirrorSprites(MirrorSprite.Mirror_NE_SW) = loadSpriteFromFile("pictures/mirror_orig.bmp")
    mirrorSprites(MirrorSprite.Mirror_NW_SE) = loadSpriteFromFile("pictures/mirror_flipped.bmp")
    
    ' Load sprites for the beams
    originalBeamSprites(RaySprite.NE) = loadSpriteFromFile("pictures/beam_ne.bmp")
    originalBeamSprites(RaySprite.NS) = loadSpriteFromFile("pictures/beam_ns.bmp")
    originalBeamSprites(RaySprite.NW) = loadSpriteFromFile("pictures/beam_nw.bmp")
    originalBeamSprites(RaySprite.ES) = loadSpriteFromFile("pictures/beam_es.bmp")
    originalBeamSprites(RaySprite.EW) = loadSpriteFromFile("pictures/beam_ew.bmp")
    originalBeamSprites(RaySprite.SW) = loadSpriteFromFile("pictures/beam_sw.bmp")
    
    ' Load sprites for the tanks
    originalTankSprites(TankSprite.N) = loadSpriteFromFile("pictures/tank_n.bmp")
    originalTankSprites(TankSprite.E) = loadSpriteFromFile("pictures/tank_e.bmp")
    originalTankSprites(TankSprite.S) = loadSpriteFromFile("pictures/tank_s.bmp")
    originalTankSprites(TankSprite.W) = loadSpriteFromFile("pictures/tank_w.bmp")
End Sub

sub GraphicalBoard.colorTanksAndBeams()
    print "tank and beam colors: "
    for i as integer = 0 to 24
        for j as integer = 0 to 3
            Dim tempImage as any ptr = imageCreate(spriteSize,spriteSize)
            if originalTankSprites(j) = 0 then
                print "Error: originalTankSprite can't be null!"
                sleep
                end
            end if    
            put tempImage,(0,0),originalTankSprites(j),pset
            tankSprites(j,i) = imageCreate(spriteSize,spriteSize)            
            put tankSprites(j,i),(0,0),tempImage, custom, @changeColorOfPixel,@tankColor(i)
            imagedestroy(tempImage)
        next j
        for j as integer = 0 to 5
            Dim tempImage as any ptr = imageCreate(spriteSize,spriteSize)
            if originalBeamSprites(j) = 0 then
                print "Error: originalBeamSprite can't be null!"
                sleep
                end
            end if    
            put tempImage,(0,0),originalBeamSprites(j),pset            
            beamSprites(j,i) = imageCreate(spriteSize,spriteSize)            
            put beamSprites(j,i),(0,0),tempImage, custom, @changeColorOfPixel,@tankColor(i)
            imagedestroy(tempImage)
        next j    
    next i    
    print "done."
end sub    

Sub GraphicalBoard.createBackGroundSprite()    
    print "creating backGroundSprite:"
    backGroundSprite = imageCreate(_width * spriteSize,_height * spriteSize)
    dim floorColor as uinteger = rgb(0,128,128)
    for i as integer = 0 to (_height - 1)
        for j as integer = 0 to (_width - 1)
            dim n as integer = 0
            dim e as integer = 0
            dim s as integer = 0
            dim w as integer = 0
            dim t as TileMap_.Tile Ptr = _tileMap->getTile(j,i)
            if t <> 0 then
                if _areaMap->getArea(t->getNeighbor(Direction.North)) <> _areaMap->getArea(t) then n = 1
                if _areaMap->getArea(t->getNeighbor(Direction.East)) <> _areaMap->getArea(t) then e = 1
                if _areaMap->getArea(t->getNeighbor(Direction.South)) <> _areaMap->getArea(t) then s = 1
                if _areaMap->getArea(t->getNeighbor(Direction.West)) <> _areaMap->getArea(t) then w = 1            
            end if
            dim thisImg as any ptr = imagecreate(spriteSize,spriteSize)
            line thisImg,(0,0)-(spriteSize-1,spriteSize-1),floorColor,BF
            drawBorder(thisImg,spriteSize,n,e,s,w)
            put backGroundSprite, (j * spriteSize, i * spriteSize), thisImg, pset
        next j
    next i    
    print "done."
End Sub

Function GraphicalBoard.getSpriteX(_tile as TileMap_.Tile Ptr) as integer
	if _tile <> 0 then
		return (_tile->getCoord()->x * spriteSize + xOffset)
	end if
	return -1
End Function

Function GraphicalBoard.getSpriteX(_tileX as integer) as integer
	return (_tileX * spriteSize + xOffset)
End Function

Function GraphicalBoard.getSpriteY(_tile as TileMap_.Tile Ptr) as integer
	if _tile <> 0 then
		return (_tile->getCoord()->y * spriteSize + yOffset)
	end if
	return -1
End Function

Function GraphicalBoard.getSPriteY(_tileY as integer) as integer
	return (_tileY * spriteSize + yOffset)
End Function

Sub GraphicalBoard.drawBoardBase()
    'print "draw base: "
    Put (xOffset,yOffset), backGroundSprite, pset
    'print "done."
End Sub

Sub GraphicalBoard.drawAllMirrors()
	'print "draw mirrors: "
    for i as integer = 0 to (_height - 1)
		for j as integer = 0 to (_width - 1)
            Dim t as TileMap_.Tile Ptr = _tileMap->getTile(j,i)
            if t <> 0 then
                if _areaMap->getPlayerMirror(t) <> Mirror.None then
                    if _areaMap->getPlayerMirror(t) = Mirror.NE_SW then
                        Put (getSpriteX(j), getSpriteY(i)), mirrorSprites(MirrorSprite.Mirror_NE_SW), trans
                    end if
                    if _areaMap->getPlayerMirror(t) = Mirror.NW_SE then
                        Put (getSpriteX(j), getSpriteY(i)), mirrorSprites(MirrorSprite.Mirror_NW_SE), trans
                    end if
                end if
            end if
		next j
	next i
    'print "done."
End Sub

sub GraphicalBoard.drawTank( _robot as Robot ptr )
	if _robot <> 0 then
		' draw the tank
		dim firstDirection as Direction = _robot->getStartDirection()
		dim robotX as integer = _robot->getStartX() * spriteSize + xOffset
		dim robotY as integer = _robot->getStartY() * spriteSize + yOffset
		dim sprite as TankSprite = TankSprite.N
		if firstDirection = Direction.East then
			sprite = TankSprite.E
		elseif firstDirection = Direction.South then
			sprite = TankSprite.S
		elseif firstDirection = Direction.West then
			sprite = TankSprite.W
		end if
		put (robotX,robotY), tankSprites(sprite,_robot->getId() - 1),trans
		' draw the number of reflections at endtile
		dim endX as integer = _robot->getEndX() * spriteSize + xOffset
		dim endY as integer = _robot->getEndY() * spriteSize + yOffset
		draw String (endX+10,endY+10), str(_robot->getReflections()), tankColor(_robot->getId() - 1)
	end if
end Sub

'------------------------------
' Methods for input control
'------------------------------
function GraphicalBoard.getTileFromMouseCoords ( mouseX as integer, mouseY as integer ) as TileMap_.Tile ptr
    if mouseX >= xOffset then
        if mouseY >= yOffset then
            if mouseX <= xOffset + (_width * spriteSize) then
                if mouseY <= yOffset + (_height * spriteSize) then
                    return _tileMap->getTile((mouseX - xOffset) \ spriteSize,(mouseY - yOffset) \ spriteSize)
                end if
            end if
        end if
    end if
    return 0
end function

sub GraphicalBoard.handleMouseClick ( mouseX as integer, mouseY as integer )
    dim clickedTile as TileMap_.Tile ptr = getTileFromMouseCoords(mouseX,mouseY)
    if clickedTile <> 0 then
        dim playerMirror as Mirror = _areaMap->getPlayerMirror(clickedTile)
        if playerMirror = Mirror.None then
            playerMirror = Mirror.NE_SW
        elseif playerMirror = Mirror.NE_SW then
            playerMirror = Mirror.NW_SE
        else
            playerMirror = Mirror.None
        end if    
        _areaMap->playerPlacesMirror(clickedTile,playerMirror)
        drawBeams()
    end if
end sub

'---------------------------------------------
' Init Graphics mode and the graphical board
'---------------------------------------------
declare sub mainLoop ( gb as GraphicalBoard ptr )

screenres 640,480,32

dim w as integer = 6
dim h as integer = 4
cls
dim xoffset as integer = (640 - (32*w)) \ 2
dim yoffset as integer = (480 - (32*h)) \ 2
dim b as Board Ptr = new Board(w,h)
dim solvable as Bool = b->solve()
if solvable = Bool.True then
    dim gb as GraphicalBoard ptr = new GraphicalBoard(xoffset,yoffset,b)
    gb->_draw()
    mainLoop (gb)
    delete gb
end if
delete b

'----------
' mainLoop
'----------
sub mainLoop ( gb as GraphicalBoard ptr )
    if gb <> 0 then
        Dim k as string = ""
        Dim mouseClicked as Bool = Bool.False
        while k <> chr(27)
            k = inkey
            Dim mouseX as integer
            Dim mouseY as integer
            Dim mouseButton as integer
            getMouse mouseX, mouseY,,mouseButton
            if mouseButton and &b001 then
                if mouseClicked = Bool.False then                
                    mouseClicked = Bool.True
                end if                        
            else
                if mouseClicked = Bool.True then
                    'print "click"
                    gb->handleMouseClick(mouseX,mouseY)
                    mouseClicked = Bool.False
                end if
            end if            
            sleep 1,1
        wend    
    end if    
end sub

System
