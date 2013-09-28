#include once "includes/list.bas"
#include once "includes/bool.bas"
#include once "includes/direction.bas"
#include once "includes/newline.bas"
#include once "tilemap.bas"
#include once "area.bas"
#include once "contentmap.bas"
#include once "pathtree.bas"

randomize timer

'------------
' Robot/Tank
'------------
Type Robot
    private:
        _areaMap as Area_.Map Ptr
        _mirrorMap as MirrorMap.Map Ptr
        _pathTree as PathTree Ptr
        pathFixed as Bool = Bool.False
        _mirrorPlacementMap as MirrorPlacementMap Ptr
        id as integer
        
        startTile as TileMap_.Tile Ptr = 0
        startX as integer
        startY as integer
        beamStartDirection as Direction
        endTile as TileMap_.Tile Ptr = 0
        endX as integer
        endY as integer        
        beamEndDirection as Direction                        
        reflections as Integer = 0
        
        path as MyList.List ptr = 0        
        ' directionMutations(3,4) as Direction 
        Declare Sub addToPath( _tile as TileMap_.Tile Ptr, currentDir as Direction, prevDir as Direction )
        Declare Function getRouteDescription() as String
        
        ' Private helpers for pathFinding
        declare sub reachedEdge( node as PathLeaf ptr, bounces as integer )
        declare function canReachEndTile ( node as PathLeaf ptr, bounces as integer ) as Bool
        'Declare Function getMirrorString ( oldDir as Direction, newDir as Direction, orientation as Mirror ) as String
        Declare Sub tryMirrorNone ( node as PathLeaf ptr, bounces as integer, _tile as TileMap_.Tile ptr )
        Declare Sub tryMirrorNESW ( node as PathLeaf ptr, bounces as integer, _tile as TileMap_.Tile ptr )
        Declare Sub tryMirrorNWSE ( node as PathLeaf ptr, bounces as integer, _tile as TileMap_.Tile ptr )
        Declare Sub findNextMirror( node as PathLeaf ptr, bounces as integer )
        Declare Function areaCanHaveEmptyTile( node as PathLeaf Ptr ) as Bool
        Declare Function areaHasMirror ( node as PathLeaf ptr ) as Bool
        Declare Function canUseTileInRoute ( node as PathLeaf Ptr, mirrorToPlace as Mirror ) as Bool
        Declare Sub checkChild_Mirror ( _mirror as Mirror, node as PathLeaf ptr, bounces as integer )
        Declare Sub checkChild_NoMirror( node as PathLeaf ptr, bounces as integer )        
    public:
        Declare Constructor( _id as integer, _startTile as TileMap_.Tile Ptr, startDir as Direction, __areaMap as Area_.Map Ptr, __mirrorMap as MirrorMap.Map Ptr )
        Declare Destructor()
        Declare Sub shootBeam()
        Declare Function getId() as Integer
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
        
        ' Public related to pathfinding                
        Declare Sub findAlternativePaths ( possibilityMap as MirrorPlacementMap Ptr, fileName as String )        
        Declare Function hasPathFixed() as Bool
End Type

Constructor Robot( _id as integer, _startTile as TileMap_.Tile Ptr, startDir as Direction, __areaMap as Area_.Map Ptr, __mirrorMap as MirrorMap.Map Ptr )
    if _startTile <> 0 then
        if _id > 0 then
            id = _id
        else
            print "Error: Zero is no valid ID for tank."
            sleep
            end
        end if
        '_board = __board
        _mirrorMap = __mirrorMap
        _areaMap = __areaMap
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
    ' Get new directions when bouncing on a mirror   
End Constructor

Destructor Robot()
'    if path <> 0 then       
'        Dim iteratedNode as MyList.ListNode ptr = path->getFirst()
'        While iteratedNode <> 0
'            Dim as MyList.ListNode ptr nextNode = iteratedNode->getNext()
'            Dim as Move ptr thisMove = iteratedNode->getObject()
'            delete thisMove
'            iteratedNode = NextNode
'        Wend
'        delete path
'    end if
    if _pathTree <> 0 then
        delete _pathTree
    end if
