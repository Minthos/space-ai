////////////////////////////// COPYRIGHT //////////////////////////////////////
// Copyright 2020 Espen Overaae. All rights reserved.
// 


////////////////////////////// IMPORTS ////////////////////////////////////////
import Foundation
import Glibc

let PARSEC = 3.086e16
let LY = 9.461e15
let AU = 1.496e11
let KM = 1e3

////////////////////////////// CONFIG /////////////////////////////////////////

let configString = """
{
    "randomSeed": 3,
    "numGalaxies": 2,
    "maxSystems": 5,
    "maxPlanets": 40,
    "maxMoons": 100,
    "maxAsteroids": 1000000,
    "stationDefaultCapacity": 1000
}
"""
class Config: Decodable{
    let randomSeed: Int
    let numGalaxies: Int
    let maxSystems: Int
    let maxPlanets: Int
    let maxMoons: Int
    let maxAsteroids: Int
    let stationDefaultCapacity: Double
}
print("reading config")
let config = try!JSONDecoder().decode(Config.self, from:configString.data(using: .utf8)!)

func planetQtyGen(max_: Int, min_: Int) -> Int{
    let a = (random() % max_)
    let b = (random() % max_)
    return max(min_, (a * b) / max_)
}

func moonQtyGen(max_: Int, min_: Int) -> Int{
    let a = (random() % max_)
    let b = (random() % max_)
    let c = (random() % max_)
    let d = (random() % max_)
    return max(min_, ((((a * b) / max_) * ((d * c) / max_)) / max_))
}

func genericQtyGen(max_: Int, min_: Int) -> Int{
    let a = (random() % max_)
    let b = (random() % max_)
    return max(min_, (a * b) / max_)
}

func coordGen(rho_scaling: Double) -> (Double, Double, Double){
    var rho = Double(random()) / Double(RAND_MAX)
    let rho2 = Double(random()) / Double(RAND_MAX)
    let theta = Double(random()) / Double(RAND_MAX)
    var phi = Double(random()) / Double(RAND_MAX)
    let phi2 = Double(random()) / Double(RAND_MAX)
    phi = (phi - 0.5) * 2 * phi2
    rho = rho * rho2
    return (rho * rho_scaling, theta * 360, phi * 360)
}

////////////////////////////// CLASSES ////////////////////////////////////////

class Uid{
    static var count: Int = 0
    class func getNewId() -> Int{
        let rax = count
        count += 1
        return rax
    }
}

class CargoSpace{
    var capacity: Double = 0

    var minerals: Double = 0 // minerals are used for building ships, stations and heavy machinery
    var gas: Double = 0 // gas is used for fuel, life support and synthetic materials
    var precious: Double = 0 // precious elements are used in electronics and high tech equipment
    var fuel: Double = 0 // used for spaceship propulsion
    var lifeSupport: Double = 0 // keeps living things alive
    var miningDrone: Double = 0 // used to harvest resources from asteroids, planets and moons
    var spareParts: Double = 0 // used to repair all kinds of things
    var weapons: Double = 0 // used to destroy all kinds of things
    var spaceShip: Double = 0 // can fly around in space and carry stuff
    var spaceStation: Double = 0 // conventient place to process resources and build things
    var factory: Double = 0 // turns resources into everything except fuel and life support
    var refinery: Double = 0 // turns gas into fuel and life support

    init(capacity: Double){
        self.capacity = capacity
    }

    func remainingCapacity() -> Double{
        var counter = capacity

        for variable in [
            self.minerals,
            self.gas,
            self.precious,
            self.lifeSupport,
            self.miningDrone,
            self.spareParts,
            self.weapons,
            self.spaceShip,
            self.spaceStation,
            self.factory,
            self.refinery] {
            if(variable < 0) {
                print("!!! negative value of \(variable) detected in cargo space!")
            } else {
                counter -= variable
            }
        }
        if(counter < 0){
            print("!!! cargo space overflow! \(counter) remaining of \(self.capacity) capacity!")
        }
        return counter
    }
}

class Ship:Uid{
    let id: Int
    let cargo: CargoSpace
    var owner: String

    var rho: Double = 0
    var theta: Double = 0
    var phi: Double = 0

    init(owner: String, size: Double){
        self.id = Ship.getNewId()
        self.owner = owner
        self.cargo = CargoSpace(capacity: size)
    }
}

class Station:Uid{
    let id: Int
    let hold: CargoSpace
    var owner: String = ""

    var rho: Double = 0
    var theta: Double = 0
    var phi: Double = 0

    var minerals: Double = 0
    var gas: Double = 0
    var precious: Double = 0

    init(seed: Int){
        self.id = Station.getNewId()
        self.hold = CargoSpace(capacity: config.stationDefaultCapacity)
    }

    func proceduralInit(){
        print("Space Station!")
        (self.rho, self.theta, self.phi) = coordGen(rho_scaling: 1e6 * KM)
    }
}

class Asteroid{
    private let randomSeed: Int!
    let id: Int

    var rho: Double = 0
    var theta: Double = 0
    var phi: Double = 0

    var minerals: Double = 0
    var gas: Double = 0
    var precious: Double = 0

    init(seed: Int, id: Int){
        self.randomSeed = seed
        self.id = id
    }

    func proceduralInit(){
        srandom(UInt32(self.randomSeed))
        
        (self.rho, self.theta, self.phi) = coordGen(rho_scaling: 100 * AU)

        let type = random()
        if type % 5 > 0{
            minerals = Double(random()) / Double(RAND_MAX)
        }
        if type % 5 < 3{
            gas = Double(random()) / Double(RAND_MAX)
        }
        if type % 16 == 0{
            precious = Double(random()) / Double(RAND_MAX)
        }
    }
}

