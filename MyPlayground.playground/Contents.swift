//: Playground - noun: a place where people can play

import Cocoa

//var str = "Hello, playground"
//
//
//print (4 % 3)
//
//print (-4 % 3)
//
//print (-4 % 3.1)
//
//print (5.3 % 3)
//
//print (String(format: "%0.2g", 6.7 % 3.3))
//
//print (4 % -3)

class Test
{
    func test(a : String) -> NSString {
        return a;
    }
    func test(a : UInt) -> NSString {
        return "{\(a)}"
    }
}

Test().test("Foo") // "Foo"
Test().test(123) // "{123}"







