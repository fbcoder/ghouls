' ***
' MirrorPlacementMap or Possibility Map, notes which mirrors are possible for each tile
' ***
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

' ***
' Initialize the map with all tiles marked as possible for each type of mirror.
' ***
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