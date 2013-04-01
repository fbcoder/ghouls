' ------
' Solver
' ------

Type Solver
    private:
        _areaMap as Area_.Map Ptr
        _mirrorMap
        possibilityMap
        fileName as String
        debugToFile as Bool
                    
        _pathTree as PathTree Ptr
        
        Sub solveRoute( _tank as Robot Ptr )
    public:
        Declare Constructor(__areaMap as Area_.Map Ptr, )                        
End Type

Sub Solver.solveRoute( _tank as Robot Ptr )
    Dim startTile as TileMap_.Tile Ptr
    Dim startDirection as Direction
    Dim endTile as TileMap_.Tile Ptr
    Dim endDirection as Direction    
End Sub    

