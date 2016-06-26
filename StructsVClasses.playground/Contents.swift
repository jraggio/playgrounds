//: Playground - noun: a place where people can play

import Cocoa

class IntClass {
    var value: Int
    init(_ val: Int) { self.value = val }
}

struct IntStruct {
    var value: Int
    init(_ val: Int) { self.value = val }
}

var c1 = IntClass(0)
var c2 = c1
print ("c2 = \(c2)")

print ("c1 = \(c1.value)")
print ("c2 = \(c2.value)")

c2.value = 1
print ("c1 = \(c1.value)")
print ("c2 = \(c2.value)")

var s1 = IntStruct(0)
var s2 = s1
print ("s2 = \(s2)")

print ("s1 = \(s1.value)")
print ("s2 = \(s2.value)")

s2.value = 1
print ("s1 = \(s1.value)")
print ("s2 = \(s2.value)")

// Can a struct include object members?  If so are the references themselves copies?

// If a reference to a method is passed I think this means that the object itself is altered in the method using mutators

// What about changing what the reference points to?  Can it be done?  What happens after the function returns





