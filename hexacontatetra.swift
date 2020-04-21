// hexacontatetra.swift
// Copyright 2020 Espen Overaae
// Public Domain
//
// Sparse octree with 2 levels represented per node packed in a 64-bit boolean field for a total of 64 subdivisions

import Foundation

// MAXDEPTH is 26 because Double only has 53 bits of precision and each level represents 2 bits of spatial resolution
let MAXDEPTH = 26
let BINSIZE = 1024  // I arrived at this number by measuring the performance of different values. I'm surprised at how large
                    // it is. That suggests that the octree structure is probably very inefficient. I have work to do.
                    // Hopefully with faster tree search the optimal value for this number will be lower.

// round up to nearest power of 2
func potimizeDouble(_ number: Double) -> Double{
    if(number.binade == number){
        return number
    } else {
        return number.binade * 2
    }
}

func hexString(_ number: UInt64) -> String {
    return String(format: "%llx", number)
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
        let spanx = (selection.top.x - selection.bottom.x) * 0.25
        let spany = (selection.top.y - selection.bottom.y) * 0.25
        let spanz = (selection.top.z - selection.bottom.z) * 0.25
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
        let result = (point.x >= bottom.x &&
                point.y >= bottom.y &&
                point.z >= bottom.z &&
                point.x <= top.x &&
                point.y <= top.y &&
                point.z <= top.z)
        //if !result{
        //    print("point: \(point.scientific) bbox: \(self.scientific) contained: \(result)")
        //}
        return result
    }

    func intersects(bbox: BBox) -> Bool{
        return ((bbox.bottom.x <= top.x && bbox.top.x >= bottom.x) &&
                (bbox.bottom.y <= top.y && bbox.top.y >= bottom.y) &&
                (bbox.bottom.z <= top.z && bbox.top.z >= bottom.z))
    }

    var scientific: String {
        return "BBox(top: \(top.scientific), bottom: \(bottom.scientific))"
    }

}

struct HctItem<T: AnyObject>{
    let data: T
    let position: Point
}

            /*
            let absElements = position.xyz().map({ abs($0) })
            var extent = absElements.reduce(0, { a, b in max(a, b) })
            extent = potimizeDouble(extent)
            self.dims = BBox(top: Point(extent, extent, extent), bottom:(Point(-extent, -extent, -extent)))
            */


