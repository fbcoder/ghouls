namespace Settings

    ' Constants, must be defined as constants as they are used in type property declarations.
    const maxBoardWidth = 6
    const maxBoardHeight = 6

    ' Other settings, values not assigned here
    dim shared boardsFolder as string
    dim shared defaultBoardWidth as integer
    dim shared defaultBoardHeight as integer

end namespace

Settings.boardsFolder = "boards"
Settings.defaultBoardHeight = 4
Settings.defaultBoardWidth = 4