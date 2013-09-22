#include once "mirror.bas"

enum Direction
    North = 0
    East = 1
    South = 2
    West = 3
end enum

dim shared directionNames(3) as string
directionNames(Direction.North) = "North"
directionNames(Direction.East) = "East"
directionNames(Direction.South) = "South"
directionNames(Direction.West) = "West"

dim shared directionShortNames(3) as string
directionShortNames(Direction.North) = "N"
directionShortNames(Direction.East) = "E"
directionShortNames(Direction.South) = "S"
directionShortNames(Direction.West) = "W"

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
