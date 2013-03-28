#include once "includes/list.bas"
#include once "includes/bool.bas"
#include once "includes/direction.bas"
#include once "tilemap.bas"

' New line for Windows
Const NEWLINE = !"\r\n"
'New line for Linux
'Const NEWLINE = !"\n"

Randomize Timer

Enum Mirror
    Undefined = -1
    None = 0
    NE_SW = 1
    NW_SE = 2
End Enum

Enum TileSprite
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
mirrorText(0) = " * "
mirrorText(1) = " / "
mirrorText(2) = " \ "

' Type forwarding for Board
Type BoardPtr as Board Ptr

'------
' Area
'------
Type Area
    private:
        _board as BoardPtr 
        id as integer = 0
        tileList as MyList.list
        size as integer = 0
        maxSize as integer = 0
        hasMirror as Bool = Bool.False
        originalMirrorType as Mirror
        originalMirrorTile as TileMap_.Tile Ptr
        Declare Function getRandomDirection() as Direction
        Declare Sub addTiles( _tile as TileMap_.Tile Ptr, fromTile as TileMap_.Tile Ptr, s as Integer )
    public:
        Declare Constructor ( _id as integer, startTile as TileMap_.Tile Ptr, maxSize as integer, __board as BoardPtr )
        Declare Sub placeRandomMirror()
        Declare Sub debug()
        Declare Sub debugList()
        Declare Function getSize() as integer
End Type

Constructor Area ( _id as integer, startTile as TileMap_.Tile Ptr, _maxSize as integer, __board as BoardPtr )
    id = _id
    _board = __board
    maxSize = _maxSize
    addTiles(startTile,0,1)
End Constructor

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

Function area.getSize() as integer
    return size
End Function

Sub Area.debug()
    print "-- Area --"
    print "id "; id
    print "# of tiles "; tileList.getSize()
    Dim thisNode as MyList.ListNode Ptr = tileList.getFirst()
    while thisNode <> 0
        Dim tp as TileMap_.Tile ptr = thisNode->getObject()
        if tp <> 0 then
            tp->debug()
        end if
        thisNode = thisNode->getNext()
    wend
End Sub

Sub Area.debugList()
    print "** TILE LIST **"
    tileList.debug()
End Sub

'---------------------
' Path Tree and Leafs
'---------------------
Type RouteStep
    _tile as TileMap_.Tile Ptr
    _mirror as Mirror
End Type

Type FailedRoute
    public:
        failureMsg as String
        routeList as MyList.List ptr
        Declare Constructor ( _failureMsg as String, _routeList as MyList.List Ptr )
End Type

Constructor FailedRoute ( _failureMsg as String, _routeList as MyList.List Ptr )
    failureMsg = _failureMsg
    routeList = _routeList
End Constructor

Type PathLeaf
    private:
        _tile as TileMap_.Tile Ptr
        parentOrientation as Mirror
        parent as PathLeaf ptr
        comingFrom as Direction
        children(3) as PathLeaf ptr
    public:
        Declare Constructor( __tile as TileMap_.Tile Ptr, _parentOrientation as Mirror = Mirror.None, _parent as PathLeaf ptr, _direction as Direction )
        Declare Sub addChildLeaf( childTile as TileMap_.Tile Ptr, _orientation as Mirror, _direction as Direction )
        Declare Function getChild( orientation as Mirror ) as PathLeaf Ptr
        Declare Function getParent() as PathLeaf Ptr
        Declare Function hasChildren() as Bool
        Declare Function getTile() as TileMap_.Tile Ptr
        Declare Function getParentOrientation() as Mirror
        Declare Function getIncoming() as Direction
End Type

Constructor PathLeaf( __tile as TileMap_.Tile Ptr, _parentOrientation as Mirror = Mirror.None, _parent as PathLeaf ptr, _direction as Direction )    
    _tile = __tile
    parent = _parent
    parentOrientation = _parentOrientation
    comingFrom = _direction
    for i as integer = Mirror.None to Mirror.NW_SE
        children(i) = 0
    next i        
End Constructor

Sub PathLeaf.addChildLeaf( childTile as TileMap_.Tile Ptr, _orientation as Mirror, _direction as Direction )
    if _tile <> 0 then
        children(_orientation) = new PathLeaf(childTile,_orientation,@this,_direction)
    else
        print "Error: Can't add a ChildNode to a Node with a Null Tile!"
        sleep
        end
    end if
End Sub

Function PathLeaf.getChild( orientation as Mirror ) as PathLeaf Ptr
    return children( orientation )
End Function

Function PathLeaf.getParent() as PathLeaf Ptr
    return parent
End Function    

Function PathLeaf.getParentOrientation() as Mirror
    return parentOrientation
End Function

Function PathLeaf.getIncoming() as Direction
    return comingFrom
End Function

Function PathLeaf.hasChildren() as Bool
    for i as integer = Mirror.None to Mirror.NW_SE
        if children(i) <> 0 then return Bool.True
    next i    
    return Bool.False
End Function    

Function PathLeaf.getTile() as TileMap_.Tile Ptr
    return _tile
End Function

' Tree
Type PathTree
    private:
        ' first Leaf in the tree
        root as PathLeaf ptr = 0
        routeList as MyList.List ptr = 0
        failList as MyList.List ptr = 0
        debugFailedRoutes as Bool = Bool.True
        Declare Function getRouteList ( leaf as PathLeaf Ptr ) as MyList.List Ptr
        Declare Function printRoute ( listNode as MyList.ListNode Ptr ) as String
        Declare Function printRoute ( _list as MyList.List Ptr ) as String
    public:
        Declare Constructor( _tile as TileMap_.Tile Ptr, _direction as Direction )
        Declare Function getRoot( ) as PathLeaf ptr
        Declare Sub addSuccessRoute ( leaf as PathLeaf Ptr )
        Declare Function getRouteString () as String
        Declare Sub addFailedRoute ( leaf as PathLeaf Ptr, _mirror as Mirror = Mirror.Undefined, failMsg as String )
        Declare Sub printRoutesToFile ( fileName as String )
