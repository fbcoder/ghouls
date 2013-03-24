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

Type AreaPtr as Area Ptr
    
Type TileData
    private:
        _tile as Tile Ptr = 0
        directionMap(4) as Direction
        mirrorType as Mirror = Mirror.None
        areaID as Integer = 0
        _area as AreaPtr = 0
        _isStartTile as Bool = Bool.False
        _isEndTile as Bool = Bool.False
        Declare Sub restoreDirectionMap()
    public:
        Declare Constructor( __tile as Tile Ptr )
        Declare Sub setArea( __area as areaPtr )
        Declare Function getArea() as areaPtr
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

Sub TileData.setArea( __area as AreaPtr )
    if __area <> 0 then
        if _area = 0 then
            _area = __area
        else
            sleep
        end if
    else
        sleep
    end if    
End Sub

Function TileData.getArea() as AreaPtr
    return _area
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
            if neighborData->getArea() <> _area then
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
    print "Part of Area (@ address): "; _area
    print "Mirror: "; mirrorText(mirrorType)
End Sub

'----------
' An area
'----------
Type Area
    private:
        id as integer = 0
        tileList as MyList.list
        size as integer = 0
        maxSize as integer = 0
        hasMirror as Bool = Bool.False
        originalMirrorType as Mirror
        originalMirrorTile as Tile Ptr
        Declare Function getRandomDirection() as Direction
        Declare Sub addTiles( _tile as Tile Ptr, fromTile as Tile Ptr, s as Integer )
    public:
        Declare Constructor ( _id as integer, startTile as Tile Ptr, maxSize as integer )
        Declare Sub placeRandomMirror()
        Declare Sub debug()
        Declare Sub debugList()
        Declare Function getSize() as integer
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
                size += 1
                tileList.addObject(_tile)
                _data->setArea(@this)
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
                    originalMirrorTile = tp
                    Dim r as Integer = int(rnd * 2)
                    if r = 0 then
                        originalMirrorType = Mirror.NE_SW
                    else
                        originalMirrorType = Mirror.NW_SE
                    end if
                    td->setMirror(originalMirrorType)
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

Function area.getSize() as integer
    return size
End Function

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
Enum TerminationCode
    NotTerminated
    Null
    SameArea
    MustHaveMirror    
End Enum    

Type PathLeaf
    private:
        _tile as tile Ptr
        orientation as Mirror
        'terminates as TerminationCode = Terminati
        bounces as integer = 0
        parent as PathLeaf ptr
        children(3) as PathLeaf ptr
        numberOfChildLeafs as integer = 0
    public:
        Declare Constructor( __tile as Tile Ptr, _orientation as Mirror, _parent as PathLeaf ptr )
        Declare Sub addChildLeaf( __tile as Tile Ptr, _orientation as Mirror)
        Declare Function getChild( orientation as Mirror ) as PathLeaf Ptr
        Declare Function getParent() as PathLeaf Ptr
        Declare Function hasChildren() as Bool
        Declare Function getTile() as tile Ptr
        Declare Function getBounces() as integer
        Declare Function getOrientation() as Mirror        
End Type

Constructor PathLeaf( __tile as Tile Ptr, _orientation as Mirror, _parent as PathLeaf ptr )    
    parent = _parent
    for i as integer = Mirror.None to Mirror.NW_SE
        children(i) = 0
    next i   
    if __tile <> 0 then
        _tile = __tile
        if _orientation >= Mirror.None and _orientation <= Mirror.NW_SE then
            orientation = _orientation
            Dim as integer parentBounces = 0
            if parent <> 0 then
                parentBounces = parent->getBounces
            end if
            if _orientation <> Mirror.None then
                bounces = parentBounces + 1
            end if                    
        else
            print "Wrong value for orientation: "; _orientation
            sleep
            end
        end if
    else
        print "Can't take 0 for __tile!"
        sleep
        end
    end if        
End Constructor

Sub PathLeaf.addChildLeaf( __tile as Tile Ptr, _orientation as Mirror )    
    children( _orientation ) = new PathLeaf( __tile, _orientation, @this )
    numberOfChildLeafs += 1
