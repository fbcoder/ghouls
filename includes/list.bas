' ------------------
' Simple Linked List
' fbcoder 2010
' ------------------

Namespace MyList

Type ListNode
    objectPtr as any ptr = 0
    nextNode as ListNode ptr = 0
    prevNode as ListNode ptr = 0
    Declare Constructor ()
    Declare Constructor (optr as any ptr)
End Type    

Constructor ListNode(optr as any ptr)
    objectPtr = optr
End Constructor

Type List
    firstNode as ListNode ptr = 0
    declare sub addObject(p as any ptr)    
    declare sub addNode(nodePtr as ListNode ptr)
    declare sub removeNode(p as ListNode ptr)
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
        return returnNode
    end if
    return 0
End Function 

Destructor List ()
    Dim as ListNode ptr iteratedNode = firstNode    
    While iteratedNode <> 0
        Dim as ListNode ptr nextNode = iteratedNode->nextNode
        delete iteratedNode
        iteratedNode = NextNode
    Wend
End Destructor

End Namespace