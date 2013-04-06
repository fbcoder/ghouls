#include once "includes/list.bas"
#include once "includes/bool.bas"
#include once "includes/direction.bas"
#include once "includes/mirror.bas"
#include once "includes/newline.bas"
#include once "tilemap.bas"
#include once "area.bas"
#include once "contentmap.bas"

Randomize Timer

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
    
'---------------------------------------------------------------------------------------
' MirrorPlacementMap or Possibility Map, notes which mirrors are possible for each tile
'---------------------------------------------------------------------------------------
Type MirrorPlacementMap
    private:
        _areaMap as Area_.Map Ptr
        map(6,6,3) as Bool
        _width as integer
        _height as integer
        fixedMirrors as integer = 0
        Declare Function getShortString(x as integer, y as integer) as String
    public:
        Declare Constructor ( w as integer, h as integer, __areaMap as Area_.Map Ptr )
        Declare Sub removePossibleMirror( _tile as TileMap_.Tile Ptr, _mirror as Mirror )
        Declare Function canPlaceMirror ( _tile as TileMap_.Tile Ptr, _mirror as Mirror ) as Bool
        Declare Function getPossibilityString ( _tile as TileMap_.Tile Ptr ) as String
        Declare Function getFixedMirrors() as Integer 
        Declare Function toString() as String
End Type    

Constructor MirrorPlacementMap ( w as integer, h as integer, __areaMap as Area_.Map Ptr )
    _areaMap = __areaMap
    _height = h
    _width = w
    for i as integer = 0 to _height - 1
        for j as integer = 0 to _width - 1
            for h as integer = 0 to 2
                map(j,i,h) = Bool.True
            next h
        next j
    next i    
End Constructor

Sub MirrorPlacementMap.removePossibleMirror ( _tile as TileMap_.Tile Ptr, _mirror as Mirror )
    if map(_tile->getCoord()->x,_tile->getCoord()->y,_mirror) = Bool.True then        
        map(_tile->getCoord()->x,_tile->getCoord()->y,_mirror) = Bool.False    
        Dim remaining as integer = 0
        Dim onlyMirrorLeft as integer = -1
        for i as integer = 0 to 2
            if map(_tile->getCoord()->x,_tile->getCoord()->y,i) = Bool.True then
                onlyMirrorLeft = i
                remaining += 1
            end if            
        next i    
        if remaining = 1 then           
           if onlyMirrorLeft <> Mirror.None then
               print "fixed "; mirrorText(onlyMirrorLeft); " on tile "; _tile->getCoordString()
               fixedMirrors += 1
               Dim returnValue as Bool
               returnValue = _areaMap->getArea(_tile)->markFixed(_tile,onlyMirrorLeft)
           else
               Dim returnValue as Bool
               returnValue = _areaMap->getArea(_tile)->markFixed(_tile,Mirror.None)
           end if
        end if    
    else        
    end if
End Sub

Function MirrorPlacementMap.getFixedMirrors() as Integer
    return fixedMirrors
End Function    
    
Function MirrorPlacementMap.canPlaceMirror ( _tile as TileMap_.Tile Ptr, _mirror as Mirror ) as Bool
    return map(_tile->getCoord()->x,_tile->getCoord()->y,_mirror)
End Function

Function MirrorPlacementMap.getPossibilityString ( _tile as TileMap_.Tile Ptr ) as String
    Dim returnString as String = "possible ["
    for i as integer = 0 to 2
        if map(_tile->getCoord()->x,_tile->getCoord()->y,i) = Bool.True then
            returnString &=mirrorText(i)
        end if    
    next i    
    returnString & = "]"
    return returnString
End Function

Function MirrorPlacementMap.getShortString(x as integer, y as integer) as String
    Dim returnString as String = ""
    if map(x,y,Mirror.None) = Bool.True then
        returnString &= "*"
    else
        returnString &= " "
    end if
    if map(x,y,Mirror.NE_SW) = Bool.True then
        returnString &= "/"
    else
        returnString &= " "
    end if
    if map(x,y,Mirror.NW_SE) = Bool.True then
        returnString &= "\"
    else
        returnString &= " "
    end if
    return returnString
End Function