class Moon:Uid{
    private let randomSeed: Int
    let id: Int
    
    var rho: Double = 0
    var theta: Double = 0
    var phi: Double = 0
    
    var minerals: Double = 0
    var gas: Double = 0
    var precious: Double = 0

    var stations = [Station]()

    init(seed: Int){
        self.randomSeed = seed
        self.id = Moon.getNewId()
    }

    func proceduralInit(){
        srandom(UInt32(self.randomSeed))
        (self.rho, self.theta, self.phi) = coordGen(rho_scaling: 1e8 * KM)
        let numStations = random() % 100 == 0 ? 1 : 0
        for _ in 0..<numStations{
            stations.append(Station(seed: random()))
        }
        for i in 0..<numStations{
            stations[i].proceduralInit()
        }

        let type = random()
        if type % 5 > 0{
            minerals = Double(random()) / Double(RAND_MAX)
        }
        if type % 5 < 2{
            gas = Double(random()) / Double(RAND_MAX)
        }
        if type % 2 == 0{
            precious = Double(random()) / Double(RAND_MAX)
        }

        minerals = minerals * 1e4
        gas = gas * 1e4
        precious = precious * 1e2
    }
}

class Planet:Uid{
    private let randomSeed: Int
    let id: Int
    
    var rho: Double = 0
    var theta: Double = 0
    var phi: Double = 0
    
    var minerals: Double = 0
    var gas: Double = 0
    var precious: Double = 0
    
    var moons = [Moon]()
    var stations = [Station]()

    init(seed: Int){
        self.randomSeed = seed
        self.id = Planet.getNewId()
    }

    func proceduralInit(){
        srandom(UInt32(self.randomSeed))
        (self.rho, self.theta, self.phi) = coordGen(rho_scaling: 20 * AU)
        let numMoons = moonQtyGen(max_: config.maxMoons, min_:0)
        let numStations = random() % 10 == 0 ? 1 : 0
        for _ in 0..<numMoons{
            moons.append(Moon(seed: random()))
        }
        for _ in 0..<numStations{
            stations.append(Station(seed: random()))
        }
        for i in 0..<numMoons{
            moons[i].proceduralInit()
        }
        for i in 0..<numStations{
            stations[i].proceduralInit()
        }

        let type = random()
        if type % 5 > 3{
            minerals = Double(random()) / Double(RAND_MAX)
            precious = Double(random()) / Double(RAND_MAX)
        }
        if type % 5 <= 3{
            gas = Double(random()) / Double(RAND_MAX)
        }

        minerals = minerals * 1e5
        gas = gas * 1e5
        precious = precious * 1e2
    }
}

class System:Uid{
    private let randomSeed: Int
    let id: Int
    
    var rho: Double = 0
    var theta: Double = 0
    var phi: Double = 0
    
    var planets = [Planet]()
    var asteroids = [Asteroid]()

    init(seed: Int){
        self.randomSeed = seed
        self.id = System.getNewId()
    }

    func proceduralInit(){
        print("system \(self.id)")
        srandom(UInt32(self.randomSeed))
        (self.rho, self.theta, self.phi) = coordGen(rho_scaling: 1.0e6 * PARSEC)
        let numPlanets = planetQtyGen(max_: config.maxPlanets, min_:1)
        let numAsteroids = genericQtyGen(max_: config.maxAsteroids, min_:1)
        for _ in 0..<numPlanets{
            planets.append(Planet(seed: random()))
        }
        for i in 0..<numAsteroids{
            asteroids.append(Asteroid(seed: random(), id: i))
        }
        for i in 0..<numPlanets{
            planets[i].proceduralInit()
        }
        for i in 0..<numAsteroids{
            asteroids[i].proceduralInit()
        }
    }
    
    func stations() -> Array<Station>{
        return planets.flatMap{ $0.stations + $0.moons.flatMap{ $0.stations } }
    }
}

class Galaxy:Uid{
    private let randomSeed: Int
    let id: Int
    
    var rho: Double = 0
    var theta: Double = 0
    var phi: Double = 0
    
    var systems = [System]()

    init(seed: Int){
        self.randomSeed = seed
        self.id = Galaxy.getNewId()
    }

    func proceduralInit(){
        srandom(UInt32(self.randomSeed))
        (self.rho, self.theta, self.phi) = coordGen(rho_scaling: 1.4e9 * PARSEC)
        //let numSystems = genericQtyGen(max_: config.maxSystems, min_:1)
        let numSystems = max(1, random() % config.maxSystems)
        print("spawning \(numSystems) systems")
        for _ in 0..<numSystems{
            systems.append(System(seed: random()))
        }
        print("configuring systems")
        for i in 0..<numSystems{
            systems[i].proceduralInit()
        }
        print("\(numSystems) systems ready")
    }
}

class Universe{
    private let randomSeed: Int
    var galaxies = [Galaxy]()

    init(seed: Int){
        self.randomSeed = seed
    }

    func proceduralInit(){
        srandom(UInt32(self.randomSeed))
        let numGalaxies = config.numGalaxies
        print("spawning \(numGalaxies) galaxies")
        for _ in 0..<numGalaxies{
            self.galaxies.append(Galaxy(seed: random()))
        }
        print("configuring \(numGalaxies) galaxies")
        for i in 0..<numGalaxies{
            self.galaxies[i].proceduralInit()
        }
        print("\(numGalaxies) galaxies ready")
    }

    func allSystems() -> Array<System>{
        return galaxies.flatMap{ $0.systems }
    }

    func allStations() -> Array<Station>{
        return galaxies.flatMap{ $0.systems.flatMap{ $0.planets.flatMap{ $0.stations + $0.moons.flatMap{ $0.stations } } } }
    }
}

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