End Destructor

'Function Robot.getMirrorString( oldDir as Direction, newDir as Direction, orientation as Mirror ) as String 
'    Dim mirrorChar as String
'    if orientation = Mirror.NE_SW then mirrorChar = "/"
'    if orientation = Mirror.NW_SE then mirrorChar = "\"
'    'return _tile->getCoordString() & mirrorChar   
'    return mirrorChar & "-->[" & directionNames(oldDir) & "->" & directionNames(newDir) & "]-->"
'End Function

Sub Robot.checkChild_Mirror( _mirror as Mirror, node as PathLeaf ptr, bounces as integer )
    if bounces < reflections then
        if canUseTileInRoute(node,_mirror) = Bool.True then
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
            _pathTree->addFailedRoute(node,_mirror,"Tile already used in route with different Mirror.")
        end if
    else
        _pathTree->addFailedRoute(node,_mirror,"Too much reflections already to reach endtile.")
    end if
End Sub

sub Robot.tryMirrorNESW ( node as PathLeaf ptr, bounces as integer, _tile as TileMap_.Tile ptr )
    if _mirrorPlacementMap->canPlaceMirror(_tile,Mirror.NE_SW) = Bool.True then
        if _areaMap->getArea(_tile)->canPlace(_tile,Mirror.NE_SW) = Bool.True then
            checkChild_Mirror(Mirror.NE_SW,node,bounces)
        else
            _pathTree->addFailedRoute(node,Mirror.NE_SW,"Tile already fixed for this Area.")
        end if                
    else
        Dim failMsg as String = "Mirror placement invalidated by MirrorPlacementMap. " & _mirrorPlacementMap->getPossibilityString(_tile)
        _pathTree->addFailedRoute(node,Mirror.NE_SW,failMsg)
    end if
end sub

sub Robot.tryMirrorNWSE ( node as PathLeaf ptr, bounces as integer, _tile as TileMap_.Tile ptr )
    if _mirrorPlacementMap->canPlaceMirror(_tile,Mirror.NW_SE) = Bool.True then                
        if _areaMap->getArea(_tile)->canPlace(_tile,Mirror.NW_SE) = Bool.True then
            checkChild_Mirror(Mirror.NW_SE,node,bounces)
        else
            _pathTree->addFailedRoute(node,Mirror.NW_SE,"Tile already fixed for this Area.")
        end if
    else
        Dim failMsg as String = "Mirror placement invalidated by MirrorPlacementMap. " & _mirrorPlacementMap->getPossibilityString(_tile)
        _pathTree->addFailedRoute(node,Mirror.NW_SE,failMsg)                
    end if
end sub    
    
sub Robot.tryMirrorNone ( node as PathLeaf ptr, bounces as integer, _tile as TileMap_.Tile ptr )
    if _mirrorPlacementMap->canPlaceMirror(_tile,Mirror.None) = Bool.True then                
        if _areaMap->getArea(_tile)->canPlace(_tile,Mirror.None) = Bool.True then
            checkChild_NoMirror(node,bounces)
        else
            _pathTree->addFailedRoute(node,Mirror.None,"Tile already fixed for this Area.")
        end if
    else
        Dim failMsg as String = "Mirror placement invalidated by MirrorPlacementMap. " & _mirrorPlacementMap->getPossibilityString(_tile)
        _pathTree->addFailedRoute(node,Mirror.None,failMsg)
    end if
end sub

sub Robot.reachedEdge( node as PathLeaf ptr, bounces as integer )
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
end sub

