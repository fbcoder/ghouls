' -------------------
' Simple Linked List
' fbcoder 2010-2013
' -------------------
#include once "bool.bas"
#include once "newline.bas"

namespace MyList

Type ListNode    
    private:
        objectPtr as any ptr = 0
        nextNode as ListNode ptr = 0
        prevNode as ListNode ptr = 0
    public:    
        Declare Operator cast() as String
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
        print "Error: Constructing ListNode with null object not allowed!"
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

Operator ListNode.cast() as String
    Dim returnString as String
    returnString &= "-- Node -- [ " & str(@this) & " ]" & NEWLINE
    returnString &= "Object   : " & str(objectPtr) & NEWLINE
    returnString &= "Next     : " & str(nextNode) & NEWLINE
    returnString &= "Previous : " & str(prevNode) & NEWLINE
    return returnString
End Operator

Type List
    private:
        size as Integer = 0
        firstNode as ListNode ptr = 0
        lastNode as ListNode ptr = 0
    public:        
        declare operator cast () as String
        declare sub addObject (p as any ptr)    
        declare sub addObjectTail (p as any ptr)
        declare sub addObjectBefore ( objectBefore as any ptr, objectToAdd as any ptr )
        Declare Sub addNode(nodePtr as ListNode ptr)
        Declare Sub debug ()
        Declare Function getSize () as integer
        Declare Function getFirst () as ListNode ptr
        Declare Function containsObject ( objectPtr as Any Ptr ) as Bool
        Declare Sub addObjectIfNew ( objectPtr as Any Ptr )
        Declare Sub removeObject( objectPtr as Any Ptr )
        Declare Destructor
End Type

' Add object to the head of the list
Sub List.addObject(_object as any ptr)
    if _object <> 0 then
        Dim as ListNode ptr newNode = new ListNode(_object)
        if newNode <> 0 then
            if firstNode = 0 then
                firstNode = newNode
                lastNode = newNode
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

' Add object to the tail.
sub List.addObjectTail(_object as any ptr)
    if _object <> 0 then
        Dim as ListNode ptr newNode = new ListNode(_object)
        if newNode <> 0 then
            if lastNode = 0 then
                firstNode = newNode
                lastNode = newNode
                firstNode->setNext(0)
                firstNode->setPrev(0) 
            else
                lastNode->setNext(newNode)
                newNode->setPrev(lastNode)
                newNode->setNext(0)
                lastNode = newNode
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
end sub

sub List.addObjectBefore ( objectBefore as any ptr, objectToAdd as any ptr )
    if size > 0 then
        dim currentNode as ListNode Ptr = firstNode
        dim newNode as ListNode ptr = 0
        dim foundNode as Bool = Bool.False
        while currentNode <> 0
            if currentNode->getObject() = objectBefore then
                foundNode = Bool.True
                newNode = new ListNode(objectToAdd)
                newNode->setPrev(currentNode->getPrev())
                newNode->setNext(currentNode)
                if currentNode->getPrev() <> 0 then
                    currentNode->getPrev()->setNext(newNode)
                else
                    firstNode = newNode
                end if
                currentNode->setPrev(newNode)
                exit while
            end if
            currentNode = currentNode->getNext()
        wend
        if foundNode = Bool.False then
            print "Error: objectBefore not found in list!"
            sleep
            end
        end if
    else
        print "Error: can't add objectBefore in empty list!"
        sleep
        end
    end if
end sub    

Function List.getSize() as Integer
    return size
End Function

Function List.getFirst() as ListNode ptr
    return firstNode
End Function

Function List.containsObject( objectPtr as Any Ptr ) as Bool
    if objectPtr <> 0 then
        dim currentNode as ListNode Ptr = firstNode
        while currentNode <> 0
            if currentNode->getObject() = objectPtr then
                return Bool.True
            end if
            currentNode = currentNode->getNext()
        wend
    else
        print "Error: can't search for null object in List."
        sleep
        end
    end if
    return Bool.False
End Function

Sub List.addObjectIfNew( objectPtr as Any Ptr )
    if containsObject(objectPtr) = Bool.False then
        addObject(objectPtr)
    end if    
End Sub

Sub List.removeObject( objectPtr as Any Ptr )
	dim removed as Bool = Bool.False
	dim currentNode as ListNode ptr = firstNode
	while currentNode <> 0
		if currentNode->getObject() = objectPtr then
			dim prevNode as ListNode ptr = currentNode->getPrev()
			dim nextNode as ListNode ptr = currentNode->getNext()
			if prevNode <> 0 then
				prevNode->setNext(nextNode)
			Else
				' firstNode must be adjusted
				firstNode = nextNode
			end if
			if nextNode <> 0 then
				nextNode->setPrev(prevNode)
			Else
				' lastNode must be adjusted
				lastNode = prevNode
			end if
			delete currentNode
			removed = Bool.True
			size -= 1
			exit while
		end if
		currentNode = currentNode->getNext()
	wend
	if removed = Bool.False then
		Print "Could not find object in this list and therefore did not delete it."
	end if
End Sub

Sub List.debug()
    Print "-- List --"
    Dim tempNode as ListNode ptr = firstNode
    Dim counter as integer = 0
    While tempNode <> 0        
        'tempNode->debug()
        'print tempNode
        tempNode = tempNode->getNext()
        counter += 1
        sleep
    Wend
    Print "--"
    Print "Contains "; counter; " elements."
    Print "--"
End Sub    

operator List.cast () as string
    dim returnString as string = "-- List --" & NEWLINE
    dim tempNode as ListNode ptr = firstNode
    dim counter as integer = 0
    while tempNode <> 0        
        'tempNode->debug()
        returnString &= *tempNode
        tempNode = tempNode->getNext()
        counter += 1
        'sleep
    wend
    returnString &= "--" & NEWLINE
    returnString &= "Contains " & str(counter) & " elements." & NEWLINE
    returnString &= "--" & NEWLINE
    return returnString    
end operator

Destructor List ()
    Dim as ListNode ptr iteratedNode = firstNode    
    While iteratedNode <> 0
        Dim as ListNode ptr nextNode = iteratedNode->getNext()
        delete iteratedNode
        iteratedNode = NextNode
    Wend
End Destructor

'-------------------
' The List Iterator
'-------------------
Type Iterator
    private:
        _list as List Ptr
        currentNode as ListNode Ptr
    public:
        Declare Constructor ( __list as List Ptr )
        Declare Function getNextObject() as any ptr
        Declare Function hasNextObject() as Bool
End Type    

Constructor Iterator( __list as List Ptr )
    if __list <> 0 then
        _list = __list
        currentNode = _list->getFirst()
    else    
        print "Can't construct iterator without a list!"
        sleep
        end
    end if    
End Constructor

Function Iterator.getNextObject() as any ptr        
    if currentNode <> 0 then
        Dim thisNode as ListNode Ptr = currentNode
        ' move iterator to next node
        currentNode = currentNode->getNext()
        ' return the object in old currentNode
        if thisNode->getObject() <> 0 then
            return thisNode->getObject()
        else
            print "Error: Node must have object!"
            sleep
            end
        end if
    end if
    return 0
End Function

Function Iterator.hasNextObject() as Bool
    if currentNode <> 0 then
        if currentNode->getObject() <> 0 then
            return Bool.True
        else
            print "Error: Node must have object!"
            sleep
            end
        end if
    end if
    return Bool.False
End Function

end namespace
