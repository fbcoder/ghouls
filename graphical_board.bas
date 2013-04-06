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
        print "replacementcolor can't be null"
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
tankColor(0) = rgb(&hff,&h00,&h00)
tankColor(1) = rgb(&h00,&hff,&h00)
tankColor(2) = rgb(&h00,&h00,&hff)
tankColor(3) = rgb(&hff,&hff,&h00)
tankColor(4) = rgb(&h00,&hff,&hff)
tankColor(5) = rgb(&hff,&hff,&hff)
tankColor(6) = rgb(&hff,&hff,&hff)
tankColor(7) = rgb(&hff,&hff,&hff)
tankColor(8) = rgb(&hff,&hff,&hff)
tankColor(9) = rgb(&hff,&hff,&hff)
tankColor(10) = rgb(&hff,&hff,&hff)
tankColor(11) = rgb(&hff,&hff,&hff)
tankColor(12) = rgb(&hff,&hff,&hff)
tankColor(13) = rgb(&hff,&hff,&hff)
tankColor(14) = rgb(&hff,&hff,&hff)
tankColor(15) = rgb(&hff,&hff,&hff)
tankColor(16) = rgb(&hff,&hff,&hff)
tankColor(17) = rgb(&hff,&hff,&hff)
tankColor(18) = rgb(&hff,&hff,&hff)
tankColor(19) = rgb(&hff,&hff,&hff)
tankColor(20) = rgb(&hff,&hff,&hff)
tankColor(21) = rgb(&hff,&hff,&hff)
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
        
        backgroundSprite as any ptr
        originalTankSprites(4) as any ptr
        tankSprites(4,24) as any ptr
        originalBeamSprites(6) as any ptr
        beamSprites(6,24) as any ptr
        mirrorSprites(2) as any ptr
        
        declare function getTileFromMouseCoords () as TileMap_.Tile ptr
        declare sub manipulateMirror ( _tile as TileMap_.Tile ptr )
        declare sub drawTankBeam ( _robot as Robot ptr )
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
    public:
        declare constructor ( _xOffset as integer, _yOffset as integer, __board as Board ptr )
        declare destructor ()
        declare sub _draw ()
        declare sub handleMouse ()        
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
    tankList = _board->getTankList()
    if tankList = 0 then
        print "Error: No tanks!"
        sleep
        end
    end if    
    
    ' initialize graphics
    initGraphics()
end constructor

destructor GraphicalBoard ()
end destructor

sub GraphicalBoard.initGraphics ()
    loadSprites()
    createBackGroundSprite()
    colorTanksAndBeams()
end sub    

'sub GraphicalBoard.drawTankBeam ( _robot as Robot ptr )
'    if _robot <> 0 then
'        Dim currentTile as TileMap_.Tile ptr = _robot->getStartTile()
'        Dim currentDirection as Direction = _robot->getStartDirection()
'        while currentTile <> 0
'            
'        wend    
'    end if   
'end sub 

sub GraphicalBoard._draw ()    
    cls
    print "start drawing:"
    sleep
    drawBoardBase()
    drawAllMirrors()
    Dim tankIterator as MyList.Iterator ptr = new MyList.Iterator(tankList)
    while tankIterator->hasNextObject() = Bool.True
        Dim thisTank as Robot ptr = tankIterator->getNextObject()
        if thisTank <> 0 then
            drawTank(thisTank)
        else
            print "Error: TankObject can't be null!"
            sleep
            end
        end if
    wend    
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
    Dim floorColor as uinteger = rgb(0,128,128)
    for i as integer = 0 to (_height - 1)
        for j as integer = 0 to (_width - 1)
            Dim n as integer = 0
            Dim e as integer = 0
            Dim s as integer = 0
            Dim w as integer = 0
            Dim t as TileMap_.Tile Ptr = _tileMap->getTile(j,i)
            if t <> 0 then
                if _areaMap->getArea(t->getNeighbor(Direction.North)) <> _areaMap->getArea(t) then n = 1
                if _areaMap->getArea(t->getNeighbor(Direction.East)) <> _areaMap->getArea(t) then e = 1
                if _areaMap->getArea(t->getNeighbor(Direction.South)) <> _areaMap->getArea(t) then s = 1
                if _areaMap->getArea(t->getNeighbor(Direction.West)) <> _areaMap->getArea(t) then w = 1            
            end if
            Dim thisImg as any ptr = imagecreate(spriteSize,spriteSize)
            Line thisImg,(0,0)-(spriteSize-1,spriteSize-1),floorColor,BF
            drawBorder(thisImg,spriteSize,n,e,s,w)
            put backGroundSprite, (j * spriteSize, i * spriteSize), thisImg, pset
        next j
    next i    
    print "done."
End Sub

Function GraphicalBoard.getSpriteX(_tile as TileMap_.Tile Ptr) as integer
	if _tile <> 0 then
		return (_tile->getCoord()->x * 32 + xOffset)
	end if
	return -1
End Function

Function GraphicalBoard.getSpriteX(_tileX as integer) as integer
	return (_tileX * 32 + xOffset)
End Function

Function GraphicalBoard.getSpriteY(_tile as TileMap_.Tile Ptr) as integer
	if _tile <> 0 then
		return (_tile->getCoord()->y * 32 + yOffset)
	end if
	return -1
End Function

Function GraphicalBoard.getSPriteY(_tileY as integer) as integer
	return (_tileY * 32 + yOffset)
End Function

Sub GraphicalBoard.drawBoardBase()
    print "draw base: "
    Put (xOffset,yOffset), backGroundSprite, pset
    print "done."
End Sub

Sub GraphicalBoard.drawAllMirrors()
	print "draw mirrors: "
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
    print "done."
End Sub

Sub GraphicalBoard.drawTank( _robot as Robot ptr )
	if _robot <> 0 then
		' draw the tank
		Dim firstDirection as Direction = _robot->getStartDirection()
		Dim robotX as integer = _robot->getStartX() * 32 + xOffset
		Dim robotY as integer = _robot->getStartY() * 32 + yOffset
		Dim sprite as TankSprite = TankSprite.N
		IF firstDirection = Direction.East then
			sprite = TankSprite.E
		ElseIf firstDirection = Direction.South then
			sprite = TankSprite.S
		ElseIf firstDirection = Direction.West then
			sprite = TankSprite.W
		End if
		Put (robotX,robotY), tankSprites(sprite,_robot->getId() - 1),trans
		' draw the number of reflections at endtile
		Dim endX as integer = _robot->getEndX() * 32 + xOffset
		Dim endY as integer = _robot->getEndY() * 32 + yOffset
		Draw String (endX+10,endY+10), str(_robot->getReflections()), tankColor(_robot->getId() - 1)
	end if
End Sub

'---------------------------------------------
' Init Graphics mode and the graphical board
'---------------------------------------------
ScreenRes 640,480,32

Dim w as integer = 4
Dim h as integer = 4
Cls
Dim xoffset as integer = (640 - (32*w)) \ 2
Dim yoffset as integer = (480 - (32*h)) \ 2
Dim b as Board Ptr = new Board(w,h)
Dim solvable as Bool = b->solve()
if solvable = Bool.True then
    Dim gb as GraphicalBoard ptr = new GraphicalBoard(xoffset,yoffset,b)
    gb->_draw()
    delete gb
    sleep
end if
delete b

System