' ***
' For a given node in a path it should be determined if it's still possible to
' reach the EndTile in the right direction and the right number of bounces.
' ***
function Robot.canReachEndTile ( node as PathLeaf ptr, bounces as integer ) as Bool
    dim bouncesToGo as integer = (reflections - bounces)
    dim thisDirection as Direction = node->getIncoming()
    dim opposite as Direction = (thisDirection + 2) mod 4
    if bouncesToGo = 0 then
        ' No more bounces allowed so EndTile should be reached in a straight line.
        if beamEndDirection <> thisDirection then
            _pathTree->addFailedRoute(node,,"Direction wrong with no mirrors left.")
            return Bool.False
        end if
        dim thisTile as TileMap_.Tile ptr = node->getTile()
        select case thisDirection
            case Direction.North or Direction.South:
                if thisTile->getCoord()->x <> endX then
                    _pathTree->addFailedRoute(node,,"This route would end in the wrong column.")
                    return Bool.False
                end if    
            case Direction.East or Direction.West:
                if thisTile->getCoord()->y <> endY then
                    _pathTree->addFailedRoute(node,,"This route would end in the wrong row.")
                    return Bool.False
                end if    
        end select
    elseif bouncesToGo = 1 then      
        if (beamEndDirection = opposite) or (beamEndDirection = thisDirection) then
            _pathTree->addFailedRoute(node,,"Can't reach destination edge in 1 bounce with current Direction.")
            return Bool.False
        end if
        dim thisTile as TileMap_.Tile ptr = node->getTile()
        select case thisDirection
            case Direction.North:
                if thisTile->getCoord()->y < endY then
                    _pathTree->addFailedRoute(node,,"Too far North to reach endtile in 1 bounce.")
                    return Bool.False
                end if    
            case Direction.East:
                if thisTile->getCoord()->x > endX then
                    _pathTree->addFailedRoute(node,,"Too far East to reach endtile in 1 bounce.")
                    return Bool.False
                end if
            case Direction.West:
                if thisTile->getCoord()->x < endX then
                    _pathTree->addFailedRoute(node,,"Too far West to reach endtile in 1 bounce.")
                    return Bool.False
                end if
            case Direction.South:
                if thisTile->getCoord()->y > endY then
                    _pathTree->addFailedRoute(node,,"Too far South to reach endtile in 1 bounce.")
                    return Bool.False
                end if        
        end select
    elseif bouncesToGo = 2 then        
        if (beamEndDirection <> opposite) and (beamEndDirection <> thisDirection) then
            _pathTree->addFailedRoute(node,,"Can't reach destination edge in 2 bounces with current Direction.")
            return Bool.False
        end if    
    end if
    return Bool.True
end function

Sub Robot.findNextMirror( node as PathLeaf ptr, bounces as integer )   
    if node <> 0 then
        Dim thisTile as TileMap_.Tile Ptr = node->getTile()
        if thisTile <> 0 then            
            ' try to prune early
            if canReachEndTile(node,bounces) = Bool.True then
                tryMirrorNESW(node,bounces,thisTile)
                tryMirrorNWSE(node,bounces,thisTile)
                tryMirrorNone(node,bounces,thisTile)                
            end if
        else
            ' at edge, find out if endtile is reached.
            reachedEdge(node,bounces)
        end if
    else
        ' Something wrong should never receive null node.
    end if
End Sub    

Function Robot.getId() as Integer
    return id
End Function

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
    returnString &= directionNames(beamStartDirection) & "wards in " & str(reflections) & " bounce(s)." & NEWLINE
    returnString &= "To finish  @ " & endTile->getCoordString() & NEWLINE
    returnString &= "Facing " & directionNames(beamEndDirection) & "." & NEWLINE
    returnString &= "########" & NEWLINE
    return returnString
End Function

Sub Robot.checkChild_NoMirror( node as PathLeaf ptr, bounces as integer )
    Dim thisTile as TileMap_.Tile Ptr = node->getTile()
    Dim thisArea as Area_.Area Ptr = _areaMap->getArea(thisTile)
    if thisArea <> 0 then
        if thisArea->getSize() > 1 then
            if canUseTileInRoute(node,Mirror.None) = Bool.True then
                if areaCanHaveEmptyTile(node) = Bool.True then
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
                    _pathTree->addFailedRoute(node,Mirror.None,"Placing an empty tile here would make it impossible to fit a mirror in this Area.")
                end if 
            else
                _pathTree->addFailedRoute(node,Mirror.None,"Can't place empty tile, route already contains a mirror here.")
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

