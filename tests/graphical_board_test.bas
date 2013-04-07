' test the graphical board with a random generated board.
#include once "../graphical_board.bas"

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
    sleep
    delete gb
end if
delete b
