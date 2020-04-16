////////////////////////////// COPYRIGHT //////////////////////////////////////
// Copyright 2020 Espen Overaae. All rights reserved.
// 


import Foundation

func main(){
    ////////////////////////////// INITIALIZATION /////////////////////////////////
    var seed = config.randomSeed
    if(CommandLine.arguments.count > 1){
        seed = Int(CommandLine.arguments[1]) ?? config.randomSeed
    }
    print("initializing world with seed: \(seed) at time: \(Date()) ");
    let world = Universe(seed: seed)
    world.proceduralInit()

    ////////////////////////////// TEST SETUP /////////////////////////////////////
    print("--- * * * * * * * ---")

    let spatialTree: HctTree = HctTree(initialSize: 1e6 * PARSEC)
    print("size of spatialTree: \(MemoryLayout.size(ofValue: spatialTree.root))")
    print("size of spatialTree.bit_field: \(MemoryLayout.size(ofValue: spatialTree.root.bit_field))")
    print("size of spatialTree.children: \(MemoryLayout.size(ofValue: spatialTree.root.children))")
    print("size of spatialTree.data: \(MemoryLayout.size(ofValue: spatialTree.root.data))")

    let set_bits = spatialTree.root.decode()
    print("set_bits: \(set_bits)")

    print("--- * * * * * * * ---")
    
    print("--- * * * * * * * ---")
    let stations = world.allStations()
    print("\(stations.count) stations")
    var ships: [Int: Ship] = [:]
    for system in world.allSystems(){
        for station in system.stations(){
            let ship = Ship(owner: "test", size: 10, system: system)
            ship.position = station.position
            ships[ship.id] = ship
            print("spawned ship with id \(ship.id) at station with id \(station.id)")
        }
    }

    print("--- * * * * * * * ---")

    spatialTree.insert(item: ships[351]!, position: Point(10, 10, 10))
    spatialTree.insert(item: ships[352]!, position: Point(-10, -10, -10))

    print(spatialTree.resolve(Point(4,1,8)))

    print("spatialTree contains \(spatialTree.numItems) items")
    spatialTree.remove(item: ships[351]!, position: Point(10, 10, 10))
    spatialTree.remove(item: ships[353]!, position: Point(-10, -10, -10))
    print("spatialTree contains \(spatialTree.numItems) items")
    spatialTree.remove(item: ships[352]!, position: Point(-10, -10, -10))

    ////////////////////////////// RUNLOOP ////////////////////////////////////////

    var loop_counter: Int = 0
    while loop_counter < 10 {
        for (_, ship) in ships{
            ship.tick()
        }
        loop_counter += 1
    }
}

main()

/*    
    var box1 = BBox(top: Point(99.99, 0.005, 3.14), bottom: Point(-1, -2, -1e18))
    print(box1)
    box1.potimize()
    print(box1)
    print(box1.selectQuadrant(0x00))
    print(box1.selectQuadrant(0x15))
    print(box1.selectQuadrant(0x2A))
    print(box1.selectQuadrant(0x3F))
  */  