End Type    

Constructor PathTree( _tile as TileMap_.Tile Ptr, _direction as Direction )
    if _tile <> 0 then
        root = new PathLeaf(_tile,Mirror.None,0,_direction)
    end if
End Constructor

Function PathTree.getRoot() as PathLeaf Ptr
    return root
End Function    

Function PathTree.getRouteList(leaf as PathLeaf Ptr) as MyList.List Ptr
    Dim thisRoute as MyList.List Ptr = new MyList.List()
    Dim thisLeaf as PathLeaf Ptr = leaf
    While thisLeaf->getParent() <> 0      
        thisRoute->addObject(new RouteStep(thisLeaf->getParent()->getTile(),thisLeaf->getParentOrientation()))
        thisLeaf = thisLeaf->getParent()
    Wend
    return thisRoute
End Function

Sub PathTree.addSuccessRoute (leaf as PathLeaf Ptr)    
    if routeList = 0 then
        routeList = new MyList.List()
    end if
    Dim thisRoute as MyList.List Ptr = getRouteList(leaf)
    routeList->addObject(thisRoute)
End Sub    

Function PathTree.printRoute ( _list as MyList.List Ptr ) as String
    Dim returnString as String = ""
    Dim thisIterator as MyList.Iterator Ptr = new MyList.Iterator(_list)
    while thisIterator->hasNextObject() = Bool.True
        Dim _routeStep as RouteStep ptr = thisIterator->getNextObject()
        if _routeStep <> 0 then            
            returnString &= _routeStep->_tile->getCoordString() & "--"
            returnString &= mirrorText(_routeStep->_mirror) & "-->"            
        end if
    wend
    delete thisIterator
    return returnString
End Function    

Function PathTree.printRoute ( listNode as MyList.ListNode Ptr ) as String
    Dim returnString as String = ""    
    while listNode <> 0
        Dim _routeStep as RouteStep ptr = listNode->getObject()
        if _routeStep <> 0 then            
            returnString &= _routeStep->_tile->getCoordString() & "--"
            returnString &= "[" & mirrorText(_routeStep->_mirror) & "]-->"
            'returnString &= "----" & NEWLINE            
        end if
        listNode = listNode->getNext()
    wend 
    return returnString
End Function

Function PathTree.getRouteString () as String    
    Dim routes as integer = 0
    Dim returnString as String = ""    
    if routeList <> 0 then
        returnString &= "Found " & str(routeList->getSize()) & " succesful route(s)." & NEWLINE
        Dim thisRoute as MyList.ListNode ptr = routeList->getFirst()
        while thisRoute <> 0
            Dim _route as MyList.List ptr = thisRoute->getObject()
            if _route <> 0 then
                routes += 1
                returnString &= "****" & NEWLINE              
                returnString &= "Route " & str(routes) & NEWLINE
                returnString &= "****" & NEWLINE
                returnString &= printRoute(_route) & "E" & NEWLINE
            end if
            thisRoute = thisRoute->getNext()
        wend
        returnString &= !"\r\n"
    else
        returnString &= "No Routes!" 
    end if
    if debugFailedRoutes = Bool.True then
        if failList <> 0 then
            returnString &= "Found " & str(failList->getSize()) & " invalid paths." & NEWLINE
            Dim failedRouteNode as MyList.ListNode Ptr = failList->getFirst()                        
            while failedRouteNode <> 0
                Dim thisFailedRoute as FailedRoute ptr = failedRouteNode->getObject()
                if thisFailedRoute <> 0 then
                    returnString &= printRoute(thisFailedRoute->routeList) & "X" & NEWLINE
                    returnString &= thisFailedRoute->failureMsg & NEWLINE
                end if    
                failedRouteNode = failedRouteNode->getNext()
            wend    
            
        else
            returnString &= "No failed Routes" & NEWLINE
        end if    
    end if    
    return returnString
End Function

Sub PathTree.addFailedRoute ( leaf as PathLeaf Ptr, _mirror as Mirror = Mirror.Undefined, failMsg as String = "" )
    if debugFailedRoutes = Bool.True then
        if failList = 0 then
            failList = new MyList.List()
        end if
        if _mirror <> Mirror.Undefined then
            failMsg = "Failed to add " & mirrorText(_mirror) & ". (" & failMsg & ")"
        else
            failMsg = "Could not reach endTile (" & failMsg & ")"
        end if    
        Dim routeList as myList.List Ptr = getRouteList(leaf)
        failList->addObject(new FailedRoute(failMsg,routeList))
    end if    
End Sub

' Append the routes to the board file.
Sub PathTree.printRoutesToFile ( fileName as String )
    if fileName <> "" then
        open fileName for append as #1
        print #1, getRouteString
        close #1
    else    
        print "Cannot create file with empty name."
        sleep
        end
    end if    
End Sub    
'---------------------------------
' Move object used by Robot/Tank
'---------------------------------
Type Move
    _tile as TileMap_.Tile Ptr
    _tileSprite as TileSprite
    Declare Constructor( __tile as TileMap_.Tile Ptr, __tileSprite as TileSprite )
End Type

Constructor Move( __tile as TileMap_.Tile Ptr, __tileSprite as TileSprite )
    _tile = __tile
    _tileSprite = __tileSprite
