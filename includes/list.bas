' -------------------
' Simple Linked List
' fbcoder 2010-2012
' -------------------
#include once "bool.bas"

Namespace MyList

Type ListNode    
    objectPtr as any ptr = 0
    nextNode as ListNode ptr = 0
    prevNode as ListNode ptr = 0
    Declare Constructor ()
    Declare Constructor (optr as any ptr)
    Declare Sub debug()
End Type    

Constructor ListNode(optr as any ptr)
    objectPtr = optr
End Constructor

Sub ListNode.debug()
    print "-- Node -- [ "; @this; " ]"
    print "Object   : "; objectPtr
    print "Next     : "; nextNode
    print "Previous : "; prevNode
End Sub

Type List
    private:
        size as Integer = 0
    public:
        firstNode as ListNode ptr = 0
        Declare Sub addObject(p as any ptr)    
        Declare Sub addNode(nodePtr as ListNode ptr)
        Declare Sub removeNode(p as ListNode ptr)
        Declare Sub debug ()
        Declare Function getSize() as integer
        Declare Function removeAndGetNode() as ListNode ptr
        Declare Destructor
End Type

Sub List.addObject(object as any ptr)
    Dim as ListNode ptr newNode = new ListNode(object)
    if firstNode = 0 then
        firstNode = newNode
        firstNode->nextNode = 0
        firstNode->prevNode = 0
    else
        firstNode->prevNode = newNode
        newNode->nextNode = firstNode
        newNode->prevNode = 0
        firstNode = newNode
    end if
    size += 1
End Sub

Sub List.addNode(nodePtr as ListNode ptr)
    if firstNode = 0 then
        firstNode = nodePtr
        firstNode->nextNode = 0
        firstNode->prevNode = 0
    else
        firstNode->prevNode = nodePtr
        nodePtr->nextNode = firstNode
        nodePtr->prevNode = 0
        firstNode = nodePtr
    end if
    size += 1
End Sub

Sub List.removeNode(p as ListNode ptr)
    if firstNode <> 0 then
        if p = firstNode then
            firstNode = p->nextNode
            if firstNode <> 0 then firstNode->prevNode = 0
        else
            p->prevNode->nextNode = p->nextNode
            if p->nextNode <> 0 then p->nextNode->prevNode = p->prevNode
        end if    
    end if
    size -= 1
End Sub

Function List.removeAndGetNode() as ListNode ptr    
    if firstNode <> 0 then
        Dim as ListNode ptr returnNode = firstNode       
        if firstNode->nextNode = 0 then
            firstNode = 0
        else
            firstNode->nextNode->prevNode = 0
            firstNode = firstNode->nextNode
        end if
        size -= 1
        return returnNode
    end if
    return 0    
End Function

Function list.getSize() as Integer
    return size
End Function

Sub List.debug()
    Print "-- List --"
    Dim tempNode as ListNode ptr = firstNode
    Dim counter as integer = 0
    While tempNode <> 0        
        tempNode->debug()
        tempNode = tempNode->nextNode
        counter += 1
    Wend
    Print "--"
    Print "Contains "; counter; " elements."
    Print "--"
End Sub    

Destructor List ()
    Dim as ListNode ptr iteratedNode = firstNode    
    While iteratedNode <> 0
        Dim as ListNode ptr nextNode = iteratedNode->nextNode
        delete iteratedNode
        iteratedNode = NextNode
    Wend
End Destructor

Type Iterator
    private:
        _list as List
        lastNode as ListNode ptr = 0
    public: 
        Declare Constructor( __list as List )
        Declare Function getNextObject() as any ptr
        Declare Function hasNextObject() as Bool
        Declare Function getObjectAtIndex( i as integer ) as any ptr
        Declare Sub resetList()
End Type

Constructor Iterator( __list as List )
    _list = __list
    lastNode = _list.firstNode
End Constructor

Function Iterator.getNextObject() as any ptr
    Dim returnPtr as any ptr = 0
    if lastNode <> 0 then
        returnPtr = lastNode->objectPtr
        lastNode = lastNode->nextNode        
    end if
    return returnPtr
End Function

Function Iterator.getObjectAtIndex( i as integer ) as any ptr
    if i < _list.getSize() then
        Dim listIndex as integer = 0
        Dim thisNode as ListNode ptr = _list.firstNode
        while thisNode <> 0
            'print listIndex
            if listIndex = i then
                return thisNode->objectPtr
            end if    
            listIndex += 1
            thisNode = thisNode->nextNode
        wend    
    end if
    return 0
End Function

Function Iterator.hasNextObject() as Bool
    if lastNode <> 0 then
        Return Bool.True
    end if    
    Return Bool.False
End Function

Sub Iterator.resetList()
    lastNode = _list.firstNode
End Sub

' End Namespace MyList
End Namespace
