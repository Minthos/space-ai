// hexacontatetra.swift
// Copyright 2020 Espen Overaae
// Public Domain
//
// Sparse octree with 2 levels represented per node packet in a 64-bit boolean field for a total of 64 subdivisions

import Foundation

// round up to nearest power of 2
func potimizeDouble(_ number: Double) -> Double{
    if(number.binade == number){
        return number
    } else {
        return number.binade * 2
    }
}

struct Point{
    var x: Double
    var y: Double
    var z: Double

    init(_ x: Double, _ y: Double, _ z: Double){
        self.x = x
        self.y = y
        self.z = z
    }

    // round each coordinate up to nearest power of 2
    mutating func potimize(){
        x = potimizeDouble(x)
        y = potimizeDouble(y)
        z = potimizeDouble(z)
    }
}

struct BBox{
    var top: Point
    var bottom: Point

    mutating func expandTo(_ point: Point){
        top.x = max(top.x, point.x)
        top.y = max(top.y, point.y)
        top.z = max(top.z, point.z)
        top.x = min(top.x, point.x)
        top.y = min(top.y, point.y)
        top.z = min(top.z, point.z)
    }

    // round each coordinate up to nearest power of 2
    mutating func potimize(){
        top.potimize()
        bottom.potimize()
    }

    func contains(_ point: Point) -> Bool{
        return (point.x > bottom.x &&
                point.y > bottom.y &&
                point.z > bottom.z &&
                point.x < top.x &&
                point.y < top.y &&
                point.z < top.z)
    }

    func intersects(_ bbox: BBox) -> Bool{
        return ((bbox.bottom.x <= top.x && bbox.top.x >= bottom.x) &&
                (bbox.bottom.y <= top.y && bbox.top.y >= bottom.y) &&
                (bbox.bottom.z <= top.z && bbox.top.z >= bottom.z))
    }
}

// TODO: complete implementation
// TODO: optimize
class HctTree{
    var numItems: Int = 0
    var root: HctNode = HctNode()
    var dims: BBox = BBox(top: Point(0, 0, 0), bottom: Point(0, 0, 0))

    func insert(item: AnyObject, position: Point){
        if !dims.contains(position){
            // TODO: panic! just kidding.. add more levels of the tree
        }
        
    }

    func remove(item: AnyObject, position: Point){

    }

    func relocate(item: AnyObject, currentPosition: Point, newPosition: Point){
        remove(item: item, position:currentPosition)
        insert(item: item, position:newPosition)
    }

    func lookup(region: BBox) -> [AnyObject] {
        return []
    }

}

class HctNode{
    var bit_field: UInt64 = 0
    var children: [HctNode] = []
    var data: [AnyObject] = []
    
    func whichBit(input: UInt64) -> Int {
        let masks: [UInt64] = [
            0xaaaaaaaaaaaaaaaa,
            0xcccccccccccccccc,
            0xf0f0f0f0f0f0f0f0,
            0xff00ff00ff00ff00,
            0xffff0000ffff0000,
            0xffffffff00000000
        ]

        var index = 0
        var i = 0
        while i < masks.count {
            if ((input & masks[i]) != 0) {
                index += (1 << i)
            }
            i += 1
        }
        return index
    }

    func decode() -> [Int] {
        var v = bit_field
        var results: [Int] = []
        while v != 0{
            let prev = v
            v &= v - 1; // clear the least significant bit set
            let diff = v ^ prev
            results.append(whichBit(input: diff))
        }
        return results
    }

    func count_bits() -> Int {
        var v = bit_field
        var c: Int = 0
        while v != 0{
            v &= v - 1; // clear the least significant bit set
            c += 1
        }
        return c
    }
}