Function MirrorPlacementMap.toString () as String
    Dim thisContentMap as ContentMap Ptr = new ContentMap(_width,_height)
    for i as integer = 0 to (_height - 1)
        for j as integer = 0 to (_width - 1)
            Dim thisCoord as TileMap_.Coord Ptr = new TileMap_.Coord(j,i)
            'print "bla: " & getShortString(j,i)
            'sleep
            thisContentMap->setCell(thisCoord,getShortString(j,i))
            delete thisCoord
        next j
    next i    
    Dim as String returnString = _areaMap->toString(thisContentMap)    
    'delete thisContentMap
    return returnString
End Function

' ---------------------------------------
' RouteTile - For tiles used in a route.
' ---------------------------------------
Type RouteTile
    private:
        _tile as TileMap_.Tile Ptr
        inRoutes as integer = 0
        _mirror(3) as Bool
    public:    
        Declare Constructor( __tile as TileMap_.Tile Ptr, __mirror as Mirror )
        Declare Sub addMirror( __mirror as Mirror )
        Declare Function getMirror ( __mirror as Mirror ) as Bool
        Declare Function inAllRoutes( totalRoutes as integer ) as Bool
        Declare Function getTile() as TileMap_.Tile Ptr
End Type

Constructor RouteTile( __tile as TileMap_.Tile Ptr, __mirror as Mirror )
    'print "adding routeTile"; __mirror
    _tile = __tile
    for i as integer = 0 to 2
        _mirror(i) = Bool.False
    next i
    _mirror(__mirror) = Bool.True
    inRoutes = 1
End Constructor

Sub RouteTile.addMirror( __mirror as Mirror )
     'print "adding mirror"; __mirror
    _mirror(__mirror) = Bool.True
    inRoutes += 1
End Sub

Function RouteTile.getMirror ( __mirror as Mirror ) as Bool
    return _mirror(__mirror)
End Function    

Function RouteTile.inAllRoutes( totalRoutes as integer ) as Bool
    if inRoutes = totalRoutes then 
        return Bool.True
    end if    
    return Bool.False
End Function

Function RouteTile.getTile() as TileMap_.Tile Ptr
    return _tile
End Function    

Type RouteStep
    _tile as TileMap_.Tile Ptr
    _mirror as Mirror
    Declare Destructor()    
End Type

Destructor RouteStep()
    _tile = 0    
End Destructor

Type FailedRoute
    private:        
    public:
        failureMsg as String
        routeList as MyList.List ptr
        Declare Constructor( _failureMsg as String, _routeList as MyList.List Ptr )
        Declare Destructor()
End Type

Constructor FailedRoute( _failureMsg as String, _routeList as MyList.List Ptr )
    failureMsg = _failureMsg
    routeList = _routeList    
End Constructor

Destructor FailedRoute()
    Dim thisIterator as MyList.Iterator Ptr = new MyList.Iterator(routeList)
    while thisIterator->hasNextObject <> Bool.False
        Dim thisStep as RouteStep Ptr = thisIterator->getNextObject()
        delete thisStep
    wend
    delete thisIterator
End Destructor

' ---------
' Path Leaf
' ---------
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

' ---------
' Path Tree
' ---------
Type PathTree
    private:
        ' first Leaf in the tree
        root as PathLeaf ptr = 0
        routeList as MyList.List ptr = 0
        tileList as MyList.List ptr = 0
        failList as MyList.List ptr = 0
        debugFailedRoutes as Bool = Bool.True
        Declare Function getRouteList ( leaf as PathLeaf Ptr ) as MyList.List Ptr
        Declare Function printRoute ( listNode as MyList.ListNode Ptr ) as String
        Declare Function printRoute ( _list as MyList.List Ptr ) as String
        Declare Function findRouteTile( tileToFind as TileMap_.Tile Ptr ) as RouteTile Ptr
        Declare Sub addToTileList( _route as MyList.List Ptr )
        Declare Sub deleteLeaf( leaf as PathLeaf Ptr )
    public:
        Declare Constructor( _tile as TileMap_.Tile Ptr, _direction as Direction )
        Declare Destructor()
        Declare Function getRoot( ) as PathLeaf ptr
        Declare Sub addSuccessRoute ( leaf as PathLeaf Ptr )
        Declare Function getRouteString () as String
        Declare Sub addFailedRoute ( leaf as PathLeaf Ptr, _mirror as Mirror = Mirror.Undefined, failMsg as String )
        Declare Sub printRoutesToFile ( fileName as String )
        Declare Sub writeSuccessRoutesToMap( _mirrorMap as MirrorPlacementMap Ptr, fileName as String = "" )
        Declare Function hasUniqueSuccessRoute() as Bool