End Sub

Function PathLeaf.getChild( orientation as Mirror ) as PathLeaf Ptr
    return children( orientation )
End Function

Function PathLeaf.getParent() as PathLeaf Ptr
    return parent
End Function    

Function PathLeaf.hasChildren() as Bool
    if numberOfChildLeafs > 0 then
        return Bool.True
    end if
    return Bool.False
End Function    

Function PathLeaf.getTile() as Tile Ptr
    return _tile
End Function

Function PathLeaf.getOrientation() as Mirror
    return orientation
End Function

Function PathLeaf.getBounces() as integer
    return bounces
End Function    

Type PathTree
    private:
        ' first Leaf in the tree
        root as PathLeaf ptr = 0
        Declare Sub printLeaf( thisLeaf as PathLeaf Ptr, pathString as String, _step as integer )
        Declare Sub printLeafs2 ( thisLeaf as PathLeaf Ptr )
    public:
        Declare Constructor( _tile as Tile Ptr )
        Declare Function getRoot( ) as PathLeaf ptr
        Declare Sub printPaths()
End Type    

Constructor PathTree( _tile as Tile Ptr )
    if _tile <> 0 then
        root = new PathLeaf(_tile,Mirror.None,0)
    end if
End Constructor

Function PathTree.getRoot() as PathLeaf Ptr
    return root
End Function    

Sub PathTree.printLeaf( thisLeaf as PathLeaf Ptr, pathString as String, _step as integer )
    if thisLeaf <> 0 then
        Dim as Tile Ptr thisTile = thisLeaf->getTile()
        if thisTile <> 0 then            
            'print mirrorText(thisLeaf->getOrientation())            
            for i as integer = 0 to 2
                print _step; " : "; thisTile->getCoordString()
                print "via : "; mirrorText(thisLeaf->getOrientation()); " ("; thisLeaf->getBounces() ;" bounces) to: "
                if thisLeaf->getChild(i) <> 0 then                                        
                    printLeaf(thisLeaf->getChild(i),pathString,_step + 1)
                else  
                    print "-xx-"
                end if    
            next i
         end if    
    else        
        'pathString = pathString & "[terminated]"
        'print pathString
    end if
End Sub    
    
Sub PathTree.printLeafs2 ( thisLeaf as PathLeaf Ptr )
    if thisLeaf <> 0 then
        for i as integer = 0 to 2
            Dim pathPrinted as integer = 0
            Dim child as PathLeaf Ptr = thisLeaf->getChild(i)
            if child <> 0 then
                printLeafs2 (child)
            else               
                if pathPrinted = 0 then
                    Dim path as string
                    Dim parent as PathLeaf ptr = thisLeaf
                    While parent <> 0
                        Dim thisTile as Tile Ptr = parent->getTile()
                        Dim thisMirror as Mirror = parent->getOrientation()
                        path = path & "<--" & thisTile->getCoordString() & "[" & mirrorText(thisMirror) & "]"
                        'print path
                        'sleep
                        parent = parent->getParent()
                    Wend
                    pathPrinted = 1
                    print path
                    Sleep
                end if
            end if    
        next i
    end if
End Sub

Sub PathTree.printPaths()
    printLeafs2(root)