End Constructor

'------------
' Robot/Tank
'------------
Type Robot
    private:
        _board as BoardPtr
        _pathTree as PathTree Ptr
        id as integer
        startX as integer
        startY as integer
        endX as integer
        endY as integer
        tempMirrorMap(TileMap_.DEFAULT_MAPWIDTH,TileMap_.DEFAULT_MAPHEIGHT) as Mirror
        beamStartDirection as Direction
        beamEndDirection as Direction
        startTile as TileMap_.Tile Ptr = 0
        endTile as TileMap_.Tile Ptr = 0
        reflections as Integer = 0
        path as MyList.List ptr = 0
        beamSpriteGenerator(4,4) as TileSprite
        directionMutations(3,4) as Direction 
        Declare Sub addToPath( _tile as TileMap_.Tile Ptr, currentDir as Direction, prevDir as Direction )
        Declare Function getRouteDescription() as String
    public:
        Declare Constructor( _id as integer, _startTile as TileMap_.Tile Ptr, startDir as Direction, __board as BoardPtr )
        Declare Destructor()
        Declare Sub shootBeam()
        Declare Function getPath() as MyList.List ptr
        Declare Function getReflections() as Integer
        Declare Function getEndTile() as TileMap_.Tile Ptr
        Declare Function getEndDirection() as Direction
        Declare Function getStartTile() as TileMap_.Tile Ptr
        Declare Function getStartDirection() as Direction
        Declare Function getEndX() as Integer
        Declare Function getEndY() as Integer
        Declare Function getStartX() as Integer
        Declare Function getStartY() as Integer
        
        ' Methods for pathfinding        
        Declare Sub findAlternativePaths ()        
        Declare Function getMirrorString ( oldDir as Direction, newDir as Direction, orientation as Mirror ) as String
        Declare Sub findNextMirror( node as PathLeaf ptr, bounces as integer )
        Declare Function areaHasMirror ( node as PathLeaf ptr ) as Bool
        Declare Sub checkChild_Mirror ( _mirror as Mirror, node as PathLeaf ptr, bounces as integer )
        Declare Sub checkChild_NoMirror( node as PathLeaf ptr, bounces as integer )
End Type

Constructor Robot( _id as integer, _startTile as TileMap_.Tile Ptr, startDir as Direction, __board as BoardPtr )
    if _startTile <> 0 then
        if _id > 0 then
            id = _id
        else
            print "Error: Zero is no valid ID for tank."
            sleep
            end
        end if
        _board = __board
        path = new MyList.List()
        startTile = _startTile
        beamStartDirection = startDir
        Select Case beamStartDirection
			case Direction.North:
				startX = startTile->getCoord()->x
				startY = startTile->getCoord()->y + 1
			case Direction.East:
				startX = startTile->getCoord()->x - 1
				startY = startTile->getCoord()->y
			case Direction.South:
				startX = startTile->getCoord()->x
				startY = startTile->getCoord()->y - 1
			case Direction.West:
				startX = startTile->getCoord()->x + 1
				startY = startTile->getCoord()->y
        End Select
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
    
    ' Get new directions when bouncing on a mirror
    directionMutations(Mirror.None, Direction.North) = Direction.North
    directionMutations(Mirror.None, Direction.East) = Direction.East
    directionMutations(Mirror.None, Direction.South) = Direction.South
    directionMutations(Mirror.None, Direction.West) = Direction.West
    
    directionMutations(Mirror.NE_SW, Direction.North) = Direction.East
    directionMutations(Mirror.NE_SW, Direction.East) = Direction.North
    directionMutations(Mirror.NE_SW, Direction.South) = Direction.West
    directionMutations(Mirror.NE_SW, Direction.West) = Direction.South
    
    directionMutations(Mirror.NW_SE, Direction.North) = Direction.West
    directionMutations(Mirror.NW_SE, Direction.East) = Direction.South
    directionMutations(Mirror.NW_SE, Direction.South) = Direction.East
    directionMutations(Mirror.NW_SE, Direction.West) = Direction.North
    
End Constructor

Destructor Robot()
    if path <> 0 then       
        Dim iteratedNode as MyList.ListNode ptr = path->getFirst()
        While iteratedNode <> 0
            Dim as MyList.ListNode ptr nextNode = iteratedNode->getNext()
            Dim as Move ptr thisMove = iteratedNode->getObject()
            delete thisMove
            iteratedNode = NextNode
        Wend
        delete path
    end if    
End Destructor

Function Robot.getMirrorString( oldDir as Direction, newDir as Direction, orientation as Mirror ) as String 
    Dim mirrorChar as String
    if orientation = Mirror.NE_SW then mirrorChar = "/"
    if orientation = Mirror.NW_SE then mirrorChar = "\"
    'return _tile->getCoordString() & mirrorChar   
    return mirrorChar & "-->[" & directionNames(oldDir) & "->" & directionNames(newDir) & "]-->"
End Function

Sub Robot.checkChild_Mirror( _mirror as Mirror, node as PathLeaf ptr, bounces as integer )
    if bounces < reflections then
        if areaHasMirror(node) = Bool.False then            
            Dim newDirection as Direction = directionMutations(_mirror,node->getIncoming())
            Dim nextTile as TileMap_.Tile Ptr = node->getTile()->getNeighbor(newDirection)            
            node->addChildLeaf(nextTile,_mirror,newDirection)
            Dim createdChild as PathLeaf ptr = node->getChild(_mirror)
            if createdChild <> 0 then
                findNextMirror(createdChild,bounces + 1)
            else
                ' Something Wrong!
            end if
        else
            _pathTree->addFailedRoute(node,_mirror,"Can't have two mirrors in one area.")            
        end if
    else
        _pathTree->addFailedRoute(node,_mirror,"Too much reflections already to reach endtile.")
    end if
