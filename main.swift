////////////////////////////// COPYRIGHT //////////////////////////////////////
// Copyright 2020 Espen Overaae. All rights reserved.
// 


import Foundation
    
var ships: [Int: Ship] = [:]

func spawnSpaceShip(at: Station, owner: String, size: Double, system: System) {
    let ship = Ship(owner: owner, size: size, positionCartesian:at.positionCartesian, system: system)
    ships[ship.id] = ship
    system.shipsRegistry.insert(item: ship, position: ship.positionCartesian)
    print("spawned ship size \(size.pretty) with id \(ship.id) at station with id \(at.id)")
}

func main() {
    ////////////////////////////// INITIALIZATION /////////////////////////////
    var seed = config.randomSeed
    if(CommandLine.arguments.count > 1) {
        seed = Int(CommandLine.arguments[1]) ?? config.randomSeed
    }
    print("initializing world with seed: \(seed) at time: \(Date()) ");
    let world = Universe(seed: seed)
    world.proceduralInit()

    ////////////////////////////// TEST SETUP /////////////////////////////////
    print("--- * * * * * * * ---")

    let stations = world.allStations()
    print("\(stations.count) stations")
    for system in world.allSystems() {
        for station in system.stations() {
            spawnSpaceShip(at: station, owner: "test", size: 10, system: system)
        }
    }

    print("--- * * * * * * * ---")

    ////////////////////////////// RUNLOOP ////////////////////////////////////

    var loop_counter: Int = 0
    while loop_counter < 1500 {
        for (_, ship) in ships {
            ship.tick()
        }
        for station in stations {
            station.tick()
            if(loop_counter % 10 == 0) {
                if(station.hold.spaceShip > 500000) {
                    spawnSpaceShip(at: station, owner: "test", size: 500000, system: station.system)
                    station.hold.spaceShip -= 500000
                } else if(station.hold.spaceShip > 100000) {
                    spawnSpaceShip(at: station, owner: "test", size: 100000, system: station.system)
                    station.hold.spaceShip -= 100000
                } else if(station.hold.spaceShip > 10000) {
                    spawnSpaceShip(at: station, owner: "test", size: 10000, system: station.system)
                    station.hold.spaceShip -= 10000
                } else if(station.hold.spaceShip > 2500) {
                    spawnSpaceShip(at: station, owner: "test", size: 2500, system: station.system)
                    station.hold.spaceShip -= 2500
                } else if(station.hold.spaceShip > 1000) {
                    spawnSpaceShip(at: station, owner: "test", size: 1000, system: station.system)
                    station.hold.spaceShip -= 1000
                } else if(station.hold.spaceShip > 250) {
                    spawnSpaceShip(at: station, owner: "test", size: 250, system: station.system)
                    station.hold.spaceShip -= 250
                } else if(station.hold.spaceShip > 100) {
                    spawnSpaceShip(at: station, owner: "test", size: 100, system: station.system)
                    station.hold.spaceShip -= 100
                } else if(station.hold.spaceShip > 30) {
                    spawnSpaceShip(at: station, owner: "test", size: 30, system: station.system)
                    station.hold.spaceShip -= 30
                }
            }
        }
        loop_counter += 1
        print("tick \(loop_counter)")
    }

    ////////////////////////////// POST MORTEM ////////////////////////////////

    for (_, ship) in ships {
        //print("ship recent fuel average: \(ship.fuelMovingAverage.pretty)" + (ship.stuck >= 5 ? " stuck: \(ship.stuck >= 5)" : ""))
        if(ship.stuck > 5) {
            print("stuck ship size \(ship.cargo.capacity.pretty)")
        }
    }
    for system in world.allSystems() {
        print("System \(system.id): remaining asteroids: \(system.asteroidRegistry.values().count) originally: \(system.initialAsteroids) randomSeed: \(system.randomSeed)")
        for station in system.stations() {
            print(station.hold.pretty + " " + station.modules.pretty)
        }
    }
    print("\(ships.count) ships spawned, total weight: \(ships.values.map( {$0.cargo.capacity}).sum().pretty)")
}

main()