End Sub    

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
        id as integer
        startX as integer
        startY as integer
        endX as integer
        endY as integer
        beamStartDirection as Direction
        beamEndDirection as Direction
        startTile as Tile Ptr = 0
        endTile as Tile Ptr = 0
        reflections as Integer = 0
        path as MyList.List ptr = 0
        _pathTree as PathTree ptr = 0
        beamSpriteGenerator(4,4) as TileSprite
        directionMutations(3,4) as Direction 
        Declare Sub addToPath( _tile as Tile Ptr, currentDir as Direction, prevDir as Direction )
    public:
        Declare Constructor( _id as integer, _startTile as Tile Ptr, startDir as Direction )
        Declare Sub shootBeam()
        Declare Function getPath() as MyList.List ptr
        Declare Function getReflections() as Integer
        Declare Function getEndTile() as Tile Ptr
        Declare Function getEndDirection() as Direction
        Declare Function getStartTile() as Tile Ptr
        Declare Function getStartDirection() as Direction
        Declare Function getEndX() as Integer
        Declare Function getEndY() as Integer
        Declare Function getStartX() as Integer
        Declare Function getStartY() as Integer
        
        ' Methods for pathfinding
        Declare Sub followLine ( thisTile as Tile Ptr, thisDirection as Direction, bounces as integer, lineLength as integer, thisPath as String )
        Declare Sub placeMirror( orientation as Mirror, thisTile as Tile Ptr, prevTile as Tile Ptr, thisDirection as Direction, bounces as integer, thisPath as String )
        Declare Sub findAlternativePaths ()
        Declare Sub addMirrorToPath( _tile as Tile Ptr, thisDirection as Direction, orientation as Mirror, newBounces as integer, oldPath as String )
        Declare Function getMirrorString ( oldDir as Direction, newDir as Direction, orientation as Mirror ) as String
        Declare Function getNewDirection ( currentDirection as Direction, orientation as Mirror ) as Direction
        Declare Function getArea ( _tile as Tile Ptr ) as Area Ptr
        Declare Sub findNextMirror( _direction as Direction, currentNode as PathLeaf ptr )
End Type

Constructor Robot( _id as integer, _startTile as Tile Ptr, startDir as Direction )
    if _startTile <> 0 then
        if _id > 0 then
            id = _id
        else
            print "Error: Zero is no valid ID for tank."
            sleep
            end
        end if    
        path = new MyList.List()
        startTile = _startTile
        beamStartDirection = startDir
        Select Case beamStartDirection
			case Direction.North:
				startX = startTile->getX()
				startY = startTile->getY() + 1
			case Direction.East:
				startX = startTile->getX() - 1
				startY = startTile->getY()
			case Direction.South:
				startX = startTile->getX()
				startY = startTile->getY() - 1
			case Direction.West:
				startX = startTile->getX() + 1
				startY = startTile->getY()
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
                beamEndDirection = newDirection
                endTile = currentTile
                Select Case beamEndDirection
					case Direction.North:
						endX = endTile->getX()
						endY = endTile->getY() - 1
					case Direction.East:
						endX = endTile->getX() + 1
						endY = endTile->getY()
					case Direction.South:
						endX = endTile->getX()
						endY = endTile->getY() + 1
					case Direction.West:
						endX = endTile->getX() - 1
						endY = endTile->getY()
                End Select
            end if
            currentTile = newTile
            currentDirection = newDirection
        end if
    Wend
    'print "** Debug Path after construction: "
    'path->debug()
    'sleep
End Sub

Function Robot.getArea ( _tile as Tile Ptr ) as Area Ptr
    if _tile <> 0 then
        Dim td as TileData ptr
        td = _tile->getData()
        if td <> 0 then
            return td->getArea()
        else
            print "Can't get Area for tile w/o TileData!"
            sleep
            end
        end if    
    end if
    print "Can't get Area for empty Tile!"
    sleep
    end    
    return 0
End Function

Function Robot.getNewDirection ( currentDirection as Direction, orientation as Mirror ) as Direction
    return directionMutations(orientation, currentDirection)
End Function

Function Robot.getMirrorString( oldDir as Direction, newDir as Direction, orientation as Mirror ) as String 
    Dim mirrorChar as String
    if orientation = Mirror.NE_SW then mirrorChar = "/"
    if orientation = Mirror.NW_SE then mirrorChar = "\"
    'return _tile->getCoordString() & mirrorChar   
    return mirrorChar & "-->[" & directionNames(oldDir) & "->" & directionNames(newDir) & "]-->"
End Function

Sub Robot.findAlternativePaths ()
    print "start following path from "; startTile->getCoordString(); " to "; endTile->getCoordString();" "; directionNames(beamStartDirection); "wards with "; reflections; " reflections."
    'followLine (startTile, beamStartDirection, 0, 0, "")
    '@TODO: fix and add findNextMirror here!
    _pathTree = new PathTree(startTile)
    findNextMirror(beamStartDirection,_pathTree->getRoot())
    print "Printing the paths for tank "; id 
    sleep
    '_pathTree->printPaths()
