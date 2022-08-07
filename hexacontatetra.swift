// hexacontatetra.swift
// Copyright 2020 Espen Overaae
// Public Domain except where I have plagiarised
//
// "Sparse octree with modifications": 64 subdivisions per node instead of the usual 8.
// The occupied subsections are encoded in a 64-bit boolean field.

import Foundation

// MAXDEPTH is 26 because Double only has 53 bits of precision and each level represents 2 bits of spatial resolution
let MAXDEPTH = 26

extension Array {
    @inlinable
    public mutating func popFirst() -> Element? {
        if isEmpty {
            return nil
        } else {
            return removeFirst()
        }
    }
}

// round up to nearest power of 2
func potimizeDouble(_ number: Double) -> Double {
    if(number.binade == number) {
        return number
    } else {
        return number.binade * 2
    }
}

func hexString(_ number: UInt64) -> String {
    return String(format: "%llx", number)
}

struct BBox {
    var center: Point
    var halfsize: Double

    var top: Point { get { return center + halfsize } }
    var bottom: Point { get { return center - halfsize } }
    var pretty: String { get { return center.pretty + " halfsize: " + halfsize.pretty }}

    init(center: Point, halfsize: Double) {
        self.center = center
        self.halfsize = halfsize
    }

    init(top: Point, bottom: Point) {
        self.center = (top + bottom) * 0.5
        self.halfsize = abs(top.x - bottom.x) * 0.5
    }
   
    // returns a (1/4, 1/4, 1/4) size section of a bounding box.
    // Which of the 64 possible subsections is indicated by the argument "index"
    func selectQuadrant(_ index: UInt8) -> BBox {
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

    func contains(_ point: Point) -> Bool {
        return( abs(point.x - center.x) < halfsize &&
                abs(point.y - center.y) < halfsize &&
                abs(point.z - center.z) < halfsize )
    }

    func intersects(bbox: BBox) -> Bool {
        // Radius isn't the right word. Suggestions welcome.
        let collisionRadius = bbox.halfsize + halfsize
        return( abs(bbox.center.x - center.x) < collisionRadius &&
                abs(bbox.center.y - center.y) < collisionRadius &&
                abs(bbox.center.z - center.z) < collisionRadius )
    }

    var scientific: String {
        return "BBox(top: \(top.scientific), bottom: \(bottom.scientific))"
    }

}

struct HctItem<T: AnyObject> {
    let data: T
    let position: Point
}


class HctTree<T: AnyObject> {
    var numItems: Int = 0
    var root: HctNode<T> = HctNode<T>()
    var dims: BBox = BBox(center: Point(0,0,0), halfsize: 0)
    let BINSIZE: Int // 1024 seems to work well for asteroids, 64 seems to work well for ships. I don't know why.

    init(initialSize: Double, binSize: Int = 1024) {
        let extent = potimizeDouble(initialSize)
        dims.halfsize = extent
        BINSIZE = binSize
    }
    
  
    // return the bit_field indices of the path leading to position for each level of the tree
    func quickResolve(_ position: Point) -> [UInt8] {
        // translate the points so that 0,0,0 is the bottom of our number range
        // (assumes dims is centered on 0,0,0 as it should be)
        // normalize magnitude to map each level to 2 bits of an Int
        let quartersize = dims.halfsize * 0.5
        let scalingFactor = Double(1 << (MAXDEPTH * 2)) / quartersize
        let p = (position - dims.bottom) * scalingFactor
        var x = (Int(p.x))
        var y = (Int(p.y))
        var z = (Int(p.z))

        // extract the information we're interested in
        var result: [UInt8] = []
        for _ in 0..<MAXDEPTH {
            x = x >> 2
            y = y >> 2
            z = z >> 2
            var temp = x & 3
            temp |= (y & 3) << 2
            temp |= (z & 3) << 4
            result.append(UInt8(temp))
        }
        return result.reversed()
    }

    // return the bit_field index of the path leading to point at one specific level of the tree
    func quickResolve(position: Point, at depth: Int) -> UInt8 {
        // translate the points so that 0,0,0 is the bottom of our number range
        // (assumes dims is centered on 0,0,0 as it should be)
        // normalize magnitude to map each level to 2 bits of an Int
        let quartersize = dims.halfsize * 0.5
        let scalingFactor = Double(1 << (MAXDEPTH * 2)) / quartersize
        let p = (position - dims.bottom) * scalingFactor
       
        // extract the information we're interested in
        let x = (Int(p.x) >> (2*(MAXDEPTH - depth))) & 0x03
        let y = (Int(p.y) >> (2*(MAXDEPTH - depth))) & 0x03
        let z = (Int(p.z) >> (2*(MAXDEPTH - depth))) & 0x03
        return UInt8( x | y << 2 | z << 4 )
    }