End Type    

Constructor PathTree( _tile as TileMap_.Tile Ptr, _direction as Direction )
    if _tile <> 0 then
        root = new PathLeaf(_tile,Mirror.None,0,_direction)
    end if
End Constructor

Destructor PathTree()
    ' delete leafs of the tree
    deleteLeaf(root)
    
    ' delete success routes
    if routeList <> 0 then        
        'print "Deleting routeList"
        Dim thisIterator as MyList.Iterator Ptr = new MyList.Iterator(routeList)
        while thisIterator->hasNextObject() = Bool.True
            Dim thisRoute as MyList.List Ptr = thisIterator->getNextObject()
            if thisRoute <> 0 then                
                'print "Deleting route of "; str(thisRoute->getSize()); " steps"
                Dim listIterator as MyList.Iterator Ptr = new MyList.Iterator(thisRoute)
                'print "a"
                while listIterator->hasNextObject() = Bool.True                    
                    Dim thisStep as RouteStep Ptr = listIterator->getNextObject()
                    'print thisStep
                    'sleep
                    if thisStep <> 0 then
                        'print "Deleting RouteStep" 
                        delete thisStep
                        'print "Done" 
                    end if 
                wend
                delete listIterator
                delete thisRoute
                'print "Done"
            end if
        wend
        delete thisIterator
        delete routeList
        'print "Done"
    end if
  
    'delete failed routes    
    if failList <> 0 then
        Dim thisIterator as MyList.Iterator Ptr = new MyList.Iterator(failList)
        while thisIterator->hasNextObject() <> Bool.False
            Dim thisFailedRoute as FailedRoute Ptr = thisIterator->getNextObject()
            delete thisFailedRoute
        wend
        delete failList
        delete thisIterator
    end if
End Destructor

Sub PathTree.deleteLeaf( leaf as PathLeaf Ptr )
    if leaf <> 0 then        
        for i as integer = 0 to 2        
            deleteLeaf(leaf->getChild(i))
        next i    
        delete leaf
    end if
End Sub

Function PathTree.getRoot() as PathLeaf Ptr
    return root
End Function    

Function PathTree.findRouteTile( tileToFind as TileMap_.Tile Ptr ) as RouteTile Ptr
    if tileList <> 0 then
        Dim thisIterator as MyList.Iterator Ptr = new MyList.Iterator(tileList)
        while thisIterator->hasNextObject() = Bool.True
            Dim thisRouteTile as RouteTile Ptr = thisIterator->getNextObject()
            if thisRouteTile <> 0 then
                'print "found RouteTile @";
                'print thisRouteTile->_tile
                if thisRouteTile->getTile() = tileToFind then                    
                    return thisRouteTile                    
                end if    
            end if 
        wend
        delete thisIterator
    end if
    return 0
End Function    
    
Sub PathTree.addToTileList( _route as MyList.List Ptr )
    if _route <> 0 then
        Dim thisIterator as MyList.Iterator Ptr = new MyList.Iterator(_route)
        while thisIterator->hasNextObject = Bool.True
            Dim thisStep as RouteStep Ptr = thisIterator->getNextObject()
            if thisStep <> 0 then
                Dim thisRouteTile as RouteTile Ptr = findRouteTile(thisStep->_tile)
                if thisRouteTile <> 0 then                    
                    thisRouteTile->addMirror(thisStep->_mirror)
                else
                    Dim newRouteTile as RouteTile Ptr = new RouteTile(thisStep->_tile,thisStep->_mirror)
                    'print "adding RouteTile"
                    tileList->addObject(newRouteTile)
                end if    
            end if
        wend 
        delete thisIterator
    end if         
End Sub

Function PathTree.getRouteList(leaf as PathLeaf Ptr) as MyList.List Ptr
    Dim thisRoute as MyList.List Ptr = new MyList.List()
    Dim thisLeaf as PathLeaf Ptr = leaf
    While thisLeaf->getParent() <> 0      
        Dim tileToAdd as TileMap_.Tile Ptr = thisLeaf->getParent()->getTile()
        Dim mirrorToAdd as Mirror = thisLeaf->getParentOrientation()
        thisRoute->addObject(new RouteStep(tileToAdd,mirrorToAdd))
        thisLeaf = thisLeaf->getParent()
    Wend
    return thisRoute
