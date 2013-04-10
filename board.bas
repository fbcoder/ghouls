#include once "includes/list.bas"
#include once "includes/bool.bas"
#include once "includes/direction.bas"
#include once "includes/mirror.bas"
#include once "includes/newline.bas"
#include once "tilemap.bas"
#include once "area.bas"
#include once "contentmap.bas"

Randomize Timer

dim shared directionMutations(2,3) as Direction

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
    
'---------------------------------------------------------------------------------------
' MirrorPlacementMap or Possibility Map, notes which mirrors are possible for each tile
'---------------------------------------------------------------------------------------
Type MirrorPlacementMap
    private:
        _areaMap as Area_.Map Ptr
        map(TileMap_.MAX_MAPWIDTH,TileMap_.MAX_MAPHEIGHT,3) as Bool
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
    delete thisContentMap
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

function Robot.canReachEndTile ( node as PathLeaf ptr, bounces as integer ) as Bool
    dim bouncesToGo as integer = (reflections - bounces)
    dim thisDirection as Direction = node->getIncoming()
    dim opposite as Direction = (thisDirection + 2) mod 4
    if bouncesToGo = 0 then
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
        
        boardFileName = "boards/board_" & date & "_" & str(int(timer)) & ".txt"
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

'------------------------
' Init Screen and Board.
'------------------------