    func insert(item: T, position: Point) {
        if !dims.contains(position) {
            print("PANIC! attempting to insert object outside the bounds of the spatial tree: \(position)")
            assert(false)
        }
        let path = quickResolve(position)
        var leaf = root
        var depth = 0

        while(true) {
            if(leaf.bit_field == 0) {
                leaf.data.append(HctItem(data: item, position: position))
                // max BINSIZE items per leaf node unless we are at max depth
                if(leaf.data.count > BINSIZE && depth < MAXDEPTH) {
                    leaf.subdivide(depth: depth, tree: self, BINSIZE: BINSIZE)
                }
                numItems++
                return
            }

            // descend deeper in the tree
            let index = Int(path[depth])
            if(leaf.bit_field & (1 << index) != 0) {
                let decoded = leaf.decode()
                for i in 0..<decoded.count {
                    if(decoded[i] == index) {
                        leaf = leaf.children[i]
                        break
                    }
                }
            } else {
                let newNode = HctNode<T>()
                leaf.bit_field |= (1 << index)
                let decoded = leaf.decode()
                for i in 0..<decoded.count {
                    if(decoded[i] == index) {
                        leaf.children.insert(newNode, at: i)
                        leaf = newNode
                        break
                    }
                }
            }
            depth++
        }
    }

