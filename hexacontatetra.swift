// hexacontatetra.swift
// Copyright 2020 Espen Overaae
// Public Domain
//
// Sparse octree with 2 levels represented per node packet in a 64-bit boolean field for a total of 64 subdivisions

import Foundation



class HctNode{
    static var lookupTable = [Int](repeating: 0, count: 256)
    static func initialize() {
        for i in 0..<256{
            lookupTable[i] = (i & 1) + lookupTable[i / 2];
        }
    }

    var bit_field: UInt64 = 0
    var children: [HctNode] = []
    var data: [AnyObject] = []
    
    func insert(item: AnyObject, location: (Double, Double, Double)){
        // how to convert location to spatial tree index?
    }
/* // Swift can't typecheck this damn thing
    func count_bits_lookup_table() -> Int{
        let v = bit_field
        var c = lookupTable[v & 0xff] + 
            lookupTable[(v >> 8) & 0xff] + 
            lookupTable[(v >> 16) & 0xff] + 
            lookupTable[(v >> 24) & 0xff] + 
            lookupTable[(v >> 32) & 0xff] + 
            lookupTable[(v >> 40) & 0xff] + 
            lookupTable[(v >> 48) & 0xff] + 
            lookupTable[v >> 56]
        return c
    }
*/
    func count_bits_wegner_kernighan() -> Int {
        var v = bit_field
        var c: Int = 0
        while v != 0{
            v &= v - 1; // clear the least significant bit set
            c += 1
        }
        return c
    }

    // TODO: complete implementation

    // TODO: optimize
}

