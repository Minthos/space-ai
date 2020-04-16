// hexacontatetra.swift
// Copyright 2020 Espen Overaae
// Public Domain
//
// Sparse octree with 2 levels represented per node packed in a 64-bit boolean field for a total of 64 subdivisions

import Foundation

// round up to nearest power of 2
func potimizeDouble(_ number: Double) -> Double{
    if(number.binade == number){
        return number
    } else {
        return number.binade * 2
    }
}

struct BBox{
    var top: Point
    var bottom: Point

    // returns a (1/4, 1/4, 1/4) size section of a bounding box.
    // Which of the 64 possible subsections is indicated by the argument "index"
    func selectQuadrant(_ index: UInt8) -> BBox{
        let xindex = Double(index & 0x03)
        let yindex = Double((index >> 2) & 0x03)
        let zindex = Double((index >> 4) & 0x03)
        var selection = BBox(top: top, bottom: bottom)
        let spanx = (selection.top.x - selection.bottom.x) / 4
        let spany = (selection.top.y - selection.bottom.y) / 4
        let spanz = (selection.top.z - selection.bottom.z) / 4
        selection.top.x -= spanx * (3 - xindex)
        selection.bottom.x += spanx * xindex
        selection.top.y -= spany * (3 - yindex)
        selection.bottom.y += spany * yindex
        selection.top.z -= spanz * (3 - zindex)
        selection.bottom.z += spanz * zindex
        return selection
    }

    mutating func expandTo(_ point: Point){
        top.x = max(top.x, point.x)
        top.y = max(top.y, point.y)
        top.z = max(top.z, point.z)
        bottom.x = min(bottom.x, point.x)
        bottom.y = min(bottom.y, point.y)
        bottom.z = min(bottom.z, point.z)
    }

    // round each coordinate up to nearest power of 2
    mutating func potimize(){
        top.potimize()
        bottom.potimize()
    }

    func contains(_ point: Point) -> Bool{
        return (point.x >= bottom.x &&
                point.y >= bottom.y &&
                point.z >= bottom.z &&
                point.x <= top.x &&
                point.y <= top.y &&
                point.z <= top.z)
    }

    func intersects(bbox: BBox) -> Bool{
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

    init(initialSize: Double){
        let extent = potimizeDouble(initialSize)
        self.dims = BBox(top: Point(extent, extent, extent), bottom:(Point(-extent, -extent, -extent)))
    }

    func index2bit(top: Double, bottom: Double, point: Double) -> UInt8{
        if (top - point) > 3 * (point - bottom){
            return 0
        } else if (top - point) > (point - bottom){
            return 1
        } else if 3 * (top - point) > (point - bottom){
            return 2
        } else {
            return 3
        }
    }

    func index6bit(top: Point, bottom: Point, point: Point) -> UInt8{
        return index2bit(top: top.x, bottom: bottom.x, point: point.x) |
                index2bit(top: top.y, bottom: bottom.y, point: point.y) << 2 |
                index2bit(top: top.z, bottom: bottom.z, point: point.z) << 4
    }

    func resolve(_ position: Point) -> [UInt8]{
        var rax: [UInt8] = []
        var box = dims
        // 26 because Double only has 53 bits of precision. Should break out earlier if possible. (TODO)
        for _ in 0..<26 {
            let quadrant = index6bit(top: box.top, bottom:box.bottom, point:position)
            rax.append(UInt8(quadrant))
            box = box.selectQuadrant(quadrant)
            if !box.contains(position){
                print("!!! ERROR! point not inside bounding box at HctTree.resolve(position: \(position))")
            }
        }
        return rax
    }

    func addLayer(){
        
    }

    func insert(item: AnyObject, position: Point){
        if !dims.contains(position){
            // TODO: panic! just kidding.. just make the tree deeper
            // btw the following is not the complete solution, it's also necessary to create new nodes:
            let absElements = position.xyz().map({ abs($0) })
            var extent = absElements.reduce(0, { a, b in max(a, b) })
            extent = potimizeDouble(extent)
            self.dims = BBox(top: Point(extent, extent, extent), bottom:(Point(-extent, -extent, -extent)))
        }
       
        root.data.append(item)
        numItems += 1
    }

    func remove(item: AnyObject, position: Point){
        if let i = root.data.firstIndex(where: { $0 === item } ){
            root.data.remove(at: i)
            numItems -= 1
        } else {
            print("Can't remove element that isn't there!")
            // TODO: add more functionality
        }
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
   
    // expects a bit field with a single bit set to high
    // returns the index of that bit
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
    
    // returns an array of numbers indicating which bit in the bit field represents
    // the child node at the same index in the children array
    //
    // example:
    // bit_field 0000 0000 0000 0000 0001 0000 0001 0001
    // children [node, node, node]
    // decode: [0,4,12]
    // then you can zip decode with children and get something like [(0, node), (4, node), (12, node)]
    // TODO: verify that the order of bits I described above matches what the code produces, to avoid bugs
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

    // returns the number of children by counting high bits in the bit field
    // a bit useless I suppose when one can just query the length of the children array
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