End Sub

Sub Robot.findNextMirror( node as PathLeaf ptr, bounces as integer )   
    if node <> 0 then
        Dim thisTile as TileMap_.Tile Ptr = node->getTile()
        if thisTile <> 0 then            
            checkChild_Mirror(Mirror.NE_SW,node,bounces)
            checkChild_Mirror(Mirror.NW_SE,node,bounces)
            checkChild_NoMirror(node,bounces)
        else
            ' at edge, find out if endtile is reached.
            if bounces = reflections then
                Dim parentNode as PathLeaf Ptr = node->getParent()
                if parentNode <> 0 then
                    Dim parentTile as TileMap_.Tile Ptr = parentNode->getTile()
                    if parentTile <> 0 then
                        if parentTile = endTile then
                            if node->getIncoming() = beamEndDirection then
                                ' Found endtile!!
                                ' Add succesful route.
                                _pathTree->addSuccessRoute(node)
                            else
                                 _pathTree->addFailedRoute(node,,"Tile is right, direction however is not.")
                            end if    
                        end if    
                    else
                        ' Wrong again parent must have tile that is not null!
                    end if
                else    
                    ' Something wrong!
                end if
            else
                _pathTree->addFailedRoute(node,,"Reaches edge with too little reflections.")
            end if
        end if
    else
        ' Something wrong should never receive null node.
    end if
End Sub    

Function Robot.getPath() as MyList.List ptr
    return path
End Function

Function Robot.getReflections() as integer
    return reflections
End Function

Function Robot.getEndTile() as TileMap_.Tile Ptr
    return endTile
End Function

Function Robot.getEndDirection() as Direction
    return beamEndDirection
End Function

Function Robot.getStartTile() as TileMap_.Tile Ptr
    return startTile
End Function

Function Robot.getStartDirection() as Direction
    return beamStartDirection
End Function

Function Robot.getStartX() as Integer
	return startX
End Function

Function Robot.getStartY() as Integer
	return startY
End Function

Function Robot.getEndX() as Integer
	return endX
End Function

Function Robot.getEndY() as Integer
	return endY
End Function

Function Robot.getRouteDescription() as String
    dim returnString as String
    returnString &= "########" & NEWLINE
    returnString &= "Tank  : " & str(id) & NEWLINE
    returnString &= "From start @ " & startTile->getCoordString() & NEWLINE
    returnString &= directionNames(beamStartDirection) & "wards in " & str(reflections) & " bounces." & NEWLINE
    returnString &= "To finish  @ " & endTile->getCoordString() & NEWLINE
    returnString &= "Facing " & directionNames(beamEndDirection) & "." & NEWLINE
    returnString &= "########" & NEWLINE
    return returnString
End Function    

'-------------
' ** BOARD! **
'-------------
Type Board
    private:
        areaList as MyList.List
        _tileMap as TileMap_.TileMap ptr
        areaMap(TileMap_.DEFAULT_MAPWIDTH,TileMap_.DEFAULT_MAPHEIGHT) as Area Ptr
        boardWidth as integer
        boardHeight as integer
        boardFileName as String

        ' SET THE RIGHT NUMBER HERE!!
        tileSprites(30) as any Ptr
        spriteMap(TileMap_.DEFAULT_MAPWIDTH,TileMap_.DEFAULT_MAPHEIGHT) as integer
        backGroundSprite as any Ptr
        mirrorMap(TileMap_.DEFAULT_MAPWIDTH,TileMap_.DEFAULT_MAPHEIGHT) as Mirror
        tankPositionTaken(4,6) as Bool

        ' Related to graphics
        spriteSize as integer = 32
        xOffset as integer = 0
        yOffset as integer = 0
        Declare Function getSpriteX( _tile as TileMap_.Tile Ptr ) as integer
        Declare Function getSpriteX( _tileX as integer ) as integer
		Declare Function getSpriteY( _tile as TileMap_.Tile Ptr ) as integer
        Declare Function getSpriteY( _tileY as integer ) as integer
		Declare Sub drawTank(__robot as Robot ptr )
		Declare Sub drawBoardBase()
		Declare Sub drawAllMirrors()
		Declare Sub drawBeam( __robot as Robot ptr )
		Declare Sub drawTile()
		Declare Sub drawBorder( img as any Ptr, length as integer, n as integer, e as integer, s as integer, w as integer )
        Declare Function loadSpriteFromFile( fileName as String ) as any ptr
        Declare Sub loadSprites()
        Declare Sub createBackGroundSprite()
        
        ' Robots
        robots(24) as Robot ptr
        Declare Sub placeTanks()
        Declare Function addTank( _tile as TileMap_.Tile Ptr, _direction as Direction, _tankID as integer ) as Robot ptr
        Declare Sub removeTank( _tile as TileMap_.Tile Ptr, _direction as Direction )

        ' Internal helpers        
        Declare Sub createTileMap()
        Declare Sub addArea( newArea as Area Ptr )
        Declare Sub createAreas()
        Declare Sub placeRandomMirrors()
        Declare Sub printBoardToFile()
    public:
        Declare Constructor( _boardWidth as integer, _boardHeight as integer )
        Declare Destructor()
        Declare Sub _draw()                
        Declare Sub setOffset( _xOffset as integer, yOffset as integer )
        Declare Function getWidth () as integer
        Declare Function getHeight () as integer
        Declare Function getBoardFileName() as String
        
        Declare Function getArea ( _tile as TileMap_.Tile Ptr ) as Area Ptr
        Declare Function getMirror ( _tile as TileMap_.Tile Ptr ) as Mirror
        Declare Sub setArea ( _tile as TileMap_.Tile Ptr, _area as Area Ptr )
        Declare Sub setMirror ( _tile as TileMap_.Tile Ptr, _mirror as Mirror )        
