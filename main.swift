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

    HctNode.initialize()
    let spatialTree: HctNode = HctNode()

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

