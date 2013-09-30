#include once "../includes/list.bas"

Dim thisList As MyList.List

' Create array of 10 integer pointers
Dim elements(10) As Integer Ptr

For i As Integer = 0 To 3
	elements(i) = New Integer(i)
	thisList.addObject(elements(i))
Next i

' Debug list
Print thisList
Sleep

thislist.removeObject(elements(3))
Print thisList
Sleep

' Clean up
For i As Integer = 0 To 3
	Delete elements(i)
Next i


 