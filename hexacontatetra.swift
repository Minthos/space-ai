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
    var center: Point
    var halfsize: Double

    var top: Point { get { return center + halfsize } }
    var bottom: Point { get { return center - halfsize } }

    init(center: Point, halfsize: Double){
        self.center = center
        self.halfsize = halfsize
    }
/*
    init(top: Point, bottom: Point){
        self.center = (top + bottom) * 0.5
        self.halfsize = abs(top.x - bottom.x) * 0.5
    }
  */ 

    // returns a (1/4, 1/4, 1/4) size section of a bounding box.
    // Which of the 64 possible subsections is indicated by the argument "index"
    func selectQuadrant(_ index: UInt8) -> BBox{
        let xindex = Double(index & 0x03)
        let yindex = Double((index >> 2) & 0x03)
        let zindex = Double((index >> 4) & 0x03)
        let quartersize = halfsize * 0.5
        let eighthsize = halfsize * 0.25
        let offset = eighthsize - halfsize
        return BBox(center: Point(center.x + offset + xindex * quartersize,
                                  center.y + offset + yindex * quartersize,
                                  center.z + offset + zindex * quartersize),
                    halfsize: eighthsize)
    }
    
//    func mkIndex(a: Double, )
    
    func b4p_element(center: Double, halfsize: Double, quartersize: Double, point: Double) -> Double{
        let bottom = center - halfsize
        let result = (point - bottom) / quartersize
        return result.rounded(.towardZero)
    }

    func boxForPoint(_ point: Point) -> BBox {
        assert(contains(point))

        let quartersize = halfsize * 0.5
        let eighthsize = halfsize * 0.25
        let offset = eighthsize - halfsize
        let xindex = b4p_element(center: center.x, halfsize: halfsize, quartersize: quartersize, point: point.x)
        let yindex = b4p_element(center: center.y, halfsize: halfsize, quartersize: quartersize, point: point.y)
        let zindex = b4p_element(center: center.z, halfsize: halfsize, quartersize: quartersize, point: point.z)
        let result = BBox(center: Point(center.x + offset + xindex * quartersize,
                                  center.y + offset + yindex * quartersize,
                                  center.z + offset + zindex * quartersize),
                    halfsize: eighthsize)

        assert(result.contains(point))
        return result
    }

    func contains(_ point: Point) -> Bool{
        return( abs(point.x - center.x) < halfsize &&
                abs(point.y - center.y) < halfsize &&
                abs(point.z - center.z) < halfsize )
    }

    func intersects(bbox: BBox) -> Bool{
        let collisionRadius = bbox.halfsize + halfsize
        return( abs(bbox.center.x - center.x) < collisionRadius &&
                abs(bbox.center.y - center.y) < collisionRadius &&
                abs(bbox.center.z - center.z) < collisionRadius )
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
/*
    Optimization ideas:
    Intelligently subdivide the search space on each level to avoid unnecessary box-box intersection tests
    Better nearest-neigbor search using priority queue (described below)

*/
class HctTree<T: AnyObject>{
    var numItems: Int = 0
    var root: HctNode<T> = HctNode<T>()
    var dims: BBox = BBox(center: Point(0,0,0), halfsize: 0)

    init(initialSize: Double){
        let extent = potimizeDouble(initialSize)
        dims.halfsize = extent
    }

    func index2bit(center: Double, halfsize: Double, quartersize: Double, point: Double) -> UInt8{
        let bottom = center - halfsize
        let result = UInt8((point - bottom) / quartersize)
        return result
    }

    func index6bit(center: Point, halfsize: Double, point: Point) -> UInt8{
        let quartersize = halfsize * 0.5
        return index2bit(center: center.x, halfsize: halfsize, quartersize: quartersize, point: point.x) |
                index2bit(center: center.y, halfsize: halfsize, quartersize: quartersize, point: point.y) << 2 |
                index2bit(center: center.z, halfsize: halfsize, quartersize: quartersize, point: point.z) << 4
    }

    func resolve(position: Point, at depth: Int) -> UInt8{
        var box = dims
        for _ in 0..<depth {
            box = box.boxForPoint(position)
//            quadrant = index6bit(center: box.center, halfsize: box.halfsize, point:position)
//            box = box.selectQuadrant(quadrant)
        }
        if(!box.contains(position)){
            print("index6bit: \(box) \(position)")
        }
        assert(box.contains(position))
        return index6bit(center: box.center, halfsize: box.halfsize, point:position)
    }

    func resolve(_ position: Point) -> [UInt8]{
        var rax: [UInt8] = []
        var box = dims
        // MAXDEPTH is 26 because Double only has 53 bits of precision. Should break out earlier if possible. (TODO)
        for _ in 0..<MAXDEPTH {
            let quadrant = index6bit(center: box.center, halfsize: box.halfsize, point:position)
            rax.append(quadrant)
            box = box.selectQuadrant(quadrant)
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
                // max BINSIZE items per leaf node unless we are at max depth
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
                let q = with.selectQuadrant(decoded[i])
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
        let indices = data.map({ Int(tree.resolve(position: $0.position, at: depth)) })
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
    func whichBit(input: UInt64) -> UInt8 {
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
        return UInt8(index)
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
    func decode() -> [UInt8] {
        //print("counted bits: \(count_bits()), counted children: \(children.count)")

        var v = bit_field
        var results: [UInt8] = []
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

