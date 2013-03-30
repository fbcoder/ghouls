#include once "includes/list.bas"
#include once "includes/mirror.bas"
#include once "includes/newline.bas"
#include once "tilemap.bas"
#include once "mirrormap.bas"

NameSpace Area_

' Forward for Map
Type MapPtr as Map Ptr

'------
' Area
'------
Type Area
    private:        
        _map as MapPtr
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
        Declare Constructor ( _id as integer, startTile as TileMap_.Tile Ptr, maxSize as integer, __map as MapPtr  )
        Declare Sub placeRandomMirror()
        Declare Sub debug()
        Declare Sub debugList()
        Declare Function getSize() as integer
End Type

Constructor Area ( _id as integer, startTile as TileMap_.Tile Ptr, _maxSize as integer, __map as MapPtr )
    id = _id
    _map = __map
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

Type Map
    private:
        _tileMap as TileMap_.TileMap Ptr
        _mirrorMap as MirrorMap.Map Ptr
        areaList as MyList.List
        _map(6,6) as Area Ptr
        _width as integer
        _height as integer
        Declare Sub buildMap()
        Declare Sub placeRandomMirrors()
    public:
        Declare Constructor ( w as integer, h as integer, __tileMap as TileMap_.TileMap Ptr, __mirrorMap as MirrorMap.Map Ptr)
        Declare Destructor ()
        Declare Sub setArea ( _tile as TileMap_.Tile Ptr , _area as Area Ptr )
        Declare Function getArea ( _tile as TileMap_.Tile Ptr ) as Area Ptr
        Declare Sub setMirror( _tile as TileMap_.Tile Ptr, _mirror as Mirror )
        Declare Function toString() as String
End Type

Constructor Map ( w as integer, h as integer, __tileMap as TileMap_.TileMap Ptr, __mirrorMap as MirrorMap.Map Ptr )
    if __tileMap <> 0 then
        _tileMap = __tileMap
    else
        print "Error: null __tileMap"
        sleep
        end
    end if

    if __mirrorMap <> 0 then
        _mirrorMap = __mirrorMap
    else
        print "Error: null __mirrorMap"
        sleep
        end
    end if
        
    _width = w
    _height = h    
    
    for i as integer = 0 to (_height - 1)
        for j as integer = 0 to (_width - 1)
            _map(j,i) = 0
        next j
    next i    
    
    buildMap()
    placeRandomMirrors()
End Constructor

Destructor Map () 
End Destructor

' Build the areas
Sub Map.buildMap()
    if _tileMap <> 0 then       
        Dim tilesInAreas as integer = 0
        Dim areaID as integer = 0
		For i as integer = 0 to (_height - 1)
			For j as integer = 0 to (_width - 1)
				Dim tp as TileMap_.Tile Ptr = _tileMap->getTile(j,i)
				'Dim dp as TileData Ptr = tp->getData()
				if tp <> 0 then
					if getArea(tp) = 0 then						
                        Dim size as integer = int(rnd * _width) + 1
                        areaID += 1
                        Dim newArea as Area Ptr = new Area(areaID,tp,size,@this)
						areaList.addObject(newArea)
                        tilesInAreas += newArea->getSize()
					end if
				end if
			Next j
		Next i
        ' check if all tiles have an area
        if tilesInAreas <> _width * _height then
            print "Error: Too few tiles in areas. : "; tilesInAreas
            sleep
            end
        end if    
	end if
End Sub

Sub Map.placeRandomMirrors()
    Dim thisNode as MyList.ListNode ptr = areaList.getFirst()
	While thisNode <> 0
        Dim areaPtr as Area Ptr = thisNode->getObject()
		areaPtr->placeRandomMirror()
        thisNode = thisNode->getNext()
	Wend
End Sub

Sub Map.SetArea( _tile as TileMap_.Tile Ptr, _area as Area Ptr )
    if _tile <> 0 and _area <> 0 then
        _map(_tile->getCoord()->x,_tile->getCoord()->y) = _area
    else
        print "Error: Can't set Area, _tile or _area is empty!"
        sleep
        end
    end if 
End Sub    

Function Map.getArea( _tile as TileMap_.Tile Ptr ) as Area Ptr
    if _tile <> 0 then
        return _map(_tile->getCoord()->x,_tile->getCoord()->y)
    end if
    return 0
End Function

Sub Map.setMirror( _tile as TileMap_.Tile Ptr, _mirror as Mirror )
    _mirrorMap->setMirror(_tile,_mirror)
End Sub

Function Map.toString() as String
    Dim returnString as String = ""
    for i as integer = 0 to (_height - 1)
        Dim coordLine as String = "    "
        if i = 0 then
            for j as integer = 0 to (_width - 1)
                coordLine &= " " & str(j) & "  "
            next j    
            returnString &= coordLine & NEWLINE
        end if        
        Dim line1 as String = ""        
        Dim line2 as String = ""
        Dim line3 as String = ""
        for j as integer = 0 to (_width - 1)
            Dim n as Bool = Bool.False
            Dim e as Bool = Bool.False
            Dim celBody as String = "   "
            Dim _tile as TileMap_.Tile Ptr = _tileMap->getTile(j,i)
            if _mirrorMap->getMirror(_tile) = Mirror.NE_SW then celBody = " / "
            if _mirrorMap->getMirror(_tile) = Mirror.NW_SE then celBody = " \ "            
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
        returnString &= "   " & line1 & NEWLINE
        returnString &= " " & str(i) & " " & line2 & NEWLINE
        if line3 <> "" then
            returnString &= "   " & line3 & NEWLINE
        end if        
    next i    
    return returnString
End Function

' ---------------------------------------------------------------------------
' Methods from ** Area ** Defined here because it needs methods from Map
' ---------------------------------------------------------------------------
Sub Area.addTiles( _tile as TileMap_.Tile Ptr, fromTile as TileMap_.Tile Ptr, s as Integer )
    'print "Area now has size: "; s
    if _tile <> 0 and tileList.getSize() < maxSize then
        'Dim _data as TileData Ptr = _tile->getData()
        if _map <> 0 then            
            if _map->getArea(_tile) = 0 then
                size += 1
                tileList.addObject(_tile)
                _map->setArea(_tile,@this)
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
            print "Error: No Area Map defined!"
            sleep
            end
        end if
    end if
End Sub

Sub Area.placeRandomMirror( )
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
                    _map->setMirror(tp,originalMirrorType)
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

End NameSpace