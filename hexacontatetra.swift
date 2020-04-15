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
    var data: AnyObject?
}

