#include once "../board.bas"

Dim b as Board ptr = new Board(0,0)
b->solve()
delete b
sleep
