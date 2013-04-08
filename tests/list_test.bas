#include once "../includes/list.bas"

randomize timer

dim thisList as MyList.List

'---------------------------
' Test sorting on insertion
'---------------------------
for i as integer = 0 to 9
    dim intToAdd as integer ptr = new integer( int(rnd * 10) + 1 )
    print *intToAdd; ",";
    dim addedToList as Bool = Bool.False
    dim thisIterator as MyList.Iterator ptr = new MyList.Iterator(@thisList)
    while thisIterator->hasNextObject() = Bool.True
        dim as Integer ptr thisInt = thisIterator->getNextObject()
        if *intToAdd >= *thisInt then
            thisList.addObjectBefore(thisInt,intToAdd)
            addedToList = Bool.True
            delete thisIterator
            exit while
        end if
    wend
    delete thisIterator
    if addedToList = Bool.False then
        thisList.addObjectTail(intToAdd) 
    end if
next i

print
dim thisIterator as MyList.Iterator ptr = new MyList.Iterator(@thisList)
while thisIterator->hasNextObject() = Bool.True
    dim as Integer ptr thisInt = thisIterator->getNextObject()    
    print *thisInt; ",";
    delete thisint
wend
delete thisIterator

sleep

system