End Sub

Sub Robot.addMirrorToPath( _tile as Tile Ptr, thisDirection as Direction, orientation as Mirror, newBounces as integer, oldPath as String )
    Dim oldDir as Direction = thisDirection                            
    thisDirection = getNewDirection(thisDirection, orientation)
    if thisDirection > 3 or thisDirection < 0 then
        print "wrong direction!: "; thisDirection
        sleep
        end
    end if    
    Dim as String newPath 
    newPath = oldPath & getMirrorString(oldDir,thisDirection,orientation)
    followLine(_tile, thisDirection, newBounces, 0, newPath)
End Sub

Sub Robot.placeMirror( orientation as Mirror, thisTile as Tile Ptr, prevTile as Tile Ptr, thisDirection as Direction, bounces as integer, thisPath as String )
    if orientation <> Mirror.None then
        if thisTile <> 0 then
            if prevTile <> 0 then
                if thisTile <> prevTile then
                    if getArea(thisTile) <> getArea(prevTile) then
                        ' if mirror does not stand in the way of other Tanks' path
                        addMirrorToPath(thisTile, thisDirection, orientation, bounces + 1, thisPath)
                    else
                        print "fail (2 mirrors in same area): "; thisPath
                        return
                    end if                    
                end if            
                return
            else
                addMirrorToPath(thisTile, thisDirection, orientation, bounces + 1, thisPath)
            end if
        else
            if prevTile <> 0 then
                addMirrorToPath(thisTile, thisDirection, orientation, bounces + 1, thisPath)
            end if    
        end if
    end if
End Sub
    
Sub Robot.followLine ( thisTile as Tile Ptr, thisDirection as Direction, bounces as integer, lineLength as integer, thisPath as String )
    if thisTile <> 0 then          
        thisPath = thisPath & "[" & bounces & "]" & thisTile->getCoordString()
        
        ' get the next Tile in this Line
        Dim nextTile as Tile Ptr
        nextTile = thisTile->getNeighbor(thisDirection)
        Dim continueThisLine as Bool = Bool.False
        ' if the desired number of reflections is not meet yet
        if bounces < reflections then        
            Dim pathFork as String            
            if lineLength = 0 then
                pathFork = thisPath
                placeMirror(Mirror.NE_SW, thisTile, 0, thisDirection, bounces, pathFork)
                pathFork = thisPath
                placeMirror(Mirror.NW_SE, thisTile, 0, thisDirection, bounces, pathFork)            
            else
                pathFork = thisPath
                placeMirror(Mirror.NE_SW, nextTile, thisTile, thisDirection, bounces, pathFork)
                pathFork = thisPath
                placeMirror(Mirror.NW_SE, nextTile, thisTile, thisDirection, bounces, pathFork)                
            end if
            continueThisLine = Bool.True
        else
            Select Case thisDirection
                case Direction.North or Direction.South:
                    if thisTile->getX() = endX then 
                        continueThisLine = Bool.True                
                    end if    
                case Direction.East or Direction.West:
                    if thisTile->getY() = endY then 
                        continueThisLine = Bool.True                
                    end if    
            End Select
        end if        
        if nextTile <> 0 then
            if continueThisLine = Bool.True then
                ' this space must be free in order to reach endpoint
                thisPath = thisPath & "->" 
                followLine (nextTile, thisDirection, bounces, lineLength + 1, thisPath)
            end if
        else
            if thisTile = endTile and thisDirection = beamEndDirection then
                ' eureka! found a route
                print "succes! : " & thisPath
                'sleep
            else
                ' failed to find a path
                print "fail! : " & thisPath
            end if    
        end if    
    end if    
End Sub