' ***
' A beam can 'reuse' a mirror already used in the same route or cross a beam. But it is not allowed to block ' a beam or change the mirror.
' ***
Function Robot.canUseTileInRoute ( node as PathLeaf Ptr, mirrorToPlace as Mirror ) as Bool
    Dim thisIterator as PathTreeIterator Ptr = new PathTreeIterator(node)
    while thisIterator->hasParent() = Bool.True
        Dim thisStep as RouteStep Ptr = thisIterator->getNextLeaf()                
        if thisStep <> 0 then
            if thisStep->_tile = node->getTile() then
                if thisStep->_mirror = mirrorToPlace then
                    delete thisIterator
                    return Bool.True
                else
                    delete thisIterator
                    return Bool.False
                end if    
            end if
        end if
    wend
    delete thisIterator
    return Bool.True
End Function

Function Robot.areaCanHaveEmptyTile( node as PathLeaf Ptr ) as Bool
    Dim thisTile as TileMap_.Tile Ptr = node->getTile()
    Dim thisArea as Area_.Area Ptr = _areaMap->getArea(thisTile)
    if thisArea = 0 then
        print "Error: thisTile is not part of an area!"
        sleep
    end
    end if
    Dim areaSize as integer = thisArea->getSize()
    if areaSize = 1 then
        return Bool.False
    else
    Dim emptyTilesList as MyList.List = MyList.List()    
    Dim emptyTiles as integer = 0
    Dim thisNode as PathLeaf ptr = node 
    while thisNode <> 0
        Dim parentNode as PathLeaf ptr = thisNode->getParent()
        if parentNode <> 0 then
            Dim parentMirror as Mirror = thisNode->getParentOrientation()
            if parentMirror = Mirror.None then
                Dim parentTile as TileMap_.Tile Ptr = parentNode->getTile()
                if parentTile <> 0 then
                    Dim parentArea as Area_.Area Ptr = _areaMap->getArea(parentTile)
                    if parentArea = 0 then
                        print "Error: parentTile is not part of an area!"
                        sleep
                        end
                    end if    
                    if parentArea = thisArea then
                        if parentTile <> thisTile then
                            if emptyTilesList.containsObject(parentTile) = Bool.False then
                                emptyTilesList.addObject(parentTile)
                                emptyTiles += 1
                                if emptyTiles >= (areaSize - 1) then
                                    return Bool.False
                                end if                                    
                            end if
                        end if
                    end if
                end if
            end if    
        end if 
        thisNode = parentNode
    wend
    end if
    return Bool.True
End Function    

Function Robot.areaHasMirror( node as PathLeaf ptr ) as Bool    
    Dim thisTile as TileMap_.Tile Ptr = node->getTile()
    Dim thisArea as Area_.Area Ptr = _areaMap->getArea(thisTile)
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
                    Dim parentArea as Area_.Area Ptr = _areaMap->getArea(parentTile)
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
        if _mirrorMap->getMirror(_tile) > Mirror.None then
            reflections += 1
        end if
        'Dim newMove as Move Ptr = new Move( _tile, beamSpriteGenerator( currentDir, newDir ) )
        'path->addObject( newMove )
    else
    end if
End Sub

Sub Robot.shootBeam()
    reflections = 0
    Dim currentTile as TileMap_.Tile Ptr = startTile
    Dim currentDirection as Direction = beamStartDirection
    
    'Erase old pathdata and start with new path.
'    if path <> 0 then        
'        delete path
'        path = new MyList.List()
'    end if    
    
    print "** Constructing Path:"
    While currentTile <> 0
        currentTile->debug()
        ' Temporary dir and tile
        Dim newDirection as Direction
        Dim newTile as TileMap_.Tile Ptr
        Dim thisMirror as Mirror = _mirrorMap->getMirror(currentTile)
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