End Type

Constructor Board( _boardWidth as integer, _boardHeight as integer )
	if _boardWidth <= 6 and _boardHeight <= 6 then		
        boardWidth = _boardWidth
		boardHeight = _boardHeight		        
        
        ' Generate maps and populate
        createTileMap()
        createAreas()        
        placeRandomMirrors()
        boardFileName = "boards/board " & date & "_" & str(int(timer)) & ".txt"
        printBoardToFile()
        
        ' Prepare the sprites
        createBackGroundSprite()        
        loadSprites()
        
        ' Place tanks on the board
        placeTanks()
	else
		print "Error: board can be 6 x 6 at most."
        sleep
        end
	end if
End Constructor

Destructor Board
    ' Delete all objects Board created with the new statement
    if _tileMap <> 0 then
        delete _tileMap
    end if    
    for i as integer = 0 to ( boardWidth * 2 + boardHeight * 2 - 1)        
        if robots(i) <> 0 then
            delete robots(i)
        end if            
    next i
End Destructor

Sub Board.placeTanks()
    ' north edge        
    for i as integer = 0 to (boardWidth - 1)
        Dim index as integer = i
        robots(index) = addTank( _tileMap->getTile(i,0), Direction.South, index + 1)
    next i
    ' east edge
    for i as integer = 0 to (boardHeight - 1)
        Dim index as integer = boardWidth + i
        robots(index) = addTank( _tileMap->getTile((boardWidth - 1),i), Direction.West, index + 1)
    next i
    ' south edge
    for i as integer = 0 to (boardWidth - 1)
        Dim index as integer = boardWidth + boardHeight + i
        robots(index) = addTank( _tileMap->getTile(i,(boardHeight - 1)), Direction.North, index + 1)
    next i
    ' west edge
    for i as integer = 0 to (boardHeight - 1)
        Dim index as integer = (boardWidth * 2) + boardHeight + i
        robots(index) = addTank( _tileMap->getTile(0,i), Direction.East, index + 1)
    next i
End Sub    

Sub Board.setOffset( _xOffset as integer, _yOffset as integer )
	xOffset = _xOffset
	yOffset = _yOffset
End Sub

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
        print "Failed to load ";fileName; ", error nr. ";returnValue
        sleep
        end
    else
        return _img
    end if
    return 0
End Function

Sub Board.loadSprites()
    ' Load sprites for mirrors
    tileSprites(TileSprite.Mirror_NE_SW) = loadSpriteFromFile("pictures/mirror_orig.bmp")
    tileSprites(TileSprite.Mirror_NW_SE) = loadSpriteFromFile("pictures/mirror_flipped.bmp")
    
    ' Load sprites for the beams
    tileSprites(TileSprite.Beam_NE) = loadSpriteFromFile("pictures/beam_ne.bmp")
    tileSprites(TileSprite.Beam_NS) = loadSpriteFromFile("pictures/beam_ns.bmp")
    tileSprites(TileSprite.Beam_NW) = loadSpriteFromFile("pictures/beam_nw.bmp")
    tileSprites(TileSprite.Beam_ES) = loadSpriteFromFile("pictures/beam_es.bmp")
    tileSprites(TileSprite.Beam_EW) = loadSpriteFromFile("pictures/beam_ew.bmp")
    tileSprites(TileSprite.Beam_SW) = loadSpriteFromFile("pictures/beam_sw.bmp")
    
    ' Load sprites for the tanks
    tileSprites(TileSprite.Tank_N) = loadSpriteFromFile("pictures/tank_n.bmp")
    tileSprites(TileSprite.Tank_E) = loadSpriteFromFile("pictures/tank_e.bmp")
    tileSprites(TileSprite.Tank_S) = loadSpriteFromFile("pictures/tank_s.bmp")
    tileSprites(TileSprite.Tank_W) = loadSpriteFromFile("pictures/tank_w.bmp")
End Sub

Sub Board.createTileMap()
	_tilemap = new TileMap_.TileMap(boardWidth,boardHeight)
	For i as integer = 0 to (boardHeight - 1)
		For j as integer = 0 to (boardWidth - 1)
			Dim t as TileMap_.Tile Ptr = _tilemap->getTile(j,i)
			if t <> 0 then
                areaMap(j,i) = 0
                mirrorMap(j,i) = Mirror.None
            else
                print "Error: Null tile in tilemap!"
                sleep
                end
			end if
		Next j
	Next i
End Sub

Sub Board.createBackGroundSprite()    
    print "createBackGroundSprite"
    backGroundSprite = imageCreate(boardWidth * spriteSize,boardHeight * spriteSize)
    Dim floorColor as uinteger = rgb(0,128,128)
    for i as integer = 0 to (boardHeight - 1)
        for j as integer = 0 to (boardWidth - 1)
            Dim n as integer = 0
            Dim e as integer = 0
            Dim s as integer = 0
            Dim w as integer = 0
            Dim t as TileMap_.Tile Ptr = _tileMap->getTile(j,i)
            if t <> 0 then
                if getArea(t->getNeighbor(Direction.North)) <> getArea(t) then n = 1
                if getArea(t->getNeighbor(Direction.East)) <> getArea(t) then e = 1
                if getArea(t->getNeighbor(Direction.South)) <> getArea(t) then s = 1
                if getArea(t->getNeighbor(Direction.West)) <> getArea(t) then w = 1            
            end if
            Dim thisImg as any ptr = imagecreate(spriteSize,spriteSize)
            Line thisImg,(0,0)-(spriteSize-1,spriteSize-1),floorColor,BF
            drawBorder(thisImg,spriteSize,n,e,s,w)
            put backGroundSprite, (j * spriteSize, i * spriteSize), thisImg, pset
        next j
    next i    
