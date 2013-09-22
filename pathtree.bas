#include once "mirrorplacementmap.bas"

' ***
' RouteTile - For tiles used in a route.
' ***
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

'--------------------------------------
' RouteStep
'-------------------------------------- 
Type RouteStep
    _tile as TileMap_.Tile Ptr
    _mirror as Mirror
    Declare Destructor()    
End Type

Destructor RouteStep()
    _tile = 0    
End Destructor

'------------------
' FailedRoute
'------------------
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

' ***
' Path Tree
'
' A path tree consists of all routes tried by the board generating algorithm.
' Eacht step in that route is as PathLead object.
' ***
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

' ***
' The constructur takes a tile and direction as the root of the tree.
' ***
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
    ' output succesfull routes
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
        print "No routes found. This should never happen!"
        sleep
        end
    end if
    
    ' output failed routes
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