Sub Robot.findNextMirror( _direction as Direction, currentNode as PathLeaf ptr )
    
    Dim _tile as Tile Ptr = currentNode->getTile()
    
    Dim prevMirrorTile as Tile Ptr = 0
    Dim parent as PathLeaf Ptr = currentNode->getParent()
    While parent <> 0
        if parent->getOrientation() <> Mirror.None then
            prevMirrorTile = parent->getTile()
            exit While
        end if
        'move up
        parent = parent->getParent()
    Wend   
    
    Dim checkMirror(3) as integer = {0,0,0}    
    if getArea(_tile)->getSize() > 1 then
        checkMirror(Mirror.None) = 1
    end if    
    if currentNode->getBounces() < reflections then        
        if prevMirrorTile <> 0 then            
            if getArea(prevMirrorTile) <> getArea(_tile) then                
                checkMirror(Mirror.NE_SW) = 1
                checkMirror(Mirror.NW_SE) = 1
            end if
        else
            checkMirror(Mirror.NE_SW) = 1
            checkMirror(Mirror.NW_SE) = 1
        end if    
    end if    
    
    for i as integer = 0 to 2        
        if checkMirror(i) = 1 then
            Dim newDirection as Direction = directionMutations(i,_direction)
            Dim nextTile as Tile Ptr = _tile->getNeighbor(newDirection)
            if nextTile <> 0 then
                currentNode->addChildLeaf(nextTile,i)
                findNextMirror(newDirection,currentNode->getChild(i))
            end if    
        end if    
    next i
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

ScreenRes 640,480,32

Type Board
    private:
        areaList as MyList.List
        'areaList as Area Ptr Ptr
        'areas as integer = 0
        _tileMap as TileMap ptr
        boardWidth as integer
        boardHeight as integer

        ' SET THE RIGHT NUMBER HERE!!
        tileSprites(30) as any Ptr
        spriteMap(6,6) as integer
        mirrorMap(6,6) as Mirror
        tankPositionTaken(4,6) as Bool

        ' Related to graphics
        spriteSize as integer = 32
        xOffset as integer = 0
        yOffset as integer = 0
        Declare Function getSpriteX( _tile as Tile Ptr ) as integer
        Declare Function getSpriteX( _tileX as integer ) as integer
		Declare Function getSpriteY( _tile as Tile Ptr ) as integer
        Declare Function getSpriteY( _tileY as integer ) as integer
		Declare Sub drawTank(__robot as Robot ptr )
		Declare Sub drawBoardBase()
		Declare Sub drawAllMirrors()
		Declare Sub drawBeam( __robot as Robot ptr )
		Declare Sub drawTile()
		Declare Sub drawBorder( img as any Ptr, length as integer, n as integer, e as integer, s as integer, w as integer )
        Declare Function loadSpriteFromFile( fileName as String ) as any ptr
        Declare Sub loadSprites()
        Declare Sub createSpriteMap()
        ' Robots
        robots(24) as Robot ptr

        ' Internal helpers
        Declare Sub createTileMap()
        Declare Sub addArea( newArea as Area Ptr )
        Declare Sub createAreas()
        Declare Sub placeRandomMirrors()
    public:
        Declare Constructor( _boardWidth as integer, _boardHeight as integer )
        Declare Sub _draw()
        Declare Function addTank( _tile as Tile Ptr, _direction as Direction, _tankID as integer ) as Robot ptr
        Declare Sub removeTank( _tile as Tile Ptr, _direction as Direction )
        Declare Sub setOffset( _xOffset as integer, yOffset as integer )
        Declare Function getWidth () as integer
        Declare Function getHeight () as integer
End Type

Constructor Board( _boardWidth as integer, _boardHeight as integer )
	if _boardWidth <= 6 and _boardHeight <= 6 then
		boardWidth = _boardWidth
		boardHeight = _boardHeight
		print "* creating tilemap"
        sleep
        createTileMap()
        print "* creating areas"
        sleep
		createAreas()
		placeRandomMirrors()
		loadSprites()
        createSpriteMap()
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
	else
		print "Error: board can be 6 x 6 at most."
	end if
End Constructor

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

