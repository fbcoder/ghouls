#include once "graphical_board.bas"

'Declare mainloop
declare sub mainLoop ( gb as GraphicalBoard ptr )

'---------------------------------------------
' Init Graphics mode and the graphical board
'---------------------------------------------
screenres 640,480,32

dim w as integer = 6
dim h as integer = 4
cls
dim xoffset as integer = (640 - (32*w)) \ 2
dim yoffset as integer = (480 - (32*h)) \ 2
dim b as Board Ptr = new Board(w,h)
dim solvable as Bool = b->solve()
if solvable = Bool.True then
    dim gb as GraphicalBoard ptr = new GraphicalBoard(xoffset,yoffset,b)
    gb->_draw()
    mainloop(gb)
    delete gb
end if
delete b

'--------------
' The MainLoop
'--------------
sub mainLoop ( gb as GraphicalBoard ptr )
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

System
