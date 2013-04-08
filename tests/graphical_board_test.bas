' test the graphical board with a random generated board.
#include once "../graphical_board.bas"

screenres 640,480,32
cls

dim w as integer = 6
dim h as integer = 4
dim b as Board Ptr = new Board(w,h)
dim solvable as Bool = b->solve()
if solvable = Bool.True then
    dim gb as GraphicalBoard ptr = new GraphicalBoard(b)
    gb->_draw()
    sleep
    delete gb
end if
delete b