Sub Board.addArea( newArea as Area Ptr )
    if newArea <> 0 then
        Dim result as Area Ptr = 0
        'result = reallocate(areaList,(areas + 1) * sizeof(Area Ptr))
        if result <> 0 then
            'areaList[areas] = 0
            'areaList[areas] = newArea
            'areas += 1
        else
            print "Error: Failed to reallocate! "
            sleep
            end 
        end if
    else
        print "Error: can't add 0 as Area"
        sleep
        end
    end if
End Sub

Sub Board.createAreas()	
    if _tileMap <> 0 then
        'areaList = callocate(0,sizeof(Area Ptr))
        'if areaList = 0 then
        '    print "failed to allocate areaList!"
        '    sleep
        '    end
        'end if    
        Dim tilesInAreas as integer = 0
		'Dim nextArea as integer = 1
		For i as integer = 0 to (boardHeight - 1)
			For j as integer = 0 to (boardWidth - 1)
				Dim tp as Tile Ptr = _tileMap->getTile(j,i)
				Dim dp as TileData Ptr = tp->getData()
				if dp <> Null then
					if dp->getArea() = 0 then						
                        Dim size as integer = int(rnd * boardWidth) + 1
                        Dim newArea as Area Ptr = new Area(i,tp,size)
						areaList.addObject(newArea)
                        'addArea(newArea)                        
                        tilesInAreas += newArea->getSize()
                        'else
                        '    print "Area not created: "; areas
                        '    sleep
                        '    end
                        'end if
						'nextArea += 1
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
    'print "start placing random mirrors"
    'print "number of areas: "; areas
    'sleep
    'for i as integer = 0 to areas - 1
    '    areaList[i]->placeRandomMirror()
    'next i
End Sub

Function Board.addTank( _tile as Tile Ptr, _direction as Direction, _tankID as integer ) as Robot ptr
	if _tile <> 0 then
		Dim as Robot ptr newRobot = new Robot( _tankID, _tile, _direction )
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
			if robots(i) <> null then
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

Sub Board.removeTank( _tile as Tile Ptr, _direction as Direction )
End Sub    

' Methods and helper methods related to drawing the board etc.
Sub Board.drawTile()
End Sub

Function Board.getSpriteX(_tile as Tile Ptr) as integer
	if _tile <> 0 then
		return (_tile->getX() * 32 + xOffset)
	end if
	return -1
End Function

Function Board.getSpriteX(_tileX as integer) as integer
	return (_tileX * 32 + xOffset)
End Function

Function Board.getSpriteY(_tile as Tile Ptr) as integer
	if _tile <> 0 then
		return (_tile->getY() * 32 + yOffset)
	end if
	return -1
End Function

Function Board.getSPriteY(_tileY as integer) as integer
	return (_tileY * 32 + yOffset)
End Function

Sub Board.drawBoardBase()
	for i as integer = 0 to (boardHeight - 1)
		for j as integer = 0 to (boardWidth - 1)
			Put (getSpriteX(j), getSpriteY(i)), tileSprites(spriteMap(j,i)), pset
		next j
	next i
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
		'Dim firstTile as Tile Ptr = __robot->getStartTile()
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
		'Circle (endX+16,endY+16), 13, rgb(255,0,255) 'tileSprites(TileSprite.Border_None),pset
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
        cls
        drawBoardBase()
        drawAllMirrors()
        drawTank(robots(i))
        if robots(i) <> 0 then
            robots(i)->findAlternativePaths()
            sleep
        end if    
        'drawBeam(robots(i))
    next i
End Sub

Type MirrorObject
    private:
        _tile as Tile Ptr
        reflectedBeams(2) as Robot ptr
        orientation as Mirror
        orientationFixed as Bool = Bool.False
        tileFixed as Bool = Bool.False
    public:
        Declare Constructor ()
End Type

'--------------
' Init board.
'--------------
Dim w as integer = 3
Dim h as integer = 3
Dim b as Board = Board(w,h)
Cls
Dim xoffset as integer = (640 - (32*w)) \ 2
Dim yoffset as integer = (480 - (32*h)) \ 2
b.setOffset(xoffset,yoffset)
b._draw()
Sleep

System