// TODO: complete implementation
// TODO: optimize
class HctTree<T: AnyObject>{
    var numItems: Int = 0
    var root: HctNode<T> = HctNode<T>()
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
        // MAXDEPTH is 26 because Double only has 53 bits of precision. Should break out earlier if possible. (TODO)
        for _ in 0..<MAXDEPTH {
            let quadrant = index6bit(top: box.top, bottom:box.bottom, point:position)
            rax.append(UInt8(quadrant))
            box = box.selectQuadrant(quadrant)
            //if !box.contains(position){
            //    print("!!! ERROR! point not inside bounding box at HctTree.resolve(position: \(position))")
            //}
        }
        return rax
    }

    func insert(item: T, position: Point){
        if !dims.contains(position){
            print("PANIC! attempting to insert object outside the bounds of the spatial tree: \(position)")
            assert(false)
        }
        let path = resolve(position)
        var leaf = root
        var depth = 0

        while(true){
            if(leaf.bit_field == 0){
                leaf.data.append(HctItem(data: item, position: position))
                // max one item per leaf node unless we are at max depth
                if(leaf.data.count > BINSIZE && depth < MAXDEPTH){
                    leaf.subdivide(depth: depth, tree: self)
                }
                numItems++
                return
            }

            // descend deeper in the tree
            let index = Int(path[depth])
            if(leaf.bit_field & (1 << index) != 0){
                let decoded = leaf.decode()
                for i in 0..<decoded.count{
                    if(decoded[i] == index){
                        leaf = leaf.children[i]
                        break
                    }
                }
            } else {
                let newNode = HctNode<T>()
                leaf.bit_field |= (1 << index)
                let decoded = leaf.decode()
                for i in 0..<decoded.count{
                    if(decoded[i] == index){
                        leaf.children.insert(newNode, at: i)
                        leaf = newNode
                        break
                    }
                }
            }
            depth++
        }
    }

    func remove(item: T, position: Point){
        let path = resolve(position)
        var prev: HctNode<T>? = nil
        var leaf = root
        var depth = 0

        if(root.bit_field == 0){
            let before = root.data.count
            root.data.removeAll(where: { $0.data === item })
            numItems--
            assert(root.data.count == before - 1)
            return
        }

        while(true){
            // descend deeper in the tree
            let index = Int(path[depth])
            if(leaf.bit_field & (1 << index) != 0){
                let decoded = leaf.decode()
                for i in 0..<decoded.count{
                    if(decoded[i] == index){
                        prev = leaf
                        leaf = leaf.children[i]
                        let before = leaf.data.count
                        if(before > 0){
                            leaf.data.removeAll(where: { $0.data === item })
                            if(leaf.data.count == 0){
                                prev!.children.remove(at: i)
                                prev!.bit_field ^= (1 << index)
                            }
                            numItems--
                            return
                        }
                    }
                }
            } else {
                print("!!! Error! pathing failed in HctTree.remove!")
            }
            depth++
        }
    }

    func relocate(item: T, from: Point, to: Point){
        let before = numItems
        if let ship = item as? Ship{
            assert(ship.positionCartesian == from)
        }
        remove(item: item, position:from)
        assert(numItems == before - 1)
        insert(item: item, position:to)
        assert(numItems == before)
    }

    func values() -> [T] {
        return lookup(region: dims)
    }

    func lookup(region: BBox) -> [T] {
        var results: [T] = []
        descend(into: root, with: dims, region: region, results: &results)
        return results
    }

    func descend(into: HctNode<T>, with: BBox, region: BBox, results: inout [T]) {
        if(into.bit_field != 0){
            let decoded = into.decode()
            for i in 0..<decoded.count{
                let q = with.selectQuadrant(UInt8(decoded[i]))
                // TODO: optimize this to reduce the number of intersection tests in cases where decoded is big-ish (bigger than 8?)
                if q.intersects(bbox: region){
                    descend(into: into.children[i], with:q, region:region, results:&results)
                }
            }
        } else {
            for item in into.data{
                if(region.contains(item.position)){
                    results.append(item.data)
                }
            }
        }
    }

    /*
    https://stackoverflow.com/questions/41306122/nearest-neighbor-search-in-octree

    To find the point closest to a search point, or to get list of points in order of increasing distance,
    you can use a priority queue that can hold both points and internal nodes of the tree, which lets you
    remove them in order of distance.

    For points (leaves), the distance is just the distance of the point from the search point. For internal
    nodes (octants), the distance is the smallest distance from the search point to any point that could
    possibly be in the octant.

    Now, to search, you just put the root of the tree in the priority queue, and repeat:

    Remove the head of the priority queue;
    If the head of the queue was a point, then it is the closest point in the tree that you have not yet
    returned. You know this, because if any internal node could possibly have a closer point, then it would
    have been returned first from the priority queue;
    If the head of the queue was an internal node, then put its children back into the queue
    This will produce all the points in the tree in order of increasing distance from the search point.
    The same algorithm works for KD trees as well.
    */


}

class HctNode<T: AnyObject>{
    var bit_field: UInt64 = 0
    var children: [HctNode<T>] = []
    var data: [HctItem<T>] = []

    func subdivide(depth: Int, tree: HctTree<T>) {
        let indices = data.map({ Int(tree.resolve($0.position)[depth]) })
        let pairs = zip(indices, data).sorted(by: { $0.0 < $1.0 } )
       
        // sanity checking
        for i in 1..<pairs.count{
            let (_, a) = pairs[i]
            let (_, b) = pairs[i-1]
            if let aship = a.data as? Ship{
                if let bship = b.data as? Ship{
                    if(aship.id == bship.id){
                        print("\(aship.id) \(aship.positionCartesian)")
                        print("\(bship.id) \(bship.positionCartesian)")
                        print(pairs)
                    }
                    assert(aship.id != bship.id)
                }
            }
        }
       
        var duplicates = 0
        for i in 0..<pairs.count{
            let (index, item) = pairs[i]
            if bit_field & (1 << index) == 0 {
                bit_field |= (1 << index)
                let newNode = HctNode<T>()
                children.append(newNode)
            } else {
                duplicates++
            }
            children[i-duplicates].data.append(item)
        }
        data.removeAll()

        for c in children{
            if(c.data.count > 1 && depth+1 < MAXDEPTH){
                c.subdivide(depth: depth+1, tree: tree)
            }
        }
    }

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
    // TODO: verify that the order of bits I described above matches what the code does, to avoid confusing maintainers (aka. future me)
    func decode() -> [Int] {
        //print("counted bits: \(count_bits()), counted children: \(children.count)")

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

