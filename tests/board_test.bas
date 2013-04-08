#include once "../board.bas"

Dim b as Board ptr = new Board(4,4)
b->solve()
delete b
sleep
