' -------------------
' Simple Linked List
' fbcoder 2010-2012
' -------------------
#include once "bool.bas"

Namespace MyList

Type ListNode    
    private:
        objectPtr as any ptr = 0
        nextNode as ListNode ptr = 0
        prevNode as ListNode ptr = 0
    public:    
        Declare Constructor (optr as any ptr)    
        Declare Sub debug()
        Declare Function getNext() as ListNode Ptr
        Declare Function getPrev() as ListNode Ptr
        Declare Function getObject() as Any Ptr
        Declare Sub setNext( _nextNode as ListNode ptr )
        Declare Sub setPrev( _prevNode as ListNode ptr )
End Type    

Constructor ListNode(optr as any ptr)
    if optr <> 0 then
        objectPtr = optr
    else
        print "Error: Constructing ListNode with nullpointer! "
        sleep
        end
    end if    
End Constructor

Function ListNode.getNext() as ListNode ptr
    return nextNode
End Function

Function ListNode.getPrev() as ListNode ptr
    return prevNode
End Function

Function ListNode.getObject() as any ptr
    if objectPtr <> 0 then
        return objectPtr
    end if
    print "Error: Can't get empty object from ListNode!"
    sleep
    end
    return 0
End Function

Sub ListNode.setNext( _nextNode as ListNode ptr )
    nextNode = _nextNode
End Sub

Sub ListNode.setPrev( _prevNode as ListNode ptr )    
    prevNode = _prevNode
End Sub

Sub ListNode.debug()
    print "-- Node -- [ "; @this; " ]"
    print "Object   : "; objectPtr
    print "Next     : "; nextNode
    print "Previous : "; prevNode
End Sub

Type List
    private:
        size as Integer = 0
        firstNode as ListNode ptr = 0
    public:        
        Declare Sub addObject(p as any ptr)    
        Declare Sub addNode(nodePtr as ListNode ptr)
        Declare Sub debug ()
        'Declare Sub deleteObjects ()
        Declare Function getSize() as integer
        Declare Function getFirst() as ListNode ptr
        Declare Destructor
End Type

Sub List.addObject(_object as any ptr)
    if _object <> 0 then
        Dim as ListNode ptr newNode = new ListNode(_object)
        if newNode <> 0 then
            if firstNode = 0 then
                firstNode = newNode
                firstNode->setNext(0)
                firstNode->setPrev(0)
            else
                firstNode->setPrev(newNode)
                newNode->setNext(firstNode)
                newNode->setPrev(0)
                firstNode = newNode
            end if
            size += 1
        else
            print "Error: no new Listnode!"
            sleep
            end
        end if
    else
        print "Error: can't create node without object."
        sleep
        end        
    end if    
End Sub

Function List.getSize() as Integer
    return size
End Function

Function List.getFirst() as ListNode ptr
    return firstNode
End Function

Sub List.debug()
    Print "-- List --"
    Dim tempNode as ListNode ptr = firstNode
    Dim counter as integer = 0
    While tempNode <> 0        
        tempNode->debug()
        tempNode = tempNode->getNext()
        counter += 1
        sleep
    Wend
    Print "--"
    Print "Contains "; counter; " elements."
    Print "--"
End Sub    

Destructor List ()
    Dim as ListNode ptr iteratedNode = firstNode    
    While iteratedNode <> 0
        Dim as ListNode ptr nextNode = iteratedNode->getNext()
        delete iteratedNode
        iteratedNode = NextNode
    Wend
End Destructor

End Namespace
