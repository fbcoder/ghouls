Enum Direction
    North = 0
    East = 1
    South = 2
    West = 3
End Enum

Dim Shared directionNames(3) as String
directionNames(Direction.North) = "North"
directionNames(Direction.East) = "East"
directionNames(Direction.South) = "South"
directionNames(Direction.West) = "West"

Dim Shared directionShortNames(3) as String
directionShortNames(Direction.North) = "N"
directionShortNames(Direction.East) = "E"
directionShortNames(Direction.South) = "S"
directionShortNames(Direction.West) = "W"
