#include once "graphical_board.bas"

' -------------
' Declare loops
' -------------
declare sub mainLoop ()
declare sub puzzleLoop ( gb as GraphicalBoard ptr )
declare sub menuLoop ()
declare function getSolvableBoard ( w as integer, h as integer ) as Board ptr

'---------------------
' Create Board
'---------------------
function getSolvableBoard ( w as integer, h as integer ) as Board ptr            
    ' Try at most 10 times to get a board with a unique solution.
    for i as integer = 0 to 9
        dim b as Board Ptr = new Board(w,h)
        dim solvable as Bool = b->solve()
        if solvable = Bool.True then        
            return b
        end if       
        delete b    
    next i
    
    return 0
end function

'---------------------------------
' The loop for handling a puzzle.
'---------------------------------
sub puzzleLoop ( gb as GraphicalBoard ptr )
    if gb <> 0 then
        Dim k as string = ""
        Dim mouseClicked as Bool = Bool.False
        while k <> chr(27)
            k = inkey
            Dim mouseX as integer
            Dim mouseY as integer
            Dim mouseButton as integer
            getMouse mouseX, mouseY,,mouseButton
            if mouseButton and &b001 then
                if mouseClicked = Bool.False then                
                    mouseClicked = Bool.True
                end if                        
            else
                if mouseClicked = Bool.True then
                    'print "click"
                    gb->handleMouseClick(mouseX,mouseY)
                    mouseClicked = Bool.False
                end if
            end if            
            sleep 1,1
        wend    
    end if
end sub

'--------------
' The MainLoop
'--------------
sub mainLoop ()
    ' Init Graphics mode
    screenres 640,480,32
    
    dim b as Board Ptr = getSolvableBoard(6,4)
    if b <> 0 then
        dim gb as GraphicalBoard ptr = new GraphicalBoard(b)
        if gb <> 0 then
            cls
            gb->_draw()
            puzzleLoop(gb)
            delete gb
        end if    
        delete b
    end if    
end sub

mainLoop()

System
