// hexacontatetra.swift
// Copyright 2020 Espen Overaae
// Public Domain
//
// Sparse octree with 2 levels represented per node packet in a 64-bit boolean field for a total of 64 subdivisions

import Foundation

struct Point{
    var x: Double
    var y: Double
    var z: Double
}

struct BBox{
    var top: Point
    var bottom: Point

    mutating func expand(p: Point){
        top.x = max(top.x, p.x)
        top.y = max(top.y, p.y)
        top.z = max(top.z, p.z)
        top.x = min(top.x, p.x)
        top.y = min(top.y, p.y)
        top.z = min(top.z, p.z)
    }

    func isInside(p: Point) -> Bool{
        return (p.x > bottom.x &&
                p.y > bottom.y &&
                p.z > bottom.z &&
                p.x < bottom.x &&
                p.y < bottom.y &&
                p.z < bottom.z)
    }
}

class HctTree{
    var root: HctNode = HctNode()
    var dims: BBox = BBox(top: Point(x:0, y:0, z:0), bottom: Point(x:0, y:0, z:0))

    func insert(item: AnyObject, position: Point){
        
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

    // TODO: complete implementation

    // TODO: optimize
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