Sub Robot.findAlternativePaths ( possibilityMap as MirrorPlacementMap Ptr, fileName as String )
    'print getRouteDescription()
    'followLine (startTile, beamStartDirection, 0, 0, "")
    '@TODO: fix and add findNextMirror here!
    if possibilityMap <> 0 then 
        _mirrorPlacementMap = possibilityMap
        if _pathTree = 0 then
            _pathTree = new PathTree(startTile,beamStartDirection)
        end if
        findNextMirror( _pathTree->getRoot(), 0 )
        'print _pathTree->getRouteString()
        'Dim fileName as String = "routes_for_tank_" & str(id) & ".txt"    
        open fileName for append as #1
            print #1, getRouteDescription()
        close #1
        _pathTree->printRoutesToFile(fileName)
        if _pathTree->hasUniqueSuccessRoute() = Bool.True then
            _pathTree->writeSuccessRoutesToMap(_mirrorPlacementMap,fileName)
            pathFixed = Bool.True
        end if
        
        delete _pathTree
        _pathTree = 0
    else
        print "Error: can't start pathfinding with null mirrormap!"
        sleep
        end
    end if
End Sub

Function Robot.hasPathFixed() as Bool
    return pathFixed
End Function

'----------------
' ** The Board **
'----------------
type Board
    private:
        _tileMap as TileMap_.TileMap ptr
        _areaMap as Area_.Map Ptr
        _mirrorMap as MirrorMap.Map Ptr
        boardWidth as integer
        boardHeight as integer
        boardFileName as String
        
        ' Robots
        tankPositionTaken(4,6) as Bool
        robots(24) as Robot ptr
        tankList as MyList.List ptr
        requiredTankList as MyList.List Ptr
        Declare Sub placeTanks()
        declare sub addTankToList( _tank as Robot ptr )
        Declare Function addTank( _tile as TileMap_.Tile Ptr, _direction as Direction, _tankID as integer ) as Robot ptr
    
        ' Internal helpers        
        Declare Sub createMaps()
        Declare Sub printBoardToFile()
    public:
        Declare Constructor( _boardWidth as integer, _boardHeight as integer )
        Declare Destructor()
        declare function solve() as Bool

        ' getters for the outside world
        Declare Function getBoardFileName() as String
        declare function getTankList () as MyList.List ptr
        declare function getRequiredTankList () as MyList.List ptr
        declare function getAreaMap () as Area_.Map ptr
        declare function getTileMap () as TileMap_.TileMap ptr
        declare function getWidth () as integer
        declare function getHeight () as integer
end type

Constructor Board( _boardWidth as integer, _boardHeight as integer )
    if _boardWidth <= 6 and _boardHeight <= 6 and _boardWidth > 0 and _boardHeight > 0 then		
    boardWidth = _boardWidth
        boardHeight = _boardHeight
    ' Generate maps and populate
    createMaps()
    
    boardFileName = Settings.boardsFolder & "/board_" & date & "_" & str(int(timer)) & ".txt"
    printBoardToFile()

    tankList = new MyList.List ()
    requiredTankList = new MyList.List ()
    placeTanks()
    else
        print "Error: Board dimensions must be larger than 0 and smaller than 7"
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
    delete tankList
    delete requiredTankList
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

Sub Board.createMaps()
    _tilemap = new TileMap_.TileMap(boardWidth,boardHeight)
    _mirrorMap = new MirrorMap.Map(boardWidth,boardHeight,_tileMap)
    _areaMap = new Area_.Map(boardWidth,boardHeight,_tileMap,_mirrorMap)
End Sub

' ----
' Methods for placing tanks on the board.
' ----
sub Board.addTankToList( _tank as Robot ptr )
    Dim reflections as integer = _tank->getReflections()
    Dim thisIterator as MyList.Iterator ptr = new MyList.Iterator(tankList)
    while thisIterator->hasNextObject() = Bool.True
        dim as Robot ptr thisTank = thisIterator->getNextObject()
        if reflections < thisTank->getReflections() then
            tankList->addObjectBefore(thisTank,_tank)
            delete thisIterator
            exit sub
        end if
    wend
    delete thisIterator
    tankList->addObjectTail(_tank)    