    func remove(item: T, position: Point) {

        if(root.bit_field == 0) {
            let before = root.data.count
            assert(before == numItems)
            root.data.removeAll(where: { $0.data === item })
            numItems--
            assert(root.data.count == before - 1)
            assert(root.data.count == numItems)
            return
        }

        var leaf = root
        let path = quickResolve(position)
        var depth = 0
        var prev: [HctNode<T>] = []
        var previ: [Int] = []
        while(true) {
            // descend deeper in the tree
            let index = Int(path[depth])
            if(leaf.bit_field & (1 << index) != 0) {
                let decoded = leaf.decode()
                for i in 0..<decoded.count {
                    if(decoded[i] == index) {
                        prev.append(leaf)
                        previ.append(i)
                        leaf = leaf.children[i]
                        let before = leaf.data.count
                        if(before > 0) {
                            leaf.data.removeAll(where: { $0.data === item })
                            if(leaf.data.count == 0) {
                                var p: HctNode<T>? = nil
                                repeat {
                                    p = prev.popLast()
                                    let pi = previ.popLast()
                                    p?.children.remove(at: pi!)
                                    p?.bit_field ^= (1 << Int(path[depth]))
                                    depth--
                                } while(p?.bit_field == 0 && !(p === root))
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

    // move an item to a different position and update the tree accordingly
    func relocate(item: T, from: Point, to: Point) {
        let before = numItems
        if let ship = item as? Ship {
            assert(ship.positionCartesian == from)
        }
        remove(item: item, position:from)
        assert(numItems == before - 1)
        insert(item: item, position:to)
        assert(numItems == before)
    }
    
    // returns all the items in the tree
    func values() -> [T] {
        return root.everything().map { $0.data }
    }

    // very fast but if you want accurate results you must set a high cutoff and filter the results by box-point intersection
    func lookup(region: BBox, cutoff: Int) -> [T] {
        var results: [T] = []
        descend(into: root, with: dims, region: region, results: &results, cutoff: cutoff)
        return results
    }

    func descend(into: HctNode<T>, with: BBox, region: BBox, results: inout [T], cutoff: Int) {
        if(results.count >= cutoff) {
            return
        }
        if(into.bit_field != 0) {
            let decoded = into.decode()
            for i in 0..<decoded.count {
                let q = with.selectQuadrant(decoded[i])
                if q.intersects(bbox: region) {
                    descend(into: into.children[i], with:q, region:region, results:&results, cutoff: cutoff)
                }
            }
        } else {
            results.append(contentsOf:into.data.map { $0.data })
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
    func index2bit(center: Double, halfsize: Double, quartersize: Double, point: Double) -> UInt8 {
        let bottom = center - halfsize
        let result = UInt8((point - bottom) / quartersize)
        return result
    }

    func index6bit(center: Point, halfsize: Double, point: Point) -> UInt8 {
        let quartersize = halfsize * 0.5
        return index2bit(center: center.x, halfsize: halfsize, quartersize: quartersize, point: point.x) |
                index2bit(center: center.y, halfsize: halfsize, quartersize: quartersize, point: point.y) << 2 |
                index2bit(center: center.z, halfsize: halfsize, quartersize: quartersize, point: point.z) << 4
    }

    // the square of the distance a point is outside a box, or 0 if it's inside
    func squaredDist(_ box: BBox, _ b: Point) -> Double {
        let a = box.center
        let x = max(0, abs(b.x - a.x) - box.halfsize)
        let y = max(0, abs(b.y - a.y) - box.halfsize)
        let z = max(0, abs(b.z - a.z) - box.halfsize)
        return x * x + y * y + z * z
    }

    // the square of the distance between two points
    func squaredDist(_ a: Point, _ b: Point) -> Double {
        let x = b.x - a.x
        let y = b.y - a.y
        let z = b.z - a.z
        return x * x + y * y + z * z
    }
    
    // The k nearest neighbor algorithm is slower than making successive calls to lookup() and sorting the result by distance.
    func kNearestNeighbor(k: Int, to: Point, shouldSort: Bool = false) -> [T] {
        var queue: [(Double, BBox, HctNode<T>)] = [(0, dims, root)]
        var results: [T] = []
        while(results.count < k) {
            let (_, box, node) = queue.popFirst() ?? (Double.infinity, BBox(center: Point(0, 0, 0), halfsize: 0), nil)
            if(node == nil) {
                break
            } else if node!.data.count > 0 {
                assert(node!.children.count == 0)
                if(shouldSort) {
                    let sorted: [HctItem<T>] = node!.data.sorted(by: { squaredDist($0.position, to) < squaredDist($1.position, to) } )
                    results.append(contentsOf: sorted.map( {$0.data}))
                } else {
                    results.append(contentsOf: node!.data.map( {$0.data}))
                }
            } else if node!.children.count > 0 {
                // calculate greatest distance in each dimension from point to center of each child node
                // sort child nodes by distance in most distant dimension
                // merge into queue
                let decoded = node!.decode()
                assert(decoded.count == node!.children.count)
                var children: [(Double, BBox, HctNode<T>)] = []
                for i in 0..<decoded.count {
                    let newNode = node!.children[i]
                    let newBox = index2box(index: decoded[i], outer: box)
                    let calculated = index6bit(center: box.center, halfsize: box.halfsize, point: newBox.center)
                    assert(calculated == decoded[i])
                    assert(box.contains(newBox.center))
                    let distance = squaredDist(newBox, to)
                    children.append((distance, newBox, newNode))
                }
                children.sort(by: { $0.0 < $1.0 })

                var ci = 0
                var qi = 0
                repeat {
                    if(qi == queue.count || children[ci].0 < queue[qi].0) {
                        queue.insert(children[ci], at:qi)
                        ci++
                    }
                    qi++
                } while (ci < children.count && qi <= queue.count)
            } else {
                assert(node === root)
            }
        }
        return results
    }

    func index2box(index: UInt8, outer: BBox) -> BBox {
        let threeeighthssize = outer.halfsize * 0.75
        let quartersize = outer.halfsize * 0.5
        let center = Point(outer.center.x + (Double(index & 0x03) * quartersize) - threeeighthssize,
                          outer.center.y + (Double((index >> 2) & 0x03) * quartersize) - threeeighthssize,
                          outer.center.z + (Double((index >> 4) & 0x03) * quartersize) - threeeighthssize)
        return BBox(center: center, halfsize: outer.halfsize * 0.25)
    }
}

class HctNode<T: AnyObject> {
    var bit_field: UInt64 = 0
    var children: [HctNode<T>] = []
    var data: [HctItem<T>] = []

    func everything() -> ArraySlice<HctItem<T>> {
        if(bit_field == 0) {
            return data[0..<data.count]
        } else {
            return children.map { $0.everything() }.reduce([], +)
        }
    }

    func subdivide(depth: Int, tree: HctTree<T>, BINSIZE: Int) {
        let indices = data.map( { Int(tree.quickResolve(position: $0.position, at: depth)) })
        let pairs = zip(indices, data).sorted(by: { $0.0 < $1.0 } )
        var duplicates = 0
        for i in 0..<pairs.count {
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

        for c in children {
            if(c.data.count > BINSIZE && depth+1 < MAXDEPTH) {
                c.subdivide(depth: depth+1, tree: tree, BINSIZE: BINSIZE)
            }
        }
    }

    // returns an array of numbers indicating which bit in the bit field represents
    // the child node at the same index in the children array
    //
    // example:
    // bit_field 0000 0000 0000 0000 0001 0000 0001 0001
    // children [node, node, node]
    // decode: [0,4,12]
    // then you can zip decode with children and get something like [(0, node), (4, node), (12, node)]
    func decode() -> [UInt8] {
        var v = bit_field
        var results: [UInt8] = []
        while v != 0 {
            let prev = v
            v &= v - 1; // clear the least significant bit set
            let diff = v ^ prev
            results.append(whichBit(diff))
        }
        return results
    }

    // returns the number of children by counting high bits in the bit field
    // a bit useless I suppose when one can just query the length of the children array
    // maybe it'll come in handy later
    func count_bits() -> Int {
        var v = bit_field
        var c: Int = 0
        while v != 0 {
            v &= v - 1; // clear the least significant bit set
            c += 1
        }
        return c
    }
}