End Function

Sub PathTree.addSuccessRoute (leaf as PathLeaf Ptr)    
    if routeList = 0 then
        routeList = new MyList.List()
        tileList = new MyList.List()
    end if
    Dim thisRoute as MyList.List Ptr = getRouteList(leaf)
    addToTileList(thisRoute)
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
        returnString &= "Found " & str(routeList->getSize()) & " successful route(s)." & NEWLINE
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
        returnString &= NEWLINE
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

Sub PathTree.writeSuccessRoutesToMap( _mirrorMap as MirrorPlacementMap Ptr, fileName as String = "" )
    if tileList <> 0 then
        Dim thisIterator as MyList.Iterator Ptr = new MyList.Iterator(tileList)
        while thisIterator->hasNextObject() = Bool.True
            Dim thisRouteTile as RouteTile ptr = thisIterator->getNextObject()
            if thisRouteTile->inAllRoutes(routeList->getSize()) = Bool.True then
                Dim eliminatedMirrors as integer = 0
                Dim newEliminatedMirrors as integer = 0
                for i as integer = 0 to 2
                    if thisRouteTile->getMirror(i) = Bool.False then
                        if _mirrorMap->canPlaceMirror(thisRouteTile->getTile(),i) = Bool.True then
                            'new information!
                            print "elminated ["; mirrorText(i); "] on tile "; thisRouteTile->getTile()->getCoordString()
                            newEliminatedMirrors += 1
                        end if    
                        eliminatedMirrors += 1
                        _mirrorMap->removePossibleMirror(thisRouteTile->getTile(),i) 
                    end if    
                next i
                if eliminatedMirrors = 2 then
                    'if newEliminatedMirrors 
                    'print thisRouteTile->_tile->getCoordString()
                elseif eliminatedMirrors = 3 then
                    print "Error: Tiles must have at least one possible mirror!"
                    sleep
                    end
                else
                    
                end if    
            end if    
        wend    
        delete thisIterator
    end if
    if fileName <> "" then
        open fileName for append as #1
            print #1, _mirrorMap->toString()
        close #1
    end if
End Sub

Function PathTree.hasUniqueSuccessRoute() as Bool
    if routeList <> 0 then
        if routeList->getSize() = 1 then
            return Bool.True
        end if
    end if    
    return bool.False
End Function

'------------------
' PathTreeIterator
'------------------
Type PathTreeIterator
    private:
        currentNode as PathLeaf Ptr
    public:
        Declare Constructor ( startNode as PathLeaf Ptr )
        Declare Function hasParent() as Bool
        Declare Function getNextLeaf() as RouteStep Ptr  
End Type

Constructor PathTreeIterator ( startNode as PathLeaf Ptr )
    if startNode <> 0 then
        currentNode = startNode
    end if
End Constructor

Function PathTreeIterator.hasParent() as Bool
    if currentNode->getParent() <> 0 then
        return Bool.True
    end if    
    return Bool.False
End Function

Function PathTreeIterator.getNextLeaf() as RouteStep Ptr
    Dim returnMirror as Mirror = currentNode->getParentOrientation()
    currentNode = currentNode->getParent()
    if currentNode <> 0 then
        Dim returnTile as TileMap_.Tile Ptr = currentNode->getTile()    
        return new RouteStep(returnTile,returnMirror)
    end if
    return 0
End Function

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
        _areaMap as Area_.Map Ptr
        '_board as BoardPtr
        _mirrorMap as MirrorMap.Map Ptr
        _pathTree as PathTree Ptr
        pathFixed as Bool = Bool.False
        _mirrorPlacementMap as MirrorPlacementMap Ptr
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
        
        ' Private helpers for pathFinding
        Declare Function getMirrorString ( oldDir as Direction, newDir as Direction, orientation as Mirror ) as String
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
    if _pathTree <> 0 then
        delete _pathTree
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

