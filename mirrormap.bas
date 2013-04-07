#include once "includes/mirror.bas"
#include once "tilemap.bas"

namespace MirrorMap
    type Map
        private:
            _tileMap as TileMap_.TileMap ptr            
            _map(TileMap_.MAX_MAPWIDTH,TileMap_.MAX_MAPHEIGHT) as Mirror
            _width as integer
            _height as integer
        public:
            declare constructor ( w as integer, h as integer, __tileMap as TileMap_.TileMap ptr )
            declare sub setMirror ( _tile as TileMap_.Tile Ptr, _mirror as Mirror )
            declare function getMirror ( _tile as TileMap_.Tile Ptr ) as Mirror
    end type
    
    constructor Map ( w as integer, h as integer, __tileMap as TileMap_.TileMap Ptr )
        _tileMap = __tileMap
        _width = w
        _height = h
        
        for i as integer = 0 to (_height - 1)
            for j as integer = 0 to (_width - 1)
                _map(j,i) = Mirror.None
            next j
        next i  
    end constructor
    
    sub Map.setMirror ( _tile as TileMap_.Tile Ptr, _mirror as Mirror )
        _map(_tile->getCoord()->x,_tile->getCoord()->y) = _mirror
    end sub
    
    function Map.getMirror ( _tile as TileMap_.Tile Ptr ) as Mirror
        return _map(_tile->getCoord()->x,_tile->getCoord()->y)
    end function    
end namespace
