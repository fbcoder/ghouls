#include once "includes/mirror.bas"
#include once "tilemap.bas"

NameSpace MirrorMap
    Type Map
        private:
            _tileMap as TileMap_.TileMap Ptr            
            _map(6,6) as Mirror
            _width as integer
            _height as integer
        public:
            Declare Constructor ( w as integer, h as integer, __tileMap as TileMap_.TileMap Ptr)
            Declare Sub setMirror ( _tile as TileMap_.Tile Ptr, _mirror as Mirror )
            Declare Function getMirror ( _tile as TileMap_.Tile Ptr ) as Mirror
    End Type
    
    Constructor Map( w as integer, h as integer, __tileMap as TileMap_.TileMap Ptr)
        _tileMap = __tileMap
        _width = w
        _height = h
        
        for i as integer = 0 to (_height - 1)
            for j as integer = 0 to (_width - 1)
                _map(j,i) = Mirror.None
            next j
        next i  
    End Constructor
    
    Sub Map.setMirror( _tile as TileMap_.Tile Ptr, _mirror as Mirror )
        _map(_tile->getCoord()->x,_tile->getCoord()->y) = _mirror
    End Sub
    
    Function Map.getMirror( _tile as TileMap_.Tile Ptr ) as Mirror
        return _map(_tile->getCoord()->x,_tile->getCoord()->y)
    End Function    
End NameSpace