End Sub  

'---
' Methods related to creation, placement and access of Areas and Mirrors on the board.
'---
Sub Board.createAreas()	
    if _tileMap <> 0 then       
        Dim tilesInAreas as integer = 0
        Dim areaID as integer = 0
		For i as integer = 0 to (boardHeight - 1)
			For j as integer = 0 to (boardWidth - 1)
				Dim tp as TileMap_.Tile Ptr = _tileMap->getTile(j,i)
				'Dim dp as TileData Ptr = tp->getData()
				if tp <> 0 then
					if getArea(tp) = 0 then						
                        Dim size as integer = int(rnd * boardWidth) + 1
                        areaID += 1
                        Dim newArea as Area Ptr = new Area(areaID,tp,size,@this)
						areaList.addObject(newArea)
                        tilesInAreas += newArea->getSize()
					end if
				end if
			Next j
		Next i
        if tilesInAreas <> boardWidth * boardHeight then
            print "Error: Too few tiles in areas. : "; tilesInAreas
            sleep
            end
        end if    
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

Function Board.getMirror( _tile as TileMap_.Tile Ptr ) as Mirror
    return mirrorMap(_tile->getCoord()->x,_tile->getCoord()->y)
End Function    

Sub Board.setMirror ( _tile as TileMap_.Tile Ptr, _mirror as Mirror )
    mirrorMap(_tile->getCoord()->x,_tile->getCoord()->y) = _mirror
End Sub    

Sub Board.setArea( _tile as TileMap_.Tile Ptr, _area as Area Ptr )
    if _tile <> 0 and _area <> 0 then
        areaMap(_tile->getCoord()->x,_tile->getCoord()->y) = _area
    else
        print "Error: Can't set Area, _tile or _area is empty!"
        sleep
        end
    end if    
End Sub

Function Board.getArea( _tile as TileMap_.Tile Ptr ) as Area Ptr
    if _tile <> 0 then
        return areaMap(_tile->getCoord()->x,_tile->getCoord()->y)
    end if
    return 0    
End Function    

' ----
' Methods for placing tanks on the board.
' ----
Function Board.addTank( _tile as TileMap_.Tile Ptr, _direction as Direction, _tankID as integer ) as Robot ptr
	if _tile <> 0 then
		Dim as Robot ptr newRobot = new Robot( _tankID, _tile, _direction, @this )
		Dim as integer edge = (_direction + 2) mod 4
		Dim as integer index
		Select Case edge
			Case Direction.North or Direction.South
				index = newRobot->getStartX()
			Case Direction.East or Direction.West
				index = newRobot->getStartY()
		End Select

		Dim isEndPointOfOtherRoute as Bool = Bool.False
		for i as integer = 0 to (_tankID - 2)
			if robots(i) <> 0 then
				if robots(i)->getEndX() = newRobot->getStartX() then
					if robots(i)->getEndY() = newRobot->getStartY() then
						isEndPointOfOtherRoute = Bool.True
						exit for
					end if
				end if
			end if
		next i

		newRobot->shootBeam()
		if newRobot->getReflections() > 0 and isEndPointOfOtherRoute = Bool.False then
			tankPositionTaken(edge,index) = Bool.True
			return newRobot
		else
			delete newRobot
			tankPositionTaken(edge,index) = Bool.False
			return 0
		end if
	end if
	return 0
End Function

Sub Board.removeTank( _tile as TileMap_.Tile Ptr, _direction as Direction )
End Sub    

' ----
' Methods and helper methods related to drawing the board etc.
' ----
Sub Board.drawTile()
End Sub

Function Board.getSpriteX(_tile as TileMap_.Tile Ptr) as integer
	if _tile <> 0 then
		return (_tile->getCoord()->x * 32 + xOffset)
	end if
	return -1
End Function

Function Board.getSpriteX(_tileX as integer) as integer
	return (_tileX * 32 + xOffset)
End Function

Function Board.getSpriteY(_tile as TileMap_.Tile Ptr) as integer
	if _tile <> 0 then
		return (_tile->getCoord()->y * 32 + yOffset)
	end if
	return -1
End Function

Function Board.getSPriteY(_tileY as integer) as integer
	return (_tileY * 32 + yOffset)
End Function

Sub Board.drawBoardBase()
    Put (xOffset,yOffset), backGroundSprite, pset
End Sub

Sub Board.drawAllMirrors()
	for i as integer = 0 to (boardHeight - 1)
		for j as integer = 0 to (boardWidth - 1)
            if mirrorMap(j,i) <> Mirror.None then
                if mirrorMap(j,i) = Mirror.NE_SW then
                    Put (getSpriteX(j), getSpriteY(i)), tileSprites(TileSprite.Mirror_NE_SW), trans
                end if
                if mirrorMap(j,i) = Mirror.NW_SE then
                    Put (getSpriteX(j), getSpriteY(i)), tileSprites(TileSprite.Mirror_NW_SE), trans
                end if
            end if
		next j
	next i
End Sub