Sub Robot.findNextMirror( node as PathLeaf ptr, bounces as integer )   
    if node <> 0 then
        Dim thisTile as TileMap_.Tile Ptr = node->getTile()
        if thisTile <> 0 then            
            if _mirrorPlacementMap->canPlaceMirror(thisTile,Mirror.NE_SW) = Bool.True then
                if _areaMap->getArea(thisTile)->canPlace(thisTile,Mirror.NE_SW) = Bool.True then
                    checkChild_Mirror(Mirror.NE_SW,node,bounces)
                else
                    _pathTree->addFailedRoute(node,Mirror.NE_SW,"Tile already fixed for this Area.")
                end if                
            else
                Dim failMsg as String = "Mirror placement invalidated by MirrorPlacementMap. " & _mirrorPlacementMap->getPossibilityString(thisTile)
                _pathTree->addFailedRoute(node,Mirror.NE_SW,failMsg)
            end if
            if _mirrorPlacementMap->canPlaceMirror(thisTile,Mirror.NW_SE) = Bool.True then                
                if _areaMap->getArea(thisTile)->canPlace(thisTile,Mirror.NW_SE) = Bool.True then
                checkChild_Mirror(Mirror.NW_SE,node,bounces)
                else
                    _pathTree->addFailedRoute(node,Mirror.NW_SE,"Tile already fixed for this Area.")
                end if
            else
                Dim failMsg as String = "Mirror placement invalidated by MirrorPlacementMap. " & _mirrorPlacementMap->getPossibilityString(thisTile)
                _pathTree->addFailedRoute(node,Mirror.NW_SE,failMsg)                
            end if
            if _mirrorPlacementMap->canPlaceMirror(thisTile,Mirror.None) = Bool.True then                
                if _areaMap->getArea(thisTile)->canPlace(thisTile,Mirror.None) = Bool.True then
                    checkChild_NoMirror(node,bounces)
                else
                    _pathTree->addFailedRoute(node,Mirror.None,"Tile already fixed for this Area.")
                end if
            else
                Dim failMsg as String = "Mirror placement invalidated by MirrorPlacementMap. " & _mirrorPlacementMap->getPossibilityString(thisTile)
                _pathTree->addFailedRoute(node,Mirror.None,failMsg)
            end if    
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
        _pathTree->writeSuccessRoutesToMap(_mirrorPlacementMap,fileName)
        if _pathTree->hasUniqueSuccessRoute() = Bool.True then
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

        ' SET THE RIGHT NUMBER HERE!!
        tileSprites(30) as any Ptr
        'spriteMap(TileMap_.DEFAULT_MAPWIDTH,TileMap_.DEFAULT_MAPHEIGHT) as integer
        backGroundSprite as any Ptr
                        
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
		Declare Sub drawBorder( img as any Ptr, length as integer, n as integer, e as integer, s as integer, w as integer )
        Declare Function loadSpriteFromFile( fileName as String ) as any ptr
        Declare Sub loadSprites()
        Declare Sub createBackGroundSprite()
        
        ' Robots
        tankPositionTaken(4,6) as Bool
        robots(24) as Robot ptr
        tankList as MyList.List ptr
        requiredTankList as MyList.List Ptr
        Declare Sub placeTanks()
        Declare Function addTank( _tile as TileMap_.Tile Ptr, _direction as Direction, _tankID as integer ) as Robot ptr        
    
        ' Internal helpers        
        Declare Sub createMaps()
        'Declare Sub addArea( newArea as Area Ptr )
        'Declare Sub createAreas()
        'Declare Sub placeRandomMirrors()
        Declare Sub printBoardToFile()
    public:
        Declare Constructor( _boardWidth as integer, _boardHeight as integer )
        Declare Destructor()
        declare function solve() as Bool                 
        'Declare Sub setOffset( _xOffset as integer, yOffset as integer )
        ' getters for the outside world
        Declare Function getBoardFileName() as String
        declare function getTankList () as MyList.List ptr
        declare function getAreaMap () as Area_.Map ptr
        declare function getTileMap () as TileMap_.TileMap ptr
        declare function getWidth () as integer
        declare function getHeight () as integer
        'Declare Function getArea ( _tile as TileMap_.Tile Ptr ) as Area Ptr
        'Declare Function getMirror ( _tile as TileMap_.Tile Ptr ) as Mirror
        'Declare Sub setArea ( _tile as TileMap_.Tile Ptr, _area as Area Ptr )
        'Declare Sub setMirror ( _tile as TileMap_.Tile Ptr, _mirror as Mirror )        
end type