end sub    

Function Board.addTank( _tile as TileMap_.Tile Ptr, _direction as Direction, _tankID as integer ) as Robot ptr
	if _tile <> 0 then
		Dim as Robot ptr newRobot = new Robot( _tankID, _tile, _direction, _areaMap, _mirrorMap )
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
			tankList->addObjectTail(newRobot)
            return newRobot
		else
			delete newRobot
			tankPositionTaken(edge,index) = Bool.False
			return 0
		end if
	end if
	return 0
End Function

' ***
' Iterates over the list of tanks and let them generate routes to reach their
' destination.
' !!NOTE!! THIS FUNCTION SHOULD BE REWRITTEN
' ***
function Board.solve() as Bool
    Dim mirrorsToPlace as integer = _areaMap->getAreaCount()
    Dim possibilityMap as MirrorPlacementMap Ptr = new MirrorPlacementMap(boardWidth,boardHeight,_areaMap)
    dim outerIterator as MyList.Iterator ptr = new MyList.Iterator(tankList)
    while outerIterator->hasNextObject() = Bool.True        
        dim thisTank as Robot ptr = outerIterator->getNextObject()
        if thisTank <> 0 then
            if possibilityMap->getFixedMirrors() < mirrorsToPlace then
                if thisTank->hasPathFixed() = Bool.False then
                    thisTank->findAlternativePaths(possibilityMap,boardFileName)
                    if thisTank->hasPathFixed() = Bool.True then
                        requiredTankList->addObjectIfNew(thisTank)
                    end if
                    print "fixed ";possibilityMap->getFixedMirrors();"/";mirrorsToPlace;" mirrors."
                    dim innerIterator as MyList.Iterator ptr = new MyList.Iterator(tankList)
                    while innerIterator->hasNextObject()
                        dim otherTank as Robot ptr = innerIterator->getNextObject()
                        if otherTank <> 0 then
                            if otherTank <> thisTank then
                                if otherTank->hasPathFixed() = Bool.False then
                                    otherTank->findAlternativePaths(possibilityMap,boardFileName)
                                    if otherTank->hasPathFixed() = Bool.True then
                                        requiredTankList->addObjectIfNew(otherTank)
                                    end if
                                    print "fixed ";possibilityMap->getFixedMirrors();"/";mirrorsToPlace;" mirrors."
                                end if
                            else
                                exit while
                            end if
                        end if
                    wend
                    delete innerIterator
                end if
            else
            end if
            'sleep
        end if
    wend
    delete outerIterator
    if possibilityMap->getFixedMirrors() = mirrorsToPlace then
        print "Board has unique solution giving the following robots to the player:"        
        Dim robotIterator as MyList.Iterator ptr = new MyList.Iterator(requiredTankList)
        while robotIterator->hasNextObject() = Bool.True
            Dim thisRobot as Robot Ptr = robotIterator->getNextObject()
            print thisRobot->getId();
        wend
        delete robotIterator
        sleep
        return Bool.True
    else
        print "Board has no unique solution, multiple mirror combinations possible."
        sleep
    end if
    return Bool.False
end function

Sub Board.printBoardToFile()
    open boardFileName for output as #1
        print #1, _areaMap->toString()
    close #1
End Sub

Function Board.getBoardFileName() as String
    return boardFileName
End Function

function Board.getTankList () as MyList.List ptr
    return tankList
end function

function Board.getRequiredTankList () as MyList.List ptr
    return requiredTankList
end function

function Board.getAreaMap () as Area_.Map ptr
    return _areaMap
end function

function Board.getTileMap () as TileMap_.TileMap ptr
    return _tileMap
end function

function Board.getWidth () as integer
    return boardWidth
end function

function Board.getHeight () as integer
    return boardHeight
end function
'-----------------
' End ** Board **
'-----------------