Sub Board.drawTank(__robot as Robot ptr )
	if __robot <> 0 then
		' draw the tank
		Dim firstDirection as Direction = __robot->getStartDirection()
		Dim robotX as integer = __robot->getStartX() * 32 + xOffset
		Dim robotY as integer = __robot->getStartY() * 32 + yOffset
		Dim sprite as TileSprite = TileSprite.Tank_N
		IF firstDirection = Direction.East then
			sprite = TileSprite.Tank_E
		ElseIf firstDirection = Direction.South then
			sprite = TileSprite.Tank_S
		ElseIf firstDirection = Direction.West then
			sprite = TileSprite.Tank_W
		End if
		Put (robotX,robotY), tileSprites(sprite),trans
		' draw the number of reflections at endtile
		Dim endX as integer = __robot->getEndX() * 32 + xOffset
		Dim endY as integer = __robot->getEndY() * 32 + yOffset
		Draw String (endX+10,endY+10), str(__robot->getReflections())
	end if
End Sub

Sub Board.drawBeam( __robot as Robot ptr )
    if __robot <> 0 then
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
                    Dim _x as integer = getSpriteX(thisMove->_tile)
                    Dim _y as integer = getSpriteY(thisMove->_tile)
                    'print "Draw path for robot, tileSprite: "; thisMove->_tileSprite
                    'thisMove->_tile->debug()
                    'sleep
                    Put (_x, _y), tileSprites(thisMove->_tileSprite), trans
                    'locate 23,1
                    'print spriteX; ", "; spriteY
                    'sleep
                else
                    print "No tile in Move object."
                    sleep
                    end
                end if
            end if
            thisNode = thisNode->getNext()
            'sleep
        wend
    end if
End Sub

Sub Board._draw()
    for i as integer = 0 to ( boardWidth * 2 + boardHeight * 2 - 1)        
        if robots(i) <> 0 then
            cls
            drawBoardBase()
            drawAllMirrors()
            drawTank(robots(i))        
            drawBeam(robots(i))
            sleep
            robots(i)->findAlternativePaths()
            'drawBeam(robots(i))
            sleep
        end if    
    next i
End Sub

Sub Board.printBoardToFile()
    open boardFileName for output as #1
    for i as integer = 0 to boardHeight - 1            
        Dim coordLine as String = "    "
        if i = 0 then
            for j as integer = 0 to boardWidth - 1            
                coordLine &= " " & str(j) & "  "
            next j    
            print #1, coordLine
        end if        
        Dim line1 as String = ""        
        Dim line2 as String = ""
        Dim line3 as String = ""
        for j as integer = 0 to boardWidth - 1            
            Dim n as Bool = Bool.False
            Dim e as Bool = Bool.False
            Dim celBody as String = "   "
            if mirrorMap(j,i) = Mirror.NE_SW then celBody = " / "
            if mirrorMap(j,i) = Mirror.NW_SE then celBody = " \ "
            Dim _tile as TileMap_.Tile Ptr = _tileMap->getTile(j,i)
            if _tile->getNeighbor(Direction.North) = 0 then
                n = Bool.True
            else
                if getArea(_tile->getNeighbor(Direction.North)) <> getArea(_tile) then
                    n = Bool.True                
                end if
            end if    
            if _tile->getNeighbor(Direction.East) = 0 then
                e = Bool.True
            else
                if getArea(_tile->getNeighbor(Direction.East)) <> getArea(_tile) then
                    e = Bool.True                
                end if
            end if    
            if _tile->getNeighbor(Direction.South) = 0 then
                line3 &= "---+"
            end if    
            if _tile->getNeighbor(Direction.West) = 0 then
                line1 = "+" & line1
                line2 = "|" & line2
                if _tile->getNeighbor(Direction.South) = 0 then
                    line3 = "+" & line3
                end if
            else                
            end if
            if n = bool.True then
                line1 &= "---+"
            else
                line1 &= "   +"
            end if
            if e = bool.True then
                line2 &= celBody & "|"
            else   
                line2 &= celBody & " "
            end if
        next j
        print #1, "   " & line1
        print #1, " " & str(i) & " " & line2
        if line3 <> "" then
            print #1, "   " & line3
        end if        
    next i    
    close #1
End Sub

Function Board.getBoardFileName() as String
    return boardFileName
End Function
'-----------------
' End ** Board **
'-----------------

' ---------------------------------------------------------------------------
' Methods from ** Area ** Defined here because it needs methods from Board
' ---------------------------------------------------------------------------
Sub Area.addTiles( _tile as TileMap_.Tile Ptr, fromTile as TileMap_.Tile Ptr, s as Integer )
    'print "Area now has size: "; s
    if _tile <> 0 and tileList.getSize() < maxSize then
        'Dim _data as TileData Ptr = _tile->getData()
        if _board <> 0 then            
            if _board->getArea(_tile) = 0 then
                size += 1
                tileList.addObject(_tile)
                _board->setArea(_tile,@this)
                Dim nextTile as TileMap_.Tile Ptr
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
            print "no board defined!"
        end if
    end if
End Sub

Sub Area.placeRandomMirror()
    Dim randomIndex as Integer = int(rnd * tileList.getSize())
    Dim index as integer = 0
    Dim tempNode as MyList.ListNode ptr = tileList.getFirst()
    While tempNode <> 0
        Dim tp as TileMap_.Tile ptr = tempNode->getObject()
        if index = randomIndex then
            If tp <> 0 then
                'Dim td as TileData ptr = tp->getData()
                'If td <> 0 then
                    print
                    print "** Area: placing mirror at tile "; randomIndex; " **"
                    tp->debug()
                    'td->debug()
                    originalMirrorTile = tp
                    Dim r as Integer = int(rnd * 2)
                    if r = 0 then
                        originalMirrorType = Mirror.NE_SW
                    else
                        originalMirrorType = Mirror.NW_SE
                    end if
                    _board->setMirror(tp,originalMirrorType)
                    'td->setMirror(originalMirrorType)
                'Else
                    'print "Error: no TileData!"
                'End if
            Else
                print "Error: no TileMap_.Tile object!"
                sleep
                end
            End if
            exit while
        End if
        index += 1
        tempNode = tempNode->getNext()
    Wend