Constructor Board( _boardWidth as integer, _boardHeight as integer )
	if _boardWidth <= 6 and _boardHeight <= 6 then		
        boardWidth = _boardWidth
		boardHeight = _boardHeight		        
        ' Generate maps and populate
        createMaps()
        
        'createAreas()        
        'placeRandomMirrors()
        boardFileName = "boards/board_" & date & "_" & str(int(timer)) & ".txt"
        printBoardToFile()
        
        ' Prepare the sprites
        'createBackGroundSprite()        
        'loadSprites()
        
        ' Place tanks on the board
        tankList = new MyList.List ()
        requiredTankList = new MyList.List ()
        placeTanks()
        
        ' Try to solve the Board        
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

'Sub Board.setOffset( _xOffset as integer, _yOffset as integer )
'	xOffset = _xOffset
'	yOffset = _yOffset
'End Sub

' functions for graphics
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

Sub Board.createMaps()
	_tilemap = new TileMap_.TileMap(boardWidth,boardHeight)
    _mirrorMap = new MirrorMap.Map(boardWidth,boardHeight,_tileMap)
    _areaMap = new Area_.Map(boardWidth,boardHeight,_tileMap,_mirrorMap)
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
End Sub  

' ----
' Methods for placing tanks on the board.
' ----
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
			tankList->addObject(newRobot)
            return newRobot
		else
			delete newRobot
			tankPositionTaken(edge,index) = Bool.False
			return 0
		end if
	end if
	return 0
End Function

' ----
' Methods and helper methods related to drawing the board etc.
' ----

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
            Dim t as TileMap_.Tile Ptr = _tileMap->getTile(j,i)
            if t <> 0 then
                if _mirrorMap->getMirror(t) <> Mirror.None then
                    if _mirrorMap->getMirror(t) = Mirror.NE_SW then
                        Put (getSpriteX(j), getSpriteY(i)), tileSprites(TileSprite.Mirror_NE_SW), trans
                    end if
                    if _mirrorMap->getMirror(t) = Mirror.NW_SE then
                        Put (getSpriteX(j), getSpriteY(i)), tileSprites(TileSprite.Mirror_NW_SE), trans
                    end if
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
                    print "Error: No tile in Move object."
                    sleep
                    end
                end if
            end if
            thisNode = thisNode->getNext()
            'sleep
        wend
    end if
End Sub

function Board.solve() as Bool
    Dim mirrorsToPlace as integer = _areaMap->getAreaCount()
    Dim possibilityMap as MirrorPlacementMap Ptr = new MirrorPlacementMap(boardWidth,boardHeight,_areaMap)
    for i as integer = 0 to ( boardWidth * 2 + boardHeight * 2 - 1)        
        if robots(i) <> 0 then
            'cls
            'drawBoardBase()
            'drawAllMirrors()
            'sleep
            if possibilityMap->getFixedMirrors() < mirrorsToPlace then
                'drawTank(robots(i))        
                'drawBeam(robots(i))
                if robots(i)->hasPathFixed() = Bool.False then
                    robots(i)->findAlternativePaths(possibilityMap,boardFileName)
                    if robots(i)->hasPathFixed() = Bool.True then
                        requiredTankList->addObjectIfNew(robots(i))                        
                    end if    
                    print "fixed ";possibilityMap->getFixedMirrors();"/";mirrorsToPlace;" mirrors."
                    if i > 0 then
                        for j as integer = 0 to (i - 1)
                            if robots(j) <> 0 then
                                if robots(j)->hasPathFixed() = Bool.False then
                                    robots(j)->findAlternativePaths(possibilityMap,boardFileName)
                                    if robots(j)->hasPathFixed() = Bool.True then
                                        requiredTankList->addObjectIfNew(robots(j))                        
                                    end if    
                                    print "fixed ";possibilityMap->getFixedMirrors();"/";mirrorsToPlace;" mirrors."
                                end if
                            end if
                        next j    
                    end if    
                end if                
            else
            end if
            'sleep
        end if    
    next i
    if possibilityMap->getFixedMirrors() = mirrorsToPlace then
        'cls
        'drawBoardBase()
        print "Board has unique solution giving the following robots to the player:"        
        Dim robotIterator as MyList.Iterator ptr = new MyList.Iterator(requiredTankList)
        while robotIterator->hasNextObject() = Bool.True
            Dim thisRobot as Robot Ptr = robotIterator->getNextObject()
            print thisRobot->getId();
            'drawTank(thisRobot)
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

'------------------------
' Init Screen and Board.
'------------------------
