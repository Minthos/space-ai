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

    let spatialTree: HctNode = HctNode()
    print("size of spatialTree: \(MemoryLayout.size(ofValue: spatialTree))")
    print("size of spatialTree.bit_field: \(MemoryLayout.size(ofValue: spatialTree.bit_field))")
    print("size of spatialTree.children: \(MemoryLayout.size(ofValue: spatialTree.children))")
    print("size of spatialTree.data: \(MemoryLayout.size(ofValue: spatialTree.data))")

    print("--- * * * * * * * ---")
    let stations = world.allStations()
    print("\(stations.count) stations")
    var ships: [Int: Ship] = [:]
    for system in world.allSystems(){
        for station in system.stations(){
            let ship = Ship(owner: "test", size: 10)
            ships[ship.id] = ship
            print("spawned ship with id \(ship.id) at station with id \(station.id)")
        }
    }

    ////////////////////////////// RUNLOOP ////////////////////////////////////////

    //while true {
    //    print("zzz...")
    //    sleep(1);
    //}
}

main()