End Sub

'----------------------------------------------------------------------------
' Methods from ** Robot ** Defined here because it needs methods from Board
'----------------------------------------------------------------------------
Sub Robot.checkChild_NoMirror( node as PathLeaf ptr, bounces as integer )
    Dim thisTile as TileMap_.Tile Ptr = node->getTile()
    Dim thisArea as Area Ptr = _board->getArea(thisTile)
    if thisArea <> 0 then
        if thisArea->getSize() > 1 then
            Dim newDirection as Direction = directionMutations(Mirror.None,node->getIncoming())
            Dim nextTile as TileMap_.Tile Ptr = node->getTile()->getNeighbor(newDirection)
            node->addChildLeaf(nextTile,Mirror.None,newDirection)
            Dim createdChild as PathLeaf ptr = node->getChild(Mirror.None)
            if createdChild <> 0 then
                findNextMirror(createdChild,bounces)
            else
                ' Something Wrong!
            end if
        else
            _pathTree->addFailedRoute(node,Mirror.None,"Areas of one tile can't be skipped without placing a mirror.")
        end if    
    else
        print "Error: Tile Has no Mirror"
        sleep
        end
    end if
End Sub

Function Robot.areaHasMirror( node as PathLeaf ptr ) as Bool    
    Dim thisTile as TileMap_.Tile Ptr = node->getTile()
    Dim thisArea as Area Ptr = _board->getArea(thisTile)
    if thisArea = 0 then
        print "Error: thisTile is not part of an area!"
        sleep
        end
    end if    
    Dim thisNode as PathLeaf ptr = node    
    while thisNode <> 0
        Dim parentNode as PathLeaf ptr = thisNode->getParent()
        if parentNode <> 0 then
            Dim parentMirror as Mirror = thisNode->getParentOrientation()
            if parentMirror <> Mirror.None then
                Dim parentTile as TileMap_.Tile Ptr = parentNode->getTile()
                if parentTile <> 0 then
                    Dim parentArea as Area Ptr = _board->getArea(parentTile)
                    if parentArea = 0 then
                        print "Error: parentTile is not part of an area!"
                        sleep
                        end
                    end if    
                    if parentArea = thisArea then
                        if parentTile <> thisTile then
                            return Bool.True
                        end if 
                    end if
                end if
            end if    
        end if 
        thisNode = parentNode
    wend
    return Bool.False
End Function

Sub Robot.addToPath( _tile as TileMap_.Tile Ptr, newDir as Direction, currentDir as Direction )
    if _tile <> 0 then
        if _board->getMirror(_tile) > Mirror.None then
            reflections += 1
        end if
        Dim newMove as Move Ptr = new Move( _tile, beamSpriteGenerator( currentDir, newDir ) )
        path->addObject( newMove )
    else
    end if
End Sub

Sub Robot.shootBeam()
    reflections = 0
    Dim currentTile as TileMap_.Tile Ptr = startTile
    Dim currentDirection as Direction = beamStartDirection
    
    'Erase old pathdata and start with new path.
    if path <> 0 then        
        delete path
        path = new MyList.List()
    end if    
    
    print "** Constructing Path:"
    While currentTile <> 0
        currentTile->debug()
        ' Temporary dir and tile
        Dim newDirection as Direction
        Dim newTile as TileMap_.Tile Ptr
        Dim thisMirror as Mirror = _board->getMirror(currentTile)
        newDirection = directionMutations(thisMirror,currentDirection)
        newTile = currentTile->getNeighbor(newDirection)
        addToPath( currentTile, newDirection, currentDirection)
        ' Move to next
        if newTile = 0 then
            beamEndDirection = newDirection
            endTile = currentTile
            Select Case beamEndDirection
                case Direction.North:
                    endX = endTile->getCoord()->x
                    endY = endTile->getCoord()->y - 1
                case Direction.East:
                    endX = endTile->getCoord()->x + 1
                    endY = endTile->getCoord()->y
                case Direction.South:
                    endX = endTile->getCoord()->x
                    endY = endTile->getCoord()->y + 1
                case Direction.West:
                    endX = endTile->getCoord()->x - 1
                    endY = endTile->getCoord()->y
            End Select
        end if
        currentTile = newTile
        currentDirection = newDirection
    Wend
    'print "** Debug Path after construction: "
    'path->debug()
    'sleep
End Sub

Sub Robot.findAlternativePaths ()
    'print getRouteDescription()
    'followLine (startTile, beamStartDirection, 0, 0, "")
    '@TODO: fix and add findNextMirror here!
    _pathTree = new PathTree(startTile,beamStartDirection)
    findNextMirror( _pathTree->getRoot(), 0 )
    'print _pathTree->getRouteString()
    'Dim fileName as String = "routes_for_tank_" & str(id) & ".txt"    
    open _board->getBoardFileName() for append as #1
        print #1, getRouteDescription()
    close #1
    _pathTree->printRoutesToFile(_board->getBoardFileName())
End Sub

'------------------------
' Init Screen and Board.
'------------------------
ScreenRes 640,480,32

Dim w as integer = 4
Dim h as integer = 3
Dim b as Board Ptr = new Board(w,h)
Cls
Dim xoffset as integer = (640 - (32*w)) \ 2
Dim yoffset as integer = (480 - (32*h)) \ 2
b->setOffset(xoffset,yoffset)
b->_draw()
Sleep
delete b

System
