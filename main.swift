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

    let stations = world.allStations()
    print("\(stations.count) stations")
    var ships: [Int: Ship] = [:]
    for system in world.allSystems(){
        for station in system.stations(){
            let ship = Ship(owner: "test", size: 10, positionCartesian:station.positionCartesian, system: system)
            ships[ship.id] = ship
            system.shipsRegistry.insert(item: ship, position: ship.positionCartesian)
            print("spawned ship with id \(ship.id) at station with id \(station.id)")
        }
    }

    print("--- * * * * * * * ---")

    ////////////////////////////// RUNLOOP ////////////////////////////////////////

    var loop_counter: Int = 0
    while loop_counter < 300 {
        for (_, ship) in ships{
            ship.tick()
        }
        for station in stations{
            station.tick()
        }
        loop_counter += 1
        print("tick \(loop_counter)")
    }
    for station in stations{
        print(station.hold.contents)